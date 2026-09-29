# Website feature-parity implementation plan

This plan converts the repository audits into an ordered implementation sequence. It targets the existing React/Vite application and Spring Boot API without rewriting either application or changing the Flutter client.

## Scope and guardrails

- Treat backend controllers, DTOs and authorization expressions as the contract source of truth.
- Preserve the current React, React Router, Axios, Vitest and CSS stack.
- Do not migrate the project to TypeScript as part of parity work. Use small domain API modules and JSDoc where contract clarity is useful.
- Preserve the existing audit documents and all unrelated worktree changes.
- Do not edit or commit generated files under `node_modules/.vite` or `dist`.
- Keep backend changes limited to confirmed contract/configuration defects. The current password-reset backend is already secure enough to integrate; its deployment URL requires configuration, not a new reset implementation.
- Complete and verify one phase before opening the next broad feature area.

## Phase overview

| Phase | Objective | Depends on | Primary result |
|---|---|---|---|
| 0 | Baseline and test harness | None | Reproducible checks and protected worktree |
| 1 | API and permission foundation | Phase 0 | Central contracts, navigation and errors |
| 2 | Authentication and password recovery | Phase 1 | Reliable session, forgot/reset flow |
| 3 | Correct broken role workflows | Phases 1-2 | Member meetings and Admin navigation work |
| 4 | Meetings, participants and agendas | Phase 3 | Complete meeting lifecycle parity |
| 5 | Papers, files and collaboration | Phase 4 | Complete document workflows |
| 6 | News, notifications and library | Phase 5 | Secondary collaboration parity |
| 7 | Administration and settings | Phases 1-3 | Complete Admin workflows |
| 8 | Reports and exports | Phase 7 | Complete report coverage |
| 9 | Web platform adaptations | Phases 5-8 | Defined download/offline/notification behavior |
| 10 | Full verification and handoff | All phases | Evidence-backed parity status |

## Phase 0: baseline and test harness

### Work

1. Record `git status --short` and preserve all existing changes.
2. Confirm Node/npm versions and run the existing `npm test` and `npm run lint` baseline.
3. Run `npm run build` once implementation begins, after confirming `dist` is ignored or generated-only.
4. Add a browser-capable Vitest setup for component tests. Prefer the smallest required additions: `jsdom`, React Testing Library and user-event.
5. Add shared test helpers for rendering with `BrowserRouter` and `AuthProvider`, plus an Axios mock boundary.
6. Prevent generated Vite/Vitest caches from being included in implementation diffs.

### Acceptance criteria

- Existing 7 unit tests continue to pass.
- A minimal rendered-route smoke test passes.
- Lint and test commands leave no intentional source changes.

## Phase 1: API and permission foundation

### Target files

- `src/api/client.js`
- `src/api/files.js`
- New domain modules under `src/api/`, such as `auth.js`, `meetings.js`, `papers.js`, `admin.js` and `reports.js`
- `src/auth/permissions.js`
- `src/components/AppShell.jsx`
- `src/App.jsx`
- `src/pages/ResourcePage.jsx`

### Work

1. Keep one Axios instance, but move endpoint-specific calls from components into small domain functions.
2. Standardize direct-list, paged-list and singleton response normalization without guessing incompatible shapes.
3. Improve normalized errors to preserve backend `message` and field-level `validationErrors`.
4. Add request cancellation for page loads where practical.
5. Replace the sidebar's separate role arrays with one permission-driven navigation definition based on `permissionsFor`.
6. Add route guards for permissions, not only authentication.
7. Add action-level busy state to `ResourcePage` to prevent duplicate mutations.
8. Add explicit update/delete endpoint overrides so generic pages do not assume every GET path is also a mutation base.
9. Keep existing visual components and CSS conventions; defer broad formatting/refactoring to touched modules only.

### Acceptance criteria

- Categories, subcategories and privileges are visible to Admin and hidden from unauthorized roles.
- Favorites, pack delivery, reports and approvals appear only when permitted.
- A denied route redirects or renders a clear permission state before making a forbidden API call.
- API errors consistently show backend validation messages.

## Phase 2: authentication and password recovery

### Target files

- `src/state/AuthContext.jsx`
- `src/api/client.js`
- `src/pages/AuthPages.jsx`
- `src/pages/MobileParity.jsx` or dedicated `ForgotPasswordPage.jsx` and `ResetPasswordPage.jsx`
- `src/App.jsx`
- `.env.example`
- Backend deployment configuration documentation

### Work

