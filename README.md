# Giri Fruits — development preview

This is an early implementation of the purchase-to-sale workflow. It is not ready for real business data: authentication, safe payment allocation and retry handling, full accounting, bill PDF/sharing, audit history, backups, and many other requirements in IMPLEMENTATION_PLAN.md remain to be built.

## Start

1. Start Docker Desktop and ensure the Docker daemon is running.
2. Copy `.env.example` to `.env` and set a local database password; update DATABASE_URL to match if changing it.
3. Run `docker compose up -d` to start PostgreSQL on localhost port 55432. The SQL schema is applied when the database volume is first created.
4. Run `npm install` and `npm run dev`. Open http://localhost:5173.

The API uses DATABASE_URL if exported; otherwise it uses the development defaults in `.env.example`. Docker Compose reads `.env` automatically; the Node server currently requires environment variables to be exported by the shell. Do not expose this preview on a network: it has no login or authorisation.

`npm run build` checks TypeScript and builds the React interface. Database initialisation scripts only run on a new Docker volume; future changes need an explicit migration mechanism.

## Backup and recovery

Use **Home → Download backup** at the end of each business day. Copy the downloaded `.dump` to a USB drive or an encrypted cloud folder that is not solely on this laptop. Confirm that the copy is present. A backup is a snapshot: work entered after it will not be included. The download includes the database, including bills, stock, payments and deleted records; it does not include source code or files outside the database. PDFs are generated from stored bill data. Keep the project source and logo separately.

A terminal alternative, from the project folder with Docker running:

```sh
./scripts/backup.sh
./scripts/verify-backup.sh backups/NAME-OF-BACKUP.dump
```

Verification restores the backup into a temporary database and deletes that temporary database afterward. It does not change the working database. Repeat this check periodically and after moving to a new machine. Backups are not automatic: download and copy one daily.

To recover without overwriting the current database:

1. Stop the app (`Ctrl+C` in its terminal) and start Docker Desktop and `docker compose up -d`.
2. Put the chosen `.dump` file somewhere accessible. Run `./scripts/restore-to-new.sh /path/to/backup.dump`.
3. The script creates a **separate** database and prints its name. Use the printed `DATABASE_URL` command, substituting the database password, to start the app against that recovered database. Check customers, stock, bills and dates before relying on it.
4. Keep the original database and backups until recovery has been verified. The normal startup still points to the original database; permanently switching databases requires updating the deployment configuration deliberately.

Never use `docker compose down -v` or reset Docker's data when trying to recover. Both can remove the database volume. The project and database currently run locally; a backup kept only on this laptop cannot protect against its loss or failure.
