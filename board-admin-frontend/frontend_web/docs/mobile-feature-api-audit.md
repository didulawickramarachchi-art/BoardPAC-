# Mobile feature and API audit

Source reviewed: `board-admin-frontend/frontend/lib` on 2026-09-28. The Flutter client is the behavioral reference for the React website. Backend authorization remains authoritative when the client-side role matrix differs.

## Runtime architecture

- Flutter/Dart with Riverpod providers and feature-scoped repositories.
- Dio uses `API_BASE_URL`, defaulting to `http://10.0.2.2:8081/api` on Android emulators and `http://localhost:8081/api` elsewhere.
- The auth interceptor adds the bearer token and retries one 401 through `POST /tokens/refresh`.
- Credentials and tokens use Flutter Secure Storage. Local notifications, downloaded papers, and PDF annotations have platform-specific behavior.
- Navigation is primarily `MaterialPageRoute`; named public routes are `/`, `/login`, `/verify-2fa`, `/dashboard`, and `/reset-password?token=...`.

## Roles and access profiles

| Role | Profiles | Mobile capability summary |
|---|---|---|
| `ADMIN` | `BOARD_ADMINISTRATOR`, `SYSTEM_ADMINISTRATOR` | Users, devices, privileges, settings, reports, categories and subcategories |
| `SECRETARY` | `BOARD_SECRETARY`, `SECRETARY_ASSISTANT`, `SECRETARY_UPLOAD_ONLY` | Meetings, participants, agendas, papers, minutes, announcements and pack delivery; upload-only cannot manage meetings |
| `MEMBER` | `MEMBER`, `MEMBER_VIEW_ONLY`, `MEMBER_VIEW_COMMENTS` | Assigned meetings and papers, RSVP, reading, favorites, notes and permitted collaboration |

Profile gates in `RoleAccess` additionally control commenting, approving, annotating, paper upload, pending approvals, and reports. The backend's `@PreAuthorize` expressions must be used as the final rule when recreating these controls on the web.

## Screen and workflow inventory

| Area | Mobile screens/workflows | Important states and validation | Mobile API coverage |
|---|---|---|---|
| Authentication | Landing, login, 2FA verification, reset password | Required username/password; loading and inline error; 2FA challenge; reset token missing, submitting, invalid/expired error and success; new password requires 8+ chars, upper/lowercase and number | `POST /auth/login`, `/auth/verify-2fa`, `/auth/password-reset/request`, `/auth/reset-password`; refresh interceptor uses `POST /tokens/refresh` |
| Profile | Profile details, profile photo, two-factor toggle, request reset email | Image upload progress/error; optimistic 2FA toggle with rollback; generic reset-request response | `GET /users/me`, `PUT /users/me/two-factor`, `POST /users/me/profile-picture`, reset request |
| Dashboard | Role-specific summaries, quick actions, recent papers, calendar, news, notifications | Loading/error/empty provider states; role-filtered modules | `GET /dashboard/summary/{userId}`, `/paper-read-states/recent`, `/news`, notification endpoints |
| Meetings | Meeting/circular lists, create form, detail tabs, calendar, reminders, open/close/delete | Required title/type/date/category/subcategory; image upload; tabs and search/filter; confirmation before delete | Meeting CRUD/state routes, member list, subcategory list, image upload |
| Participants | Participant list/options, add participant, attendance/status, self RSVP with optional reason | Eligible/already-added distinction; status feedback; RSVP reason dialog | Participant list/options/add, status update and `PUT /meetings/{id}/rsvp` |
| Agenda | Sections and items, add/delete/reorder | Required meeting/title/type data; async empty/error; delete confirmation | Section/item list/create/delete/order |
| Meeting workspace | Private notes, minutes workflow, action items | Note create/edit/delete; minutes draft and transitions; action item assignee, due date, status and completion note | All meeting-workspace and action-item routes |
| Papers | Paper list, create, details, attachments, revisions, PDF reader | Required meeting/title/type; file upload progress; empty/error; revision note; persisted page progress | Paper list/detail/by-meeting/create/versions, attachments, file upload and read-state routes |
| PDF and annotations | PDF viewing, text markup, ink, sticky notes, voice annotation, backup/restore | Loading/download errors; page/zoom state; unsaved-change confirmation; microphone permission | Annotation list/create/backup/restore; secure/public file URLs are consumed indirectly |
| Approvals | Paper approval list/form and pending approvals | Approval status/comment; permission-gated actions; loading/error/empty | `GET /approvals/paper/{id}`, `POST /approvals`, pending-approval report |
| Comments and sharing | Paper/meeting threads, edit/delete, replies, reactions, share comment/paper | Comment permission; visibility/page context; confirmation and async feedback | All comment routes plus `POST /papers/share` |
| Favorites/library | Favorites and recently opened tabs | Empty/loading/error; open/remove favorite | All favorites routes and recent-paper route |
| Notifications | User feed, announcement composer, mark all read, clear, reply, react | Role-gated announcement; loading/error/empty; in-app replacement for browser push | All notification routes |
| News | Feed/detail, create/edit/delete/reorder, multiple images, comments, reactions | Headline/content required; max 10 images enforced by backend; image upload; reaction toggle | All news routes and file upload |
| Categories | List, add/edit/delete and image upload | Required name/display name; order; image upload; delete confirmation | List/create/update/delete and file upload |
| Subcategories | List, create and delete | Required category/name/display name | List/create/delete; update is not used |
| Users | List, add/edit, activate/deactivate, lock/unlock, admin password reset | Required account and role/profile fields; action confirmations; loading/error/empty | Current-user operations, list/create/update and status operations |
| Privileges | List by category/subcategory/user, assign/remove | Required user, subcategory and assigned role | All privilege routes |
| Devices | List, approve, activate/deactivate, wipe and delete | Status-based actions and destructive confirmations | List and all state/delete routes; mobile does not call device creation directly |
| Access control | Validate a user's `WEB` or `DEVICE` channel | Displays validation result and reasons | `GET /access-control/validate/{userId}?channel=...` |
| Pack delivery | Delivery/download status by paper and by user | Loading/error/empty | All pack-delivery routes |
| Settings | Settings home and group editor | Definition-specific controls and save feedback | List/group/save; key lookup and workflow check are unused |
| Reports | Login history, audit log, personal activity, user/category, license, pending approvals, meeting history and PDF export | Empty/loading/error; meeting-history category/subcategory/date filters; binary PDF download | Non-paged reports, personal/admin reports and both meeting-history routes |
| Search | Global client-side search over already accessible meetings, papers and users | Query filtering, role-aware result types, empty state | No dedicated backend search endpoint |
| Local/platform features | Offline paper storage, reminders, local notifications, secure-screen behavior | Download/cache failures, OS permissions, local schedules | Uses paper/file and pack-delivery APIs; remainder is device-local |

