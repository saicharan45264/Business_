#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then echo 'Usage: ./scripts/restore-to-new.sh /path/to/backup.dump' >&2; exit 1; fi
backup_file=$1
recovery_db="giri_recovered_$(date '+%Y%m%d_%H%M%S')_$$"
docker compose exec -T postgres pg_restore -l < "$backup_file" > /dev/null
docker compose exec -T postgres createdb -U giri "$recovery_db"
if ! docker compose exec -T postgres pg_restore -U giri -d "$recovery_db" --no-owner --no-privileges --exit-on-error < "$backup_file"; then
  echo "Restore failed. The incomplete database $recovery_db was kept for inspection; the current database was not changed." >&2
  exit 1
fi
docker compose exec -T postgres psql -U giri -d "$recovery_db" -v ON_ERROR_STOP=1 -c "SELECT (SELECT COUNT(*) FROM products) AS fruits, (SELECT COUNT(*) FROM parties) AS customers_and_dealers, (SELECT COUNT(*) FROM sales) AS customer_bills, (SELECT COUNT(*) FROM dealer_bills) AS dealer_bills;"
printf '\nRestored to %s. The original database was not changed.\n' "$recovery_db"
printf 'To inspect, stop the app and run: DATABASE_URL=postgresql://giri:YOUR_PASSWORD@localhost:55432/%s npm run dev\n' "$recovery_db"
