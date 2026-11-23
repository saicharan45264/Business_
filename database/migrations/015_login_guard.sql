CREATE TABLE IF NOT EXISTS app_login_guard (
  id integer PRIMARY KEY CHECK (id = 1),
  failures integer NOT NULL DEFAULT 0,
  locked_until timestamptz
);
