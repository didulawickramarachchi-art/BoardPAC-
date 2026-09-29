# Existing web frontend audit

Source reviewed: `frontend_web/src`, package configuration, existing tests and documentation on 2026-09-28. This is an audit of the current React application; it does not describe proposed implementation as completed work.

## Architecture

| Concern | Current implementation |
|---|---|
| Framework | React with Vite; JavaScript/JSX, no TypeScript |
| Routing | `BrowserRouter` and a centralized route table in `src/App.jsx` |
| State | Local component state plus `AuthContext`; no server-state/query library |
| API client | One shared Axios instance in `src/api/client.js`; direct API calls are distributed across pages/features |
| Authentication | Access token, refresh token and a reduced current-user object in `localStorage`; in-memory 2FA challenge |
| Authorization | `permissionsFor` plus route/component checks; sidebar also has a separate hard-coded role matrix |
| UI | One global, mostly minified `src/styles.css`; Lucide icons; generic tables/forms plus purpose-built workspaces |
| Files/PDF | Multipart helper in `src/api/files.js`; React PDF/PDF.js and a custom annotation overlay |
| Tests | Vitest unit tests for role permissions and annotation schema only |
| Error handling | Axios error helper, reusable loading/error/empty components and a top-level React error boundary |

There is one API client and no mock server or fixture-data layer. Some components accept both direct arrays and `content`/`items` wrappers, which is compatibility handling rather than mock data.

## Route inventory

| Route | Protection | Implementation/status |
|---|---|---|
| `/` | Public | Timed splash/landing redirect |
| `/login` | Public | Login form with password visibility and loading/error states |
| `/verify-2fa` | Public challenge state | Six-digit 2FA form; refresh loses the challenge |
| `/reset-password` | Public | Token reset form; partial flow |
| `/dashboard` | Authenticated | Role-dependent dashboard and news |
| `/meetings` | Authenticated | Generic meeting list/create/actions; broken for Member endpoint contract |
| `/meetings/:id` | Authenticated | Agenda, papers, participants, comments, notes, minutes and action-item tabs |
| `/papers` | Authenticated | Generic paper list/create |
| `/papers/:id` | Authenticated | Attachments, versions, approvals, comments, annotations and delivery tabs |
| `/approvals` | Permission check | Pending-approval report |
| `/users` | Authenticated plus UI permission | Generic user create/edit/status operations |
| `/categories`, `/subcategories` | Authenticated | Generic taxonomy CRUD; sidebar visibility conflicts with backend |
| `/privileges` | Authenticated | Generic privilege assignment/removal; sidebar role is incorrect |
| `/devices` | Admin UI check | Purpose-built device management with 15-second refresh |
| `/access-control` | Authenticated | User list with validation actions; result details are discarded |
| `/pack-delivery` | Authenticated | Current-user delivery table |
| `/favorites` | Authenticated | Favorite list/open/remove; add action absent |
| `/search` | Authenticated | Client-side aggregation of meetings, papers and Admin users |
| `/reports` and child routes | Mixed UI checks | Five generic report tables |
| `/settings` and `/settings/:group` | Admin on home only | Settings group navigation and generic create/update call |
| `/profile` | Authenticated | Profile-image-only page; upload endpoint is incorrect |

## Feature and API coverage

| Domain | Implemented web operations | Missing or incomplete operations |
|---|---|---|
| Auth | Login, 2FA, token refresh, reset-token submission | No forgot-password page/request action; no current-user refresh; no 2FA resend; no server logout/revoke contract |
| Users/profile | List, create, edit, activate/deactivate, lock/unlock, admin reset | Current profile is not fetched; own 2FA toggle absent; profile upload uses wrong URL; user detail/delete/paged list absent |
| Devices/access | Device list, approve, activate/deactivate, wipe/delete; channel validation calls | Device create absent; access-validation response is not presented |
| Meetings | Secretary list/create/open/close/delete; detail workspace | Member list must use `/meetings/member`; subcategory listing and member RSVP absent; meeting image upload absent |
| Participants | List, options, add and Admin-style status actions | Member self-RSVP/reason workflow absent; attendance-specific UI is incomplete |
| Agenda | Section/item list and create; section delete | Item delete, both reorder operations, share and shared-item views absent |
| Meeting workspace | Private-note CRUD; minutes create/transitions; action-item CRUD/status | Minutes controls are shown to Members despite Secretary-only backend; action completion-note prompt/permissions incomplete |
| Papers | List/create, by-meeting, versions, attachments, read-state updates from PDF viewer | Direct detail/by-agenda operations, explicit mark-read and paper sharing absent; create form has no paper-file upload fields |
| Approvals | List by paper, submit decision, pending report | Create control is shown without checking `canApprovePapers`; richer status presentation absent |
| Comments | Paper/meeting list, create/edit/delete, reply, react and comment sharing | Selected-user visibility has no recipient picker; paper sharing absent; raw numeric user-ID prompt is used |
| Annotations | List/create, PDF overlay tools, voice note, backup/restore and read progress | Web overlay is not rendered by Flutter; protected file URL behavior needs end-to-end verification |
| Favorites | List and remove | No add-favorite control on meeting/paper pages |
| Notifications | List, announce, mark-read, clear, reply and react | No background polling/push strategy; unread fetch occurs on mount/open |
| News | List, create, delete, one reaction, comments and single image upload | Edit, reorder, multiple image selection and other reaction choices absent |
| Taxonomy | Category and subcategory list/create/edit/delete | Category image upload absent; navigation permission matrix is wrong |
| Privileges | List, assign and remove | Sidebar exposes it to Secretary instead of Admin |
| Pack delivery | By current user and by paper | Download acknowledgment endpoint is not called by browser downloads |
| Settings | Group list and create/update | Definition-aware controls, all-settings view, key lookup and workflow-enabled check absent |
| Reports | Login, audit, category, license and pending approvals | Personal activity, meeting history/PDF, pagination, filtering and CSV export absent |
| Files/issues | Shared multipart upload and direct links | Local upload, issue reporting and explicit secure-file flow absent |
| Search | Client-side meetings/papers/users search | Member search calls Secretary-only meeting endpoint; no backend search/pagination |

