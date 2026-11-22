ALTER TABLE purchases ADD COLUMN IF NOT EXISTS is_temporary_stock BOOLEAN NOT NULL DEFAULT FALSE;
WITH seeded AS (
  INSERT INTO purchases(supplier_id,product_id,boxes,unit_cost,is_demo,is_temporary_stock)
  SELECT d.id,p.id,100,0,TRUE,TRUE
  FROM parties d CROSS JOIN products p
  WHERE d.name='MMC' AND d.role='supplier'
    AND NOT EXISTS (SELECT 1 FROM purchases x WHERE x.product_id=p.id AND x.is_temporary_stock=TRUE)
  RETURNING id,product_id,boxes,unit_cost
)
INSERT INTO batches(purchase_id,product_id,remaining,unit_cost)
SELECT id,product_id,boxes,unit_cost FROM seeded;
