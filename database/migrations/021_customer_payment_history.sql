-- New payment events are captured at the time of the transaction. Existing values are not rewritten.
CREATE TABLE IF NOT EXISTS customer_payment_events (
 id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 customer_id BIGINT NOT NULL REFERENCES parties(id),
 sale_id BIGINT REFERENCES sales(id),
 opening_payment_id BIGINT REFERENCES customer_opening_payments(id),
 occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 payment_date DATE NOT NULL DEFAULT (now() AT TIME ZONE 'Asia/Kolkata')::date,
 amount_change NUMERIC(18,2) NOT NULL,
 previous_paid NUMERIC(18,2),
 cash_change NUMERIC(18,2),
 account_change NUMERIC(18,2),
 balance_before NUMERIC(18,2),
 balance_after NUMERIC(18,2),
 CHECK ((sale_id IS NULL) <> (opening_payment_id IS NULL))
);
CREATE INDEX IF NOT EXISTS customer_payment_events_customer_date_idx ON customer_payment_events(customer_id, occurred_at DESC, id DESC);
CREATE OR REPLACE FUNCTION capture_customer_payment_event() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE cid BIGINT; change_amount NUMERIC; old_amount NUMERIC; old_cash NUMERIC; old_account NUMERIC; new_cash NUMERIC; new_account NUMERIC; current_due NUMERIC; bill_id BIGINT; payment_id BIGINT;
BEGIN
 IF TG_TABLE_NAME='sales' THEN
  IF TG_OP='UPDATE' AND NEW.retailer_id<>OLD.retailer_id THEN RETURN NEW; END IF;
  cid:=NEW.retailer_id; bill_id:=NEW.id; old_amount:=CASE WHEN TG_OP='UPDATE' THEN OLD.amount_paid ELSE 0 END;
  old_cash:=CASE WHEN TG_OP='UPDATE' THEN OLD.cash_paid ELSE 0 END; old_account:=CASE WHEN TG_OP='UPDATE' THEN OLD.account_paid ELSE 0 END;
  IF old_amount=0 THEN old_cash:=0;old_account:=0; END IF;
  change_amount:=NEW.amount_paid-old_amount; new_cash:=NEW.cash_paid; new_account:=NEW.account_paid;
 ELSE
  cid:=NEW.customer_id;payment_id:=NEW.id;old_amount:=0;old_cash:=0;old_account:=0;change_amount:=NEW.total;new_cash:=NEW.cash;new_account:=NEW.account;
 END IF;
 IF change_amount=0 THEN RETURN NEW; END IF;
 SELECT GREATEST(p.opening_balance+p.balance_adjustment+COALESCE((SELECT SUM(s.total-s.amount_paid) FROM sales s WHERE s.retailer_id=p.id AND s.deleted_at IS NULL),0)-COALESCE((SELECT SUM(cp.balance_effect) FROM customer_opening_payments cp WHERE cp.customer_id=p.id),0),0) INTO current_due FROM parties p WHERE p.id=cid;
 INSERT INTO customer_payment_events(customer_id,sale_id,opening_payment_id,amount_change,previous_paid,cash_change,account_change,balance_before,balance_after,payment_date)
 VALUES(cid,bill_id,payment_id,change_amount,old_amount,CASE WHEN old_cash IS NOT NULL AND new_cash IS NOT NULL THEN new_cash-old_cash END,CASE WHEN old_account IS NOT NULL AND new_account IS NOT NULL THEN new_account-old_account END,current_due+change_amount,current_due,COALESCE(NULLIF(current_setting('app.payment_date',true),'')::date,(now() AT TIME ZONE 'Asia/Kolkata')::date));
 RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS capture_sale_payment ON sales;
CREATE TRIGGER capture_sale_payment AFTER INSERT OR UPDATE OF amount_paid ON sales FOR EACH ROW EXECUTE FUNCTION capture_customer_payment_event();
DROP TRIGGER IF EXISTS capture_opening_payment ON customer_opening_payments;
CREATE TRIGGER capture_opening_payment AFTER INSERT ON customer_opening_payments FOR EACH ROW EXECUTE FUNCTION capture_customer_payment_event();
CREATE TABLE IF NOT EXISTS customer_payment_date_overrides (
 customer_id BIGINT NOT NULL REFERENCES parties(id),
 source_type TEXT NOT NULL CHECK (source_type IN ('earlier bill payment','older payment')),
 source_id BIGINT NOT NULL,
 payment_date DATE NOT NULL,
 PRIMARY KEY(customer_id,source_type,source_id)
);
