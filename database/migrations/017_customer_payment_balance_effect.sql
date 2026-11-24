-- Existing payments already reduced the opening balance; only new payments affect the ledger.
ALTER TABLE customer_opening_payments ADD COLUMN IF NOT EXISTS balance_effect NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (balance_effect >= 0 AND balance_effect <= total);
