# SLPA Board Management Web

Responsive React web frontend for the existing BoardPAC backend. The Flutter application remains unchanged.

## Run locally

1. Copy `.env.example` to `.env` and update `VITE_API_BASE_URL` if needed.
2. Install packages with `npm install`.
3. Start the app with `npm run dev`.

The default API is `http://localhost:8081/api`.

## Commands

- `npm run dev` — development server
- `npm run lint` — JavaScript linting
- `npm run build` — production build in `dist/`
- `npm run preview` — preview the production build

## Included areas

Authentication and 2FA, responsive role-aware application shell, dashboard, meetings, board papers, approvals, users, categories, subcategories, privileges, devices, access control, pack delivery, reports, and settings.

Roles follow the Flutter application: Admin, Secretary, and Member. Data pages use the same REST endpoints as the existing repositories and include search, responsive tables, loading, empty, and error states.