1. On application startup, restore tokens and call `GET /users/me` before treating the session as authenticated.
2. Clear only BoardPAC-owned storage keys on logout/refresh failure instead of all `localStorage`.
3. Preserve the browser installation ID.
4. Handle refresh failure once, redirect to login and avoid refresh loops.
5. Add `/forgot-password` with email validation, duplicate-submit prevention and the backend's account-enumeration-safe success message.
6. Add a “Forgot password?” link to login.
7. Upgrade `/reset-password` with show/hide controls, 8-128 character validation, uppercase/lowercase/number rules, matching confirmation, busy state and disabled duplicate submission.
8. Distinguish missing token from server-rejected/expired token and provide a link to request another email.
9. Read the token once and remove it from visible browser history using `history.replaceState` after retaining it in component memory.
10. Verify `app.password-reset.frontend-url` points to the React deployment's `/reset-password`, not the backend's hash-routing default.
11. Add profile controls for `PUT /users/me/two-factor` and correct upload to `POST /users/me/profile-picture`.
12. Refresh the current user after profile or 2FA changes.

### Tests

- Session bootstrap: valid token, expired token with refresh, failed refresh.
- Login: normal success, 2FA challenge and invalid credentials.
- Forgot password: valid email, invalid email, duplicate-click prevention and generic success.
- Reset password: missing, invalid, expired and valid token; mismatch and complexity validation; successful redirect path.
- Profile picture and 2FA use the exact `/users/me` contracts.

### Acceptance criteria

- A user can request and complete password recovery without being signed in.
- Reset tokens are never logged and do not remain in the address bar after capture.
- Reloading the app restores a valid session from the backend user record, not stale cached identity alone.

## Phase 3: correct broken role workflows

### Work

1. Use `GET /meetings` for Secretary and `GET /meetings/member` for Member in lists, workspace lookup and global search.
2. Keep Admin out of meeting/paper routes unless backend authorization explicitly permits it.
3. Correct category/subcategory/privilege navigation to Admin.
4. Remove Admin access to favorites unless backend policy is expanded.
5. Expose pack-delivery user view to Secretary and Member, but paper delivery only to Secretary.
6. Split report navigation:
   - Admin: login history, audit logs, user/category, license utilization and pending approvals.
   - Approval-capable Secretary/Member: pending approvals only.
   - Authenticated user: personal activity when added.
   - Secretary: meeting history.
7. Hide minutes create/transition controls from Members.
8. Hide approval submission unless `canApprovePapers` is true.
9. Replace access-control generic notices with a result panel showing allowed/denied status and reasons.

### Acceptance criteria

- Admin, Secretary and Member navigation snapshots match backend policy.
- Opening every visible navigation item does not immediately produce a role-based 403.
- Member meeting list, detail header and search work with Member endpoints.

## Phase 4: meetings, participants and agendas

### Work

1. Complete meeting create with image upload through `POST /files/upload` and `imageUrl` in `MeetingRequest`.
2. Add status-aware open/close/delete controls and confirmations.
3. Add subcategory filtering using `GET /meetings/subcategory/{subcategoryId}` where it improves navigation.
4. Add Member RSVP with `PUT /meetings/{meetingId}/rsvp`, status and optional reason.
5. Preserve Secretary participant add/status management and distinguish self RSVP from manager status changes.
6. Add agenda section ordering through `PUT /agendas/sections/{meetingId}/order`.
7. Add agenda item delete and ordering.
8. Add agenda sharing with a target-subcategory selector and a shared-agenda view.
9. Apply role rules to action-item create/delete; allow valid assignee status updates and request a completion note.
10. Keep private-note CRUD available to authenticated meeting participants.
11. Show minutes mutations only to Secretary and valid actions for the current status.

### Tests

- Secretary and Member meeting endpoint selection.
- RSVP body and reason handling.
- Agenda reorder payloads.
- Meeting manager versus Member controls.
- Completion-note and minutes-transition rules.

### Acceptance criteria

- Every meeting/agenda endpoint in the parity matrix is implemented or explicitly documented as intentionally unused.
- Member and Secretary workflows can be completed without hidden manual API calls.

## Phase 5: papers, files and collaboration

### Work

1. Fetch `GET /papers/{paperId}` for a real paper workspace header and metadata.
2. Complete paper creation: upload file first, then submit `filePath`, `fileName` and all `PaperRequest` fields.
3. Add agenda-item paper filtering where the agenda workflow needs it.
4. Load `GET /paper-read-states/{paperId}` and restore the saved PDF page.
5. Keep debounced read-state updates and call explicit paper mark-read at the agreed open/read event.
6. Add recent papers using `GET /paper-read-states/recent`.
7. Route protected files through Axios blob retrieval or `GET /secure-files/papers/{paperId}` instead of unauthenticated direct anchors.
8. Call pack-delivery downloaded acknowledgment only after a successful download.
9. Add favorite controls using `PUT /favorites/{type}/{targetId}`.
10. Add paper sharing with an authorized user selector.
11. Replace comment-share numeric prompts with user selection; support selected-user visibility data expected by the backend.
12. Gate approval submission by profile and improve status display.
13. Preserve annotation backup/restore and voice notes; document the existing web-overlay interoperability limitation.
14. Expose backend-supported reaction choices instead of hard-coding one type.

### Tests

