-- Add per-fruit quantity units and fractional inventory quantities.
-- Existing numeric quantities are preserved exactly; only Pineapple receives kg metadata.
BEGIN;

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS quantity_unit TEXT NOT NULL DEFAULT 'box';

ALTER TABLE products
  DROP CONSTRAINT IF EXISTS products_quantity_unit_check;
ALTER TABLE products
  ADD CONSTRAINT products_quantity_unit_check CHECK (quantity_unit IN ('box', 'kg'));

UPDATE products
SET quantity_unit = 'kg'
WHERE lower(btrim(name)) = 'pineapple';

ALTER TABLE purchases ALTER COLUMN boxes TYPE NUMERIC(12,3) USING boxes::NUMERIC(12,3);
ALTER TABLE batches ALTER COLUMN remaining TYPE NUMERIC(12,3) USING remaining::NUMERIC(12,3);
ALTER TABLE sale_lines ALTER COLUMN boxes TYPE NUMERIC(12,3) USING boxes::NUMERIC(12,3);
ALTER TABLE sale_allocations ALTER COLUMN boxes TYPE NUMERIC(12,3) USING boxes::NUMERIC(12,3);
ALTER TABLE dealer_orders ALTER COLUMN boxes TYPE NUMERIC(12,3) USING boxes::NUMERIC(12,3);
ALTER TABLE stock_history_snapshots ALTER COLUMN boxes TYPE NUMERIC(12,3) USING boxes::NUMERIC(12,3);

CREATE OR REPLACE FUNCTION record_stock_history(_product_ids BIGINT[], _event_type TEXT, _source_id BIGINT DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO stock_history_snapshots(product_id, boxes, recorded_at, event_type, source_id)
  SELECT p.id,
         COALESCE((
           SELECT SUM(b.remaining)::NUMERIC(12,3)
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

COMMIT;
