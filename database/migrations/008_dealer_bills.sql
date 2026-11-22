CREATE TABLE IF NOT EXISTS dealer_bills (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  dealer_id BIGINT NOT NULL REFERENCES parties(id),
  bill_date DATE NOT NULL,
  current_total NUMERIC(18,2) NOT NULL CHECK(current_total>=0),
  previous_due NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK(previous_due>=0),
  total_due NUMERIC(18,2) NOT NULL CHECK(total_due>=0),
  request_key TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS dealer_bill_id BIGINT REFERENCES dealer_bills(id);
CREATE TABLE IF NOT EXISTS dealer_bill_revisions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  dealer_bill_id BIGINT NOT NULL REFERENCES dealer_bills(id),
  snapshot JSONB NOT NULL,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS dealer_bills_date_idx ON dealer_bills(bill_date DESC);