- Upload then create sequencing and upload failure behavior.
- Protected file download and delivery acknowledgment.
- Saved-page restoration and update debounce.
- Approval, favorite and share permissions.
- Comment ownership and selected-user flow.

### Acceptance criteria

- A permitted user can create, upload, read, resume, annotate, share, approve and favorite a paper through the web.
- Protected files do not depend on an unauthenticated browser navigation when authentication is required.

## Phase 6: news, notifications and library

### Work

1. Add news editing through `PUT /news/{id}`.
2. Support up to 10 images and preserve existing images during edit.
3. Add news ordering through `PUT /news/order`.
4. Expose LIKE, LOVE and CELEBRATE reactions where supported.
5. Keep notification list, announcement, mark-read, clear, reply and reaction operations.
6. Add a modest polling strategy while the app is visible, with cleanup on unmount; do not claim browser push without a subscription backend contract.
7. Add the recent-papers tab to the member library and favorite toggles to source pages.

### Acceptance criteria

- News create/edit/delete/order and multi-image behavior match backend constraints.
- Notification polling does not duplicate timers or continue after logout.
- Library supports adding, opening and removing favorites plus recent papers.

## Phase 7: administration and settings

### Work

1. Replace unpaged user administration with `GET /users/paged` including page, size, search and status.
2. Add user detail loading and delete with strong confirmation.
3. Align create form fields strictly with `RegisterRequest`; collect additional profile fields only in a follow-up `PUT /users/{id}` if required.
4. Preserve all user status and password-reset actions.
5. Decide whether `POST /devices` is a real Admin workflow. Implement manual registration only if product behavior requires it; otherwise document it as operational/API-only.
6. Add category image upload and retain full category/subcategory CRUD.
7. Add privilege by-user view.
8. Replace generic settings strings with controls derived from existing setting definitions.
9. Use `GET /settings`, `/settings/key/{key}` and `/workflow-settings/enabled` where consumers need targeted configuration.
10. Add an Admin issue-report form for `POST /issues`, or document the endpoint as operational-only if that matches ownership.

### Acceptance criteria

- All Admin navigation is reachable only by Admin and all visible actions match backend authorization.
- User creation does not silently discard form fields.
- Settings values are edited with appropriate boolean, numeric, enum or text controls.

## Phase 8: reports and exports

### Work

1. Add personal activity through `GET /activity/me`.
2. Use paged login-history and audit-log endpoints with username filters.
3. Add authenticated CSV downloads for both report exports.
4. Add meeting history with category, subcategory and ISO date filters.
5. Add authenticated meeting-history PDF download.
6. Keep user/category, license and pending-approval reports, but replace generic singleton/object rendering with report-specific layouts.
7. Apply the corrected report permission menu from Phase 3.

### Acceptance criteria

- Every report endpoint has a permitted route or an explicit non-web rationale.
- Large reports paginate and exports download with meaningful filenames.

## Phase 9: web platform adaptations

### Work

1. Define whether browser offline papers are unsupported or implement IndexedDB/Cache Storage with an approved retention policy.
2. Keep in-app notifications as the supported baseline; browser push requires a separate backend subscription contract.
3. Document that browsers cannot guarantee screenshot or screen-recording prevention.
4. Confirm microphone recording requires HTTPS outside localhost and provide permission/error states.
5. Verify file opening, PDF rendering and annotation interactions at desktop and mobile widths.
6. Keep the `boardpac.web-annotation/v1` schema until Flutter adds a compatible renderer or the backend produces shared annotated PDFs.

## Phase 10: full verification and handoff

### Automated checks

1. `npm run lint`
2. `npm test`
3. `npm run build`
4. Backend tests relevant to any changed configuration or contract
5. Endpoint coverage comparison against `docs/backend-api-inventory.md`

### Browser verification

Test Admin, Secretary and Member profiles at desktop and mobile widths:

- Login, refresh, 2FA, logout and expired session.
- Forgot/reset password with valid, invalid, expired and already-used token.
- Every visible navigation route.
- Meeting create/manage and Member RSVP.
- Agenda creation/order/share.
- Paper upload/read/resume/download/annotation/comment/share/approval/favorite.
- News and notifications.
- User/device/category/privilege/settings administration.
- Report filtering, pagination and downloads.
- Loading, empty, permission-denied, validation, network-error and destructive-confirmation states.

### Definition of done

- The feature parity matrix is updated with evidence for every status change.
- All 146 backend mappings remain classified with no silent omissions.
- Applicable user-facing endpoints are integrated; indirect and not-applicable endpoints retain a written rationale.
- Lint, tests and production build pass, or unrelated failures are documented with exact output.
- No secrets, tokens, generated caches or unrelated files appear in the final diff.
- The development server is started and its URL is provided for user acceptance testing.

## First implementation batch

The safest first code batch is Phases 0-3 together: test harness, centralized permissions/navigation, authenticated session bootstrap, complete forgot/reset flow, Member meeting endpoint correction and profile upload correction. This removes the known broken paths before adding new feature surface.