## Mobile endpoint map

The following are direct calls from feature repositories. `{id}` represents runtime identifiers.

| Domain | Endpoints used by Flutter |
|---|---|
| Auth | `POST /auth/login`; `POST /auth/verify-2fa`; `POST /auth/password-reset/request`; `POST /auth/reset-password`; `POST /tokens/refresh` |
| Users | `GET /users/me`; `PUT /users/me/two-factor`; `POST /users/me/profile-picture`; `GET /users`; `POST /users`; `PUT /users/{id}`; activate/deactivate/lock/unlock/reset-password operations |
| Devices/access | `GET /devices`; approve/activate/deactivate/wipe/delete operations; `GET /access-control/validate/{userId}` |
| Taxonomy/privileges | Category list/create/update/delete; subcategory list/create/delete; privilege list/by-user/create/delete |
| Meetings | `GET/POST /meetings`; `GET /meetings/member`; open/close/delete; participant list/options/create/status; RSVP |
| Workspace | Notes list/create/update/delete; minutes list/create/transition; action-items list/create/status/delete |
| Agenda | Sections and items list/create/delete/reorder |
| Papers/files | Paper list/detail/by-meeting/create/versions; attachment list/create/reaction; `POST /files/upload`; read-state get/update/recent |
| Collaboration | Approval list/create; annotation list/create/backup/restore; comments list/create/update/delete/reaction/reply/share; paper share; favorites list/add/remove |
| Content | News list/create/update/delete/reorder/comment/react; notifications list/announce/read/clear/reply/react |
| Delivery/dashboard | Pack delivery by paper/user/downloaded; dashboard summary |
| Administration | Settings list/group/save; standard reports; personal activity; admin reports; meeting-history list/PDF |

## Backend endpoints not used directly by Flutter

These are valid backend operations but have no direct Flutter repository call:

- `POST /auth/register` (administrative creation uses `POST /users`).
- `POST /devices` (device details are submitted through login/2FA instead).
- `POST /agendas/share` and `GET /agendas/shared/subcategory/{subcategoryId}`.
- `GET /meetings/subcategory/{subcategoryId}`.
- `GET /papers/agenda-item/{agendaItemId}` and `PUT /papers/{paperId}/read`.
- `GET /settings/key/{key}` and `GET /workflow-settings/enabled?key=...`.
- `GET /users/{id}`, `DELETE /users/{id}`, and `GET /users/paged`.
- Paged and CSV report endpoints.
- `POST /local-files/upload`, `POST /issues`, and direct secure-file retrieval.
- The mobile app follows returned file/profile URLs, so file-content routes can be used indirectly without a literal repository path.

## Confirmed contract mismatches and risks

1. Flutter sends `{email, resetUrl}` to the reset-request endpoint, but `PasswordResetEmailRequest` accepts only `email`. The backend always builds the email link from `app.password-reset.frontend-url`; the client-provided URL is ignored.
2. The backend default reset URL is `http://localhost:8080/#/reset-password`, while both current clients expect `/reset-password?token=...` with non-hash routing. Deployment configuration must override this value for the React site.
3. Flutter does not expose a forgot-password action on the login screen. Reset email is requested from the authenticated profile screen, even though the backend endpoint is public.
4. Global search is client-side aggregation, so it only searches data already fetched and permitted for the signed-in user.
5. Flutter sends direct arrays and models expect direct arrays. The website may accept `content`/`items` wrappers for compatibility, but the checked backend controllers currently return direct lists except explicitly paged routes.
6. Offline files, local reminders, notification scheduling, secure storage and screenshot restrictions require web-specific alternatives and cannot be copied literally.

## Standard UI states to preserve on the website

Every migrated workflow should retain: initial loading, retryable error, empty result, populated result, submit-in-progress, success feedback, validation feedback, permission denied, expired session, and destructive-action confirmation where relevant. Long lists additionally need search/filter and backend pagination when a paged endpoint exists.
