-- Destructive demo reset. Run only when replacing the existing business data.
BEGIN;
TRUNCATE sales_revisions, sale_allocations, sale_lines, sales, receipts, dealer_bill_revisions, batches, purchases, dealer_bills, dealer_orders, supplier_payments, products, parties RESTART IDENTITY;
INSERT INTO products(name) VALUES ('Apple'),('Pomegranate'),('Grapes'),('Kiwi'),('Orange');
INSERT INTO parties(name,role) VALUES ('MMC (Demo)','supplier'),('Siva Fruits (Demo)','supplier'),('Sai Fruits (Demo)','supplier'),('Nani RR Pet (Demo)','retailer'),('Nani D (Demo)','retailer'),('Nani MSN (Demo)','retailer'),('Durga (Demo)','retailer'),('Suresh (Demo)','retailer'),('Sanyasrao (Demo)','retailer');
INSERT INTO dealer_bills(dealer_id,bill_date,current_total,previous_due,total_due,request_key,amount_paid) VALUES
(1,'2026-11-20',50000,0,50000,'demo-dealer-1',30000),
(2,'2026-11-21',44000,0,44000,'demo-dealer-2',20000),
(3,'2026-11-22',20000,0,20000,'demo-dealer-3',10000);
INSERT INTO purchases(supplier_id,product_id,boxes,unit_cost,dealer_bill_id) VALUES
(1,1,50,800,1),(1,4,20,500,1),(2,2,40,700,2),(2,3,20,800,2),(3,5,40,500,3);
INSERT INTO batches(purchase_id,product_id,remaining,unit_cost) SELECT id,product_id,boxes,unit_cost FROM purchases;
INSERT INTO sales(retailer_id,total,request_key,sale_date,previous_due,total_due,amount_paid) VALUES
(4,14000,'demo-customer-1','2026-11-21',0,14000,10000),
(4,6000,'demo-customer-2','2026-11-22',4000,10000,2000),
(5,6000,'demo-customer-3','2026-11-22',0,6000,6000);
INSERT INTO sale_lines(sale_id,product_id,boxes,unit_price) VALUES
(1,1,10,1000),(1,4,5,800),(2,2,6,1000),(3,5,10,600);
INSERT INTO sale_allocations(sale_line_id,batch_id,boxes,unit_cost) VALUES (1,1,10,800),(2,2,5,500),(3,3,6,700),(4,5,10,500);
UPDATE batches SET remaining=remaining-10 WHERE id=1;
UPDATE batches SET remaining=remaining-5 WHERE id=2;
UPDATE batches SET remaining=remaining-6 WHERE id=3;
UPDATE batches SET remaining=remaining-10 WHERE id=5;
COMMIT;
