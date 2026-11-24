-- Preserve historical bills and payments while allowing corrections to current balances.
ALTER TABLE parties ADD COLUMN IF NOT EXISTS balance_adjustment NUMERIC(18,2) NOT NULL DEFAULT 0;
