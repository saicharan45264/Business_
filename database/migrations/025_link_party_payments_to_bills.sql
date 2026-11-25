-- Link newly recorded customer/dealer payments to a bill from the same date.
-- Nullable columns are additive; existing payment records remain unlinked and unchanged.
ALTER TABLE customer_opening_payments
  ADD COLUMN IF NOT EXISTS sale_id BIGINT REFERENCES sales(id);

-- Migration 017's inline CHECK(balance_effect <= total) is redundant for
-- discounts and may survive alongside the explicitly named replacement.
ALTER TABLE customer_opening_payments
  DROP CONSTRAINT IF EXISTS customer_opening_payments_check1;

CREATE INDEX IF NOT EXISTS customer_opening_payments_sale_idx
  ON customer_opening_payments(sale_id) WHERE sale_id IS NOT NULL;

ALTER TABLE supplier_payments
  ADD COLUMN IF NOT EXISTS dealer_bill_id BIGINT REFERENCES dealer_bills(id);

CREATE INDEX IF NOT EXISTS supplier_payments_bill_idx
  ON supplier_payments(dealer_bill_id) WHERE dealer_bill_id IS NOT NULL;

-- Payments only auto-link to bills created after this feature was installed.
-- This prevents backfilling historical bills when old payment dates are entered.
CREATE TABLE IF NOT EXISTS payment_bill_matching_config (
  singleton BOOLEAN PRIMARY KEY DEFAULT TRUE CHECK (singleton),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO payment_bill_matching_config(singleton)
VALUES (TRUE)
ON CONFLICT (singleton) DO NOTHING;
