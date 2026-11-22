#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then echo 'Usage: ./scripts/verify-backup.sh backups/backup-file.dump' >&2; exit 1; fi
backup_file=$1
verify_db="giri_restore_check_$$"
cleanup() { docker compose exec -T postgres dropdb -U giri --if-exists "$verify_db" >/dev/null || true; }
trap cleanup EXIT HUP INT TERM
docker compose exec -T postgres createdb -U giri "$verify_db"
docker compose exec -T postgres pg_restore -U giri -d "$verify_db" --no-owner --no-privileges --exit-on-error < "$backup_file"
docker compose exec -T postgres psql -U giri -d "$verify_db" -v ON_ERROR_STOP=1 -c "SELECT (SELECT COUNT(*) FROM products) AS fruits, (SELECT COUNT(*) FROM parties) AS customers_and_dealers, (SELECT COUNT(*) FROM sales) AS customer_bills, (SELECT COUNT(*) FROM dealer_bills) AS dealer_bills;"
printf 'Restore verification succeeded in a temporary database.\n'
