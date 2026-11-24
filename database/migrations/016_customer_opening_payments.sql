CREATE TABLE customer_opening_payments (
 id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 customer_id BIGINT NOT NULL REFERENCES parties(id),
 total NUMERIC(18,2) NOT NULL CHECK(total>0),
 cash NUMERIC(18,2) NOT NULL CHECK(cash>=0),
 account NUMERIC(18,2) NOT NULL CHECK(account>=0),
 request_key TEXT NOT NULL UNIQUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 CHECK(cash+account=total)
);
