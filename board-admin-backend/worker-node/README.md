Worker node example

- `index.js` enqueues example notification jobs.
- `worker.js` processes jobs: reads notification from DB and sends email + push.

Environment variables (use .env or environment):
- REDIS_URL
- DATABASE_URL (postgres connection string)
- SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS
- FIREBASE_SERVICE_ACCOUNT (path to service account JSON)

Run:

npm install
npm run worker

Tests:

npm test
