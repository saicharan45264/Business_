-- Forward-only stock history. Existing business rows and current batch balances are
-- not changed; the opening quantities are copied into this new history table once.
BEGIN;

-- Hold stock writes until the opening snapshot and all history triggers are ready,
-- so there is no gap where a bill could change stock without a history entry.
LOCK TABLE products, purchases, batches, dealer_bills IN SHARE ROW EXCLUSIVE MODE;

CREATE TABLE IF NOT EXISTS stock_history_config (
  singleton BOOLEAN PRIMARY KEY DEFAULT TRUE CHECK (singleton),
  started_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS stock_history_snapshots (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT NOT NULL,
  boxes INTEGER NOT NULL CHECK (boxes >= 0),
  recorded_at TIMESTAMPTZ NOT NULL,
  event_type TEXT NOT NULL,
  source_id BIGINT
);

CREATE INDEX IF NOT EXISTS stock_history_product_time_idx
  ON stock_history_snapshots(product_id, recorded_at DESC, id DESC);

-- Capture the current stock as the starting point. This is the only baseline;
-- no older history is inferred or backfilled.
WITH baseline AS (
  INSERT INTO stock_history_config(singleton, started_at)
  VALUES (TRUE, clock_timestamp())
  ON CONFLICT (singleton) DO NOTHING
  RETURNING started_at
)
INSERT INTO stock_history_snapshots(product_id, boxes, recorded_at, event_type)
SELECT p.id,
       COALESCE((
         SELECT SUM(b.remaining)::INTEGER
         FROM batches b
         JOIN purchases pu ON pu.id = b.purchase_id
         LEFT JOIN dealer_bills db ON db.id = pu.dealer_bill_id
         WHERE b.product_id = p.id
           AND (pu.is_demo = FALSE OR pu.is_temporary_stock = TRUE)
           AND (pu.dealer_bill_id IS NULL OR db.deleted_at IS NULL)
       ), 0),
       baseline.started_at,
       'opening'
FROM products p
CROSS JOIN baseline;

CREATE OR REPLACE FUNCTION record_stock_history(_product_ids BIGINT[], _event_type TEXT, _source_id BIGINT DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO stock_history_snapshots(product_id, boxes, recorded_at, event_type, source_id)
  SELECT p.id,
         COALESCE((
           SELECT SUM(b.remaining)::INTEGER
           FROM batches b
           JOIN purchases pu ON pu.id = b.purchase_id
           LEFT JOIN dealer_bills db ON db.id = pu.dealer_bill_id
           WHERE b.product_id = p.id
             AND (pu.is_demo = FALSE OR pu.is_temporary_stock = TRUE)
             AND (pu.dealer_bill_id IS NULL OR db.deleted_at IS NULL)
         ), 0),
         clock_timestamp(),
         _event_type,
         _source_id
  FROM products p
  WHERE p.id = ANY(_product_ids);
END;
$$;

CREATE OR REPLACE FUNCTION stock_history_batches_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE ids BIGINT[];
BEGIN
  IF TG_OP = 'INSERT' THEN
    ids := ARRAY[NEW.product_id];
  ELSIF TG_OP = 'DELETE' THEN
    ids := ARRAY[OLD.product_id];
    PERFORM record_stock_history(ids, 'batch_delete', OLD.purchase_id);
    RETURN OLD;
  ELSE
    ids := ARRAY[OLD.product_id, NEW.product_id];
  END IF;
  PERFORM record_stock_history(ids, 'batch_' || lower(TG_OP), NEW.purchase_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS stock_history_batches ON batches;
CREATE TRIGGER stock_history_batches
AFTER INSERT OR UPDATE OR DELETE ON batches
FOR EACH ROW EXECUTE FUNCTION stock_history_batches_trigger();

CREATE OR REPLACE FUNCTION stock_history_purchases_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE ids BIGINT[];
BEGIN
  IF TG_OP = 'INSERT' THEN
    ids := ARRAY[NEW.product_id];
  ELSIF TG_OP = 'DELETE' THEN
    ids := ARRAY[OLD.product_id];
    PERFORM record_stock_history(ids, 'purchase_delete', OLD.id);
    RETURN OLD;
  ELSE
    ids := ARRAY[OLD.product_id, NEW.product_id];
  END IF;
  PERFORM record_stock_history(ids, 'purchase_' || lower(TG_OP), NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS stock_history_purchases ON purchases;
CREATE TRIGGER stock_history_purchases
AFTER INSERT OR UPDATE OR DELETE ON purchases
FOR EACH ROW EXECUTE FUNCTION stock_history_purchases_trigger();

CREATE OR REPLACE FUNCTION stock_history_dealer_bill_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE ids BIGINT[];
BEGIN
  SELECT ARRAY_AGG(DISTINCT product_id ORDER BY product_id)
  INTO ids FROM purchases WHERE dealer_bill_id = NEW.id;
  IF ids IS NOT NULL THEN
    PERFORM record_stock_history(ids, 'dealer_bill_' || CASE WHEN NEW.deleted_at IS NULL THEN 'restored' ELSE 'trashed' END, NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS stock_history_dealer_bill_status ON dealer_bills;
CREATE TRIGGER stock_history_dealer_bill_status
AFTER UPDATE OF deleted_at ON dealer_bills
FOR EACH ROW WHEN (OLD.deleted_at IS DISTINCT FROM NEW.deleted_at)
EXECUTE FUNCTION stock_history_dealer_bill_trigger();

CREATE OR REPLACE FUNCTION stock_history_new_product_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  PERFORM record_stock_history(ARRAY[NEW.id], 'fruit_added', NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS stock_history_new_product ON products;
CREATE TRIGGER stock_history_new_product
AFTER INSERT ON products
FOR EACH ROW EXECUTE FUNCTION stock_history_new_product_trigger();

COMMIT;
