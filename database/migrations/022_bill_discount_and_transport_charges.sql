-- Additive bill adjustments. Existing bill and payment data is left untouched.
ALTER TABLE sales
  ADD COLUMN IF NOT EXISTS less_amount NUMERIC(18,2) NOT NULL DEFAULT 0
  CHECK (less_amount >= 0);

ALTER TABLE dealer_bills
  ADD COLUMN IF NOT EXISTS transport_charges NUMERIC(18,2) NOT NULL DEFAULT 0
  CHECK (transport_charges >= 0);
