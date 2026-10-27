# SLPA Board Management Web

Responsive React web frontend for the existing BoardPAC backend. The Flutter application remains unchanged.

## Run locally

1. Copy `.env.example` to `.env` and update `VITE_API_BASE_URL` if needed.
2. Install packages with `npm install`.
3. Start the app with `npm run dev`.

Without an override, the API uses port 8081 on the hostname serving the frontend. For the public website, an ignored `.env.local` sets `VITE_API_BASE_URL=https://bpds.slpa.lk/api`. Restart Vite or rebuild after changing an environment file.

## Public website

Run `npm run build` to refresh `dist/`. Caddy serves the built site at `https://bpds.slpa.lk`, forwards `/api/*` to the backend at `10.105.4.183:8081`, and keeps the existing `https://apds.slpa.lk` API host. The site configuration is in `../../board-admin-backend/migration/public-test/Caddyfile`. After changing it, run `caddy reload --config migration/public-test/Caddyfile --adapter caddyfile` from the backend directory. The backend `.env` allows the `https://bpds.slpa.lk` browser origin and sets password reset links to the public website; restart the backend after changing those settings.

The backend must set `PASSWORD_RESET_FRONTEND_URL` to this site's public reset route, for example `https://board.example.com/reset-password`. The local backend default is `http://localhost:5174/reset-password`.

## Commands

- `npm run dev` — development server
- `npm run lint` — JavaScript linting
- `npm run build` — production build in `dist/`
- `npm run preview` — preview the production build

## Windows service (WinSW)

1. Install Node.js and run `npm install` and `npm run build` in this directory. The service serves the built `dist/` directory; rebuild after frontend changes or changes to `VITE_API_BASE_URL`.
2. Download the [WinSW executable](https://github.com/winsw/winsw/releases) and save it in this directory as `board-admin-web.exe`, beside `board-admin-web.xml`. If Node.js is installed elsewhere, update `<executable>` in the XML.
3. In an elevated PowerShell window in this directory, run `./board-admin-web.exe install` followed by `./board-admin-web.exe start`.
4. Open `http://localhost:5174`. To inspect the service, run `./board-admin-web.exe status`. Logs are written beside the executable.

The service listens on all network interfaces on port 5174. Restrict access with the Windows firewall or a reverse proxy as appropriate. The backend runs separately.

## Included areas

Authentication and 2FA, responsive role-aware application shell, dashboard, meetings, board papers, approvals, users, categories, subcategories, privileges, devices, access control, pack delivery, reports, and settings.

Roles follow the Flutter application: Admin, Secretary, and Member. Data pages use the same REST endpoints as the existing repositories and include search, responsive tables, loading, empty, and error states.
