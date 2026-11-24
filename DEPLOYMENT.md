# Render frontend and Vercel backend deployment

Status: preparation only. Do not use a public deployment for business data until authentication/authorization and hosted backups are implemented and verified. CORS restricts browsers; it is not authentication and does not protect the API from direct requests.

## Current deployment preparation

- Render static site: repository root; build `npm ci && npm run build`; publish directory `dist/web`. Set `VITE_API_BASE_URL` to the Vercel API origin, e.g. `https://example.vercel.app` (no `/api/v1`). This is a public build-time value, never a secret. Rebuild after changing it.
- Vercel API: set root directory to `apps/api`; NestJS entry point is `src/main.ts`. Configure `DATABASE_URL` with a hosted PostgreSQL connection string and `FRONTEND_ORIGIN` with the exact Render origin, e.g. `https://example.onrender.com` (no trailing slash). Vercel must reach the database over the internet securely. Restrict database access and use a provider-supported TLS connection URL.
- Vercel functions do not have access to local Docker. The existing Docker-based backup button is unavailable on Vercel. Arrange independent managed PostgreSQL backups, retention, export, and restore testing before any cutover.
- Local Docker PostgreSQL is not accessible from Vercel, and this preparation does not migrate local business data. Never commit credentials or database dumps to Git.

## Before deployment

1. Implement and verify authentication and authorization for the two users on every API endpoint. Do not use a frontend environment variable as a secret. Public URLs must not expose customer records or allow unauthenticated edits/deletions.
2. Connect the Render and Vercel accounts and choose a hosted PostgreSQL provider with a backup/restore plan and suitable TLS and connection pooling.
3. Take and verify a fresh backup of the local database. Restore a copy into a separate staging database, compare counts and balances, and test the application against staging. Do not run demo seed/reset scripts against real data.
4. Test all major paths, dates, stock, bills, duplicate submissions, permissions, and restore in the actual deployment environment. The Vercel NestJS build and connected Render/Vercel integration have not yet been verified.
5. Plan a cutover: stop writes to the local app, take the final backup, restore it into the hosted database, verify business balances and stock, and only then direct users to the hosted site. Preserve the local database and backup until the new system has been verified.

For setup details see [Vercel NestJS documentation](https://vercel.com/docs/frameworks/backend/nestjs) and [Render static sites](https://render.com/docs/static-sites).
