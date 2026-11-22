ALTER TABLE parties ADD COLUMN IF NOT EXISTS opening_balance NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK(opening_balance >= 0);
