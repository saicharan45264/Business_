-- Preserve any pre-existing duplicates; enforce normalized uniqueness on future writes.
CREATE OR REPLACE FUNCTION enforce_active_directory_name() RETURNS trigger AS $$
DECLARE normalized TEXT; previous_name TEXT;
BEGIN
  NEW.name := btrim(regexp_replace(NEW.name, '[[:space:]]+', ' ', 'g'));
  normalized := lower(NEW.name);
  IF normalized = '' THEN RAISE EXCEPTION 'Name cannot be empty' USING ERRCODE='23514'; END IF;
  IF NEW.archived_at IS NOT NULL THEN RETURN NEW; END IF;
  IF TG_OP = 'UPDATE' THEN
    previous_name := lower(btrim(regexp_replace(OLD.name, '[[:space:]]+', ' ', 'g')));
    IF OLD.archived_at IS NULL AND previous_name=normalized THEN
      IF TG_TABLE_NAME='products' THEN RETURN NEW; END IF;
      IF NEW.role=OLD.role THEN RETURN NEW; END IF;
    END IF;
  END IF;
  IF TG_TABLE_NAME='products' THEN
    PERFORM pg_advisory_xact_lock(hashtextextended('fruit:' || normalized, 0));
    IF EXISTS (SELECT 1 FROM products p WHERE p.archived_at IS NULL AND lower(btrim(regexp_replace(p.name, '[[:space:]]+', ' ', 'g')))=normalized AND p.id<>NEW.id) THEN
      RAISE EXCEPTION 'A fruit with this name already exists' USING ERRCODE='23505';
    END IF;
  ELSE
    PERFORM pg_advisory_xact_lock(hashtextextended('party:' || NEW.role || ':' || normalized, 0));
    IF EXISTS (SELECT 1 FROM parties p WHERE p.archived_at IS NULL AND p.role=NEW.role AND lower(btrim(regexp_replace(p.name, '[[:space:]]+', ' ', 'g')))=normalized AND p.id<>NEW.id) THEN
      RAISE EXCEPTION 'A % with this name already exists', CASE WHEN NEW.role='retailer' THEN 'customer' ELSE 'dealer' END USING ERRCODE='23505';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS products_unique_active_name ON products;
CREATE TRIGGER products_unique_active_name BEFORE INSERT OR UPDATE OF name, archived_at ON products FOR EACH ROW EXECUTE FUNCTION enforce_active_directory_name();
DROP TRIGGER IF EXISTS parties_unique_active_name ON parties;
CREATE TRIGGER parties_unique_active_name BEFORE INSERT OR UPDATE OF name, role, archived_at ON parties FOR EACH ROW EXECUTE FUNCTION enforce_active_directory_name();
