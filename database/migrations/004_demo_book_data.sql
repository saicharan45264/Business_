ALTER TABLE purchases ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE dealer_orders ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE supplier_payments ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT FALSE;

WITH samples(supplier_name, fruit_name, boxes, cost, remaining, sample_key) AS (
  VALUES ('MMC','Apple',30,1200.00,22,'DEMO-MMC-APPLE'),
         ('Siva Fruits','Grapes',18,800.00,11,'DEMO-SIVA-GRAPES'),
         ('Sai Fruits','Orange',24,650.00,24,'DEMO-SAI-ORANGE')
), inserted AS (
  INSERT INTO purchases(supplier_id,product_id,boxes,unit_cost,is_demo)
  SELECT d.id,f.id,s.boxes,s.cost,TRUE FROM samples s
  JOIN parties d ON d.name=s.supplier_name AND d.role='supplier'
  JOIN products f ON f.name=s.fruit_name
  WHERE NOT EXISTS (SELECT 1 FROM purchases p WHERE p.is_demo=TRUE AND p.unit_cost=s.cost AND p.boxes=s.boxes AND p.product_id=f.id AND p.supplier_id=d.id)
  RETURNING id,supplier_id,product_id,boxes,unit_cost
)
INSERT INTO batches(purchase_id,product_id,remaining,unit_cost)
SELECT i.id,i.product_id,CASE p.name WHEN 'Apple' THEN 22 WHEN 'Grapes' THEN 11 ELSE 24 END,i.unit_cost FROM inserted i JOIN products p ON p.id=i.product_id;

INSERT INTO supplier_payments(supplier_id,amount,method,note,is_demo)
SELECT d.id,v.amount,'cash','Demo payment example',TRUE
FROM (VALUES ('MMC',12000.00),('Siva Fruits',5000.00),('Sai Fruits',6000.00)) v(name,amount)
JOIN parties d ON d.name=v.name AND d.role='supplier'
WHERE NOT EXISTS (SELECT 1 FROM supplier_payments sp WHERE sp.supplier_id=d.id AND sp.is_demo=TRUE AND sp.note='Demo payment example');

INSERT INTO dealer_orders(dealer_id,product_id,boxes,note,is_demo)
SELECT d.id,f.id,v.boxes,'Demo order example',TRUE
FROM (VALUES ('MMC','Pomegranate',20),('Siva Fruits','Kiwi',12),('Sai Fruits','Apple',25)) v(dealer_name,fruit_name,boxes)
JOIN parties d ON d.name=v.dealer_name AND d.role='supplier'
JOIN products f ON f.name=v.fruit_name
WHERE NOT EXISTS (SELECT 1 FROM dealer_orders o WHERE o.dealer_id=d.id AND o.product_id=f.id AND o.note='Demo order example' AND o.is_demo=TRUE);
