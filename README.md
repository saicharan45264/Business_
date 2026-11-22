# Giri Fruits — development preview

This is an early implementation of the purchase-to-sale workflow. It is not ready for real business data: authentication, safe payment allocation and retry handling, full accounting, bill PDF/sharing, audit history, backups, and many other requirements in IMPLEMENTATION_PLAN.md remain to be built.

## Start

1. Start Docker Desktop and ensure the Docker daemon is running.
2. Copy `.env.example` to `.env` and set a local database password; update DATABASE_URL to match if changing it.
3. Run `docker compose up -d` to start PostgreSQL on localhost port 55432. The SQL schema is applied when the database volume is first created.
4. Run `npm install` and `npm run dev`. Open http://localhost:5173.

The API uses DATABASE_URL if exported; otherwise it uses the development defaults in `.env.example`. Docker Compose reads `.env` automatically; the Node server currently requires environment variables to be exported by the shell. Do not expose this preview on a network: it has no login or authorisation.

`npm run build` checks TypeScript and builds the React interface. Database initialisation scripts only run on a new Docker volume; future changes need an explicit migration mechanism.
