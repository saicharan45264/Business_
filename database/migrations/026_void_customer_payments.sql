-- Payment deletion is represented as a reversible void marker. Existing payment rows
-- and events are preserved; active balance queries exclude only rows explicitly voided.
ALTER TABLE customer_opening_payments
  ADD COLUMN IF NOT EXISTS voided_at TIMESTAMPTZ;

ALTER TABLE customer_payment_events
  ADD COLUMN IF NOT EXISTS voided_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS customer_opening_payments_active_customer_idx
  ON customer_opening_payments(customer_id, created_at DESC)
  WHERE voided_at IS NULL;

CREATE OR REPLACE FUNCTION capture_customer_payment_event() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  cid BIGINT;
  change_amount NUMERIC;
  discount_amount NUMERIC := 0;
  old_amount NUMERIC;
  old_cash NUMERIC;
  old_account NUMERIC;
  new_cash NUMERIC;
  new_account NUMERIC;
  current_due NUMERIC;
  bill_id BIGINT;
  payment_id BIGINT;
BEGIN
  IF current_setting('app.suppress_payment_event',true)='true' THEN RETURN NEW; END IF;
  IF TG_TABLE_NAME='sales' THEN
    IF TG_OP='UPDATE' AND NEW.retailer_id<>OLD.retailer_id THEN RETURN NEW; END IF;
    cid:=NEW.retailer_id; bill_id:=NEW.id;
    old_amount:=CASE WHEN TG_OP='UPDATE' THEN OLD.amount_paid ELSE 0 END;
    old_cash:=CASE WHEN TG_OP='UPDATE' THEN OLD.cash_paid ELSE 0 END;
    old_account:=CASE WHEN TG_OP='UPDATE' THEN OLD.account_paid ELSE 0 END;
    IF old_amount=0 THEN old_cash:=0; old_account:=0; END IF;
    change_amount:=NEW.amount_paid-old_amount;
    new_cash:=NEW.cash_paid; new_account:=NEW.account_paid;
  ELSE
    cid:=NEW.customer_id; payment_id:=NEW.id;
    old_amount:=0; old_cash:=0; old_account:=0;
    change_amount:=NEW.total; discount_amount:=COALESCE(NEW.discount,0);
    new_cash:=NEW.cash; new_account:=NEW.account;
  END IF;
  IF change_amount=0 AND discount_amount=0 THEN RETURN NEW; END IF;
  SELECT GREATEST(p.opening_balance+p.balance_adjustment+
    COALESCE((SELECT SUM(s.total-s.amount_paid) FROM sales s WHERE s.retailer_id=p.id AND s.deleted_at IS NULL),0)-
    COALESCE((SELECT SUM(cp.balance_effect) FROM customer_opening_payments cp WHERE cp.customer_id=p.id AND cp.voided_at IS NULL),0),0)
    INTO current_due FROM parties p WHERE p.id=cid;
  INSERT INTO customer_payment_events(customer_id,sale_id,opening_payment_id,amount_change,previous_paid,
    cash_change,account_change,balance_before,balance_after,payment_date,discount_change)
  VALUES(cid,bill_id,payment_id,change_amount,old_amount,
    CASE WHEN old_cash IS NOT NULL AND new_cash IS NOT NULL THEN new_cash-old_cash END,
    CASE WHEN old_account IS NOT NULL AND new_account IS NOT NULL THEN new_account-old_account END,
    current_due+change_amount+discount_amount,current_due,
    COALESCE(NULLIF(current_setting('app.payment_date',true),'')::date,(now() AT TIME ZONE 'Asia/Kolkata')::date),discount_amount);
  RETURN NEW;
END $$;
