CREATE TABLE IF NOT EXISTS dealer_orders (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  dealer_id BIGINT NOT NULL REFERENCES parties(id),
  product_id BIGINT NOT NULL REFERENCES products(id),
  boxes INTEGER NOT NULL CHECK (boxes > 0),
  ordered_on DATE NOT NULL DEFAULT CURRENT_DATE,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO products(name) VALUES
  ('Apple'), ('Pomegranate'), ('Grapes'), ('Kiwi'), ('Orange')
ON CONFLICT (name) DO NOTHING;

INSERT INTO parties(name, role) VALUES
  ('MMC', 'supplier'), ('Siva Fruits', 'supplier'), ('Sai Fruits', 'supplier'),
  ('Nani RR Pet', 'retailer'), ('Nani D', 'retailer'), ('Nani MSN', 'retailer'),
  ('Durga', 'retailer'), ('Suresh', 'retailer'), ('Sanyasrao', 'retailer')
ON CONFLICT DO NOTHING;

CREATE INDEX IF NOT EXISTS dealer_orders_date_idx ON dealer_orders(ordered_on DESC);
CREATE INDEX IF NOT EXISTS purchases_supplier_idx ON purchases(supplier_id, created_at DESC);
CREATE INDEX IF NOT EXISTS sales_customer_idx ON sales(retailer_id, created_at DESC);