## Confirmed defects

### High priority

1. **Member meeting pages fail authorization.** `src/App.jsx` always configures the meeting list as `GET /meetings`, while the backend requires Members to use `GET /meetings/member`. `MeetingWorkspace` and global search also fetch `/meetings`, so Member list, detail header and search can return 403.
2. **Profile-image upload calls a nonexistent route.** `ProfilePage` posts to `/users/{id}/profile-picture`; the backend exposes only `POST /users/me/profile-picture`.
3. **Sidebar roles disagree with backend security.** Categories/subcategories omit Admin, privileges are shown to Secretary instead of Admin, favorites are shown to Admin although the backend allows only Secretary/Member, and pack delivery hides Secretary access.
4. **Report navigation and authorization are inconsistent.** `ReportsHome` permits approving Secretary/Member profiles but shows Admin-only login, audit, category and license reports. The sidebar, conversely, exposes Reports only to Admin, preventing eligible approvers from reaching pending approvals through navigation.
5. **Role-restricted paper/meeting actions are rendered too broadly.** Member users see minutes creation/transitions, all users see approval submission, and Members can open the paper delivery tab even though `/pack-delivery/paper/{id}` is Secretary-only.

### Password reset and session handling

6. The web has no `/forgot-password` route or `POST /auth/password-reset/request` integration. Login offers no recovery link.
7. Reset submission has no busy state, allowing duplicate requests; it lacks show/hide controls and does not enforce the backend's 128-character maximum.
8. The reset token remains in the address bar/history after the page loads. Invalid, expired and already-used tokens share a generic server error state.
9. The backend default email URL uses hash routing, while this app uses `BrowserRouter`; deployment configuration must point to `/reset-password?token=...`.
10. `AuthContext` trusts the reduced `currentUser` object from `localStorage` without calling `/users/me`. A stale user can enter protected routes until an API call fails.
11. Access and refresh tokens are stored in `localStorage`. This matches the current backend contract but increases exposure to injected scripts compared with HttpOnly cookies.
12. The 2FA challenge exists only in React memory, so refreshing `/verify-2fa` returns the user to login.

### Workflow and data-contract issues

13. Access-control actions perform validation but discard `AccessValidationResponse`; users receive only a generic success message.
14. The user creation form sends profile fields that are not part of backend `RegisterRequest`. Unknown values may be ignored, so display name, office contacts, job title and 2FA selection are not reliably created.
15. Generic `ResourcePage` has no backend pagination. Users and report tables fetch complete unpaged collections despite available paged endpoints.
16. Meeting item reordering, agenda sharing, favorite creation, paper sharing, news editing/order and report exports have no UI.
17. Direct `<a href>` and React PDF file loading do not attach Axios authorization headers. This works only when backend responses contain public/tokenized URLs; authenticated file paths need a blob-fetch path.
18. The global search downloads full collections and searches serialized JSON in the browser. It is limited to 25 displayed results per group and does not search all backend domains.

## UI and maintainability observations

- `App.jsx`, `MobileParity.jsx`, `Workspaces.jsx` and several feature files contain dense single-line JSX, making contract review and targeted changes difficult.
- API calls and collection-normalization helpers are duplicated across components. There is one Axios client, but no domain API modules or shared query/state layer.
- Permission rules are duplicated between `permissionsFor`, the sidebar role arrays, route logic and individual components. The confirmed role defects are a direct consequence.
- `styles.css` contains two `:root` theme definitions; the later definition silently overrides several earlier variables.
- Native `window.prompt` and `window.confirm` are used for comments, backup restore, minutes rejection and destructive actions. These flows lack structured validation and accessible dialog behavior.
- Generic tables infer columns from the first response row and serialize nested objects as JSON, which produces unstable or noisy report/admin presentation.
- There are no obvious hard-coded mock records. Fallback labels and zero-valued dashboard fields are presentation defaults, not fake API data.

## Test and build baseline

Executed from `frontend_web`:

- `npm test`: passed, 2 files and 7 tests.
- `npm run lint`: passed with no reported violations.
- Production build was not run during this read-only audit because it writes to the existing `dist` directory.

Current tests do not cover authentication refresh, protected routing, password reset, API components, role-specific navigation, forms, uploads, meeting/paper workspaces or error states. Component/integration tests will be needed before broad feature work is considered verified.

## Recommended implementation order from this audit

1. Correct endpoint and role-routing defects: Member meetings/search, profile photo, sidebar/report permissions and restricted workspace actions.
2. Complete public password recovery and strengthen session restoration.
3. Centralize domain API functions and one permission-driven navigation definition.
4. Complete missing mobile workflows domain by domain.
5. Add component/integration coverage, then responsive and browser verification.
