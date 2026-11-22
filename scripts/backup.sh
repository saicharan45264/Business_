#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
umask 077
mkdir -p backups
stamp=$(date '+%Y%m%d-%H%M%S')
tmp=$(mktemp "backups/.giri-${stamp}-XXXXXX")
trap 'rm -f "$tmp"' EXIT HUP INT TERM
docker compose exec -T postgres pg_dump -U giri -d giri_fruits -Fc > "$tmp"
test -s "$tmp"
docker compose exec -T postgres pg_restore -l < "$tmp" > /dev/null
filename="backups/giri-fruits-${stamp}-$$.dump"
mv "$tmp" "$filename"
trap - EXIT HUP INT TERM
printf 'Backup saved: %s\n' "$filename"
