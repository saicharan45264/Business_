-- NULL means an older payment whose method was not recorded.
ALTER TABLE sales ADD COLUMN IF NOT EXISTS cash_paid NUMERIC(18,2), ADD COLUMN IF NOT EXISTS account_paid NUMERIC(18,2);
ALTER TABLE sales ADD CONSTRAINT sales_payment_split_check CHECK ((cash_paid IS NULL AND account_paid IS NULL) OR (cash_paid IS NOT NULL AND account_paid IS NOT NULL AND cash_paid>=0 AND account_paid>=0 AND cash_paid+account_paid=amount_paid));
