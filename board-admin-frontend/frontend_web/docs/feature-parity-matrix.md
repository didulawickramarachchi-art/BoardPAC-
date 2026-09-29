# Feature parity and API coverage matrix

This matrix combines the Flutter audit, all 146 backend controller mappings, and the current React implementation as reviewed on 2026-09-28.

## Status legend

- **Complete**: the web workflow calls the correct backend contract with appropriate UI states and access control.
- **Partial**: some operations exist, but behavior, permissions, fields, or states are incomplete.
- **Broken**: web code exists but calls the wrong contract or is unreachable for the intended role.
- **Missing**: applicable backend/mobile functionality has no web integration.
- **Indirect**: supporting endpoint is consumed through a returned URL or helper flow rather than a standalone page.
- **Not applicable**: compatibility, duplicate, or intentionally non-web endpoint; rationale is recorded.

## Feature matrix

| Feature | Flutter implementation | Backend endpoint coverage | Existing React support | Required web work | Status |
|---|---|---|---|---|---|
| Login and token refresh | Login with device identity; secure token refresh | JSON/form login, token refresh | JSON login and refresh interceptor | Add session bootstrap and safer token strategy; form-login variant needs no UI | Partial |
| Two-factor login | Six-digit verification with device identity | Verify 2FA | Dedicated page with a session-persisted challenge and restart path | Complete | Complete |
| Forgot password | Request is available from authenticated profile | Reset-request endpoint | Public request page and login link | Complete | Complete |
| Reset password | Token page, validation, invalid/success states | One-time reset endpoint | Token cleanup, validation, busy/show-password and rejected-link states | Complete | Complete |
| Session/current user | Secure storage and provider state | Current-user and own 2FA endpoints | `/users/me` bootstrap, refresh and own 2FA control | Complete browser adaptation | Complete |
| Profile picture | Authenticated multipart upload | `/users/me/profile-picture` | Validated own-profile upload and account refresh | Complete | Complete |
| User administration | List/add/edit/status/password actions | Full user CRUD, status and paged routes | Paged search/filter, strict create contract, detail/edit/delete and security actions | Complete | Complete |
| Devices | Admin list and all state actions | Device CRUD | List, approve, activate/deactivate, wipe/delete | `POST /devices` is operational/device-enrollment only; it is not exposed as manual web registration | Complete |
| Access validation | Channel validation result screen | Validate by user/channel | User/channel selector with allowed/denied reason result | Complete | Complete |
| Dashboard | Role summaries, recent papers, calendar, news | User summary endpoint | Role summaries, next meeting, recent papers, quick actions and news | Complete | Complete |
| Meeting list | Secretary list and Member-specific list | Secretary, Member and subcategory list routes | Role-specific list, workspace, search and subcategory filter | Complete | Complete |
| Meeting lifecycle | Create/open/close/delete with images | Meeting mutation routes | Image upload plus status-aware create/open/close/delete | Complete | Complete |
| Participants and RSVP | Participant management and self RSVP/reason | Participant list/options/add/status/RSVP | Manager controls and Member RSVP with optional reason | Complete | Complete |
| Agenda sections | Create/list/delete/reorder | All section routes | Create, list, delete and ordered persistence | Complete | Complete |
| Agenda items and sharing | Create/list/delete/reorder/share/shared list | All item/share routes | Delete, reorder, share picker and received/shared view | Complete | Complete |
| Private notes | Full private-note CRUD | All note routes | Full CRUD | Add focused tests | Complete |
| Meeting minutes | Draft and transition workflow | List/create/transition | Role-gated controls and status-valid transitions | Complete | Complete |
| Action items | List/create/status/delete with completion note | All action-item routes | Manager/assignee permissions and completion-note capture | Complete | Complete |
| Paper library | List/detail/by-meeting/by-agenda/create | Paper read/create routes | Detail header, file-first create, by-meeting and by-agenda views | Complete | Complete |
| Paper versions | Revision history/upload | Version list/create | Full list/upload | Add focused tests and file-policy validation | Complete |
| Attachments | Upload/list/reactions | Attachment and file-upload routes | Upload, authenticated download and all reaction choices | Complete | Complete |
| Paper read progress | Read state, recent list and downloaded state | Mark-read plus read-state routes | Restored progress, recent library and download acknowledgment | Complete | Complete |
| Approvals | List and submit by permitted profile | Approval list/create | Profile-gated list and submission | Complete | Complete |
| Comments/replies | CRUD, reactions, reply, visibility and sharing | All comment routes | Participant picker, selected visibility, sharing and all reactions | Complete | Complete |
| Paper sharing | User picker and share action | Paper-share route | Secretary recipient selector with feedback | Complete | Complete |
| PDF and annotations | PDF markup, audio, backup/restore | Annotation and protected-file routes | Authenticated blob rendering, progress restore and web overlay schema | Web overlay interoperability documented | Partial |
| Favorites/member library | Add/remove/list and recent tab | Favorite routes | Source toggles, remove, favorites and recent tabs | Complete | Complete |
| Notifications | List, announcement, read, clear, reply, reactions | All notification routes | Full operations and visibility-aware polling | Complete | Complete |
| News | List, create/edit/delete/order, images, comments/reactions | All news routes | Full CRUD/order, up to 10 images and all reactions | Complete | Complete |
| Categories | CRUD and image | Category CRUD | Admin CRUD with authenticated image upload | Complete | Complete |
| Subcategories | CRUD | Subcategory CRUD | Admin CRUD and navigation | Complete | Complete |
| Privileges | Assign/list/by-user/remove | All privilege routes | Admin assignment, removal and by-user filtering | Complete | Complete |
| Pack delivery | By paper/user and download acknowledgment | All delivery routes | Role-correct views and post-download acknowledgment | Complete | Complete |
| Settings | Definition-aware grouped controls | All/group/key/save/workflow check | Grouped boolean, numeric, enum and text controls with targeted key/workflow checks | Complete | Complete |
| Reports | Standard/admin/personal/meeting reports and PDF | Standard, paged, CSV, personal, admin and meeting-history routes | Role-correct report hub, paged activity reports, filters and authenticated exports | Complete | Complete |
| Issue reporting | Administrative issue capture | Issue endpoint | Admin issue-report form with diagnostic attachment options | Complete | Complete |
| Search | Client aggregation of accessible records | No search endpoint | Role-correct meetings, papers and permitted-user aggregation | Complete within the backend contract | Complete |
| Offline/local capabilities | Downloads, local reminders and notifications | File/download and delivery support | IndexedDB paper retention/removal, offline opening and persisted Notification API reminders | Closed-browser push requires a backend push subscription | Web adaptation complete |
| Calendar and reminders | Monthly schedule and configurable reminders | Meeting list routes | Monthly schedule, day view and persisted reminder offsets | Complete with browser lifecycle limits | Complete |
| Theme preference | System/light/dark persisted preference | Local-only | Persisted light/dark switch with system default | Complete | Complete |

## Endpoint-by-endpoint classification

Every mapped backend operation is included below. The two login rows are separate content-type mappings, giving 146 operations and 145 unique method/path pairs.

### Access, auth, users and devices

| Endpoint | Web status | Required action/rationale |
|---|---|---|
| `GET /api/access-control/validate/{userId}` | Complete | Structured allowed/denied result with channel and reason |
| `POST /api/auth/register` | Not applicable | Public self-registration is intentionally not exposed; Admin creation uses `/users` |
| `POST /api/auth/login` (JSON) | Complete | Existing login flow |
| `POST /api/auth/login` (form) | Not applicable | Compatibility variant; JSON is canonical for React |
| `POST /api/auth/verify-2fa` | Complete | Session-persisted challenge and restart UX |
| `POST /api/auth/password-reset/request` | Complete | Public account-enumeration-safe request flow |
| `POST /api/auth/reset-password` | Complete | One-time token flow with URL cleanup and backend-matched validation |
| `POST /api/tokens/refresh` | Complete | Existing Axios retry path |
| `POST /api/users` | Complete | Create form matches `RegisterRequest` |
| `GET /api/users/me` | Complete | Session bootstrap and profile refresh |
| `PUT /api/users/me/two-factor` | Complete | Profile security control |
| `POST /api/users/me/profile-picture` | Complete | Validated own-profile upload |
| `GET /api/users` | Complete | Used by administration and Admin dashboard |
| `GET /api/users/{id}` | Complete | Admin detail modal |
| `PUT /api/users/{id}` | Complete | Generic edit form calls it |
| `PUT /api/users/{id}/deactivate` | Complete | Existing action |
| `PUT /api/users/{id}/activate` | Complete | Existing action |
| `DELETE /api/users/{id}` | Complete | Username-confirmed destructive action |
| `PUT /api/users/{id}/reset-password` | Complete | Existing Admin action |
| `PUT /api/users/{id}/lock` | Complete | Existing Admin action |
| `PUT /api/users/{id}/unlock` | Complete | Existing Admin action |
| `GET /api/users/paged` | Complete | Server pagination, search and status filtering |
| `POST /api/devices` | Not applicable | Device enrollment is initiated by client login |
| `GET /api/devices` | Complete | Purpose-built page |
| `PUT /api/devices/{id}/approve` | Complete | Existing action |
| `PUT /api/devices/{id}/deactivate` | Complete | Existing action |
| `PUT /api/devices/{id}/activate` | Complete | Existing action |
| `PUT /api/devices/{id}/wipe` | Complete | Existing action |
| `DELETE /api/devices/{id}` | Complete | Existing wiped-device action |

### Meetings and agenda

| Endpoint | Web status | Required action/rationale |
|---|---|---|
| `POST /api/meetings` | Complete | Image upload and contract-aligned payload |
| `GET /api/meetings` | Complete | Authorized contexts use this route; Members use `/meetings/member` |
| `GET /api/meetings/member` | Complete | Member list, workspace lookup and search |
| `GET /api/meetings/subcategory/{subcategoryId}` | Complete | Meetings list subcategory filter |
| `PUT /api/meetings/{meetingId}/open` | Complete | Existing Secretary action |
| `PUT /api/meetings/{meetingId}/close` | Complete | Existing Secretary action |
| `DELETE /api/meetings/{meetingId}` | Complete | Existing Secretary action |
| `POST /api/meetings/participants` | Complete | Existing manager form |
| `GET /api/meetings/{meetingId}/participants` | Complete | Existing tab |
| `GET /api/meetings/{meetingId}/participant-options` | Complete | Existing remote select |
| `PUT /api/meetings/participants/status` | Complete | Manager status controls with optional reasons |
| `PUT /api/meetings/{meetingId}/rsvp` | Complete | Member self-RSVP and reason form |
| `POST /api/agendas/sections` | Complete | Existing form |
| `GET /api/agendas/sections/{meetingId}` | Complete | Existing workspace list |
| `DELETE /api/agendas/sections/{sectionId}` | Complete | Existing action |
| `PUT /api/agendas/sections/{meetingId}/order` | Complete | Ordered-ID controls |
| `POST /api/agendas/items` | Complete | Existing form |
| `GET /api/agendas/items/{meetingId}` | Complete | Existing workspace list |
| `DELETE /api/agendas/items/{itemId}` | Complete | Secretary delete action |
| `PUT /api/agendas/items/{meetingId}/order` | Complete | Ordered-ID controls |
| `POST /api/agendas/share` | Complete | Agenda item and target-subcategory picker |
| `GET /api/agendas/shared/subcategory/{subcategoryId}` | Complete | Meeting subcategory shared-agenda view |
| `GET /api/meeting-workspace/{meetingId}/notes` | Complete | Existing notes panel |
| `POST /api/meeting-workspace/{meetingId}/notes` | Complete | Existing notes panel |
| `PUT /api/meeting-workspace/notes/{noteId}` | Complete | Existing notes panel |
| `DELETE /api/meeting-workspace/notes/{noteId}` | Complete | Existing notes panel |
| `GET /api/meeting-workspace/{meetingId}/minutes` | Complete | Existing minutes panel |
| `POST /api/meeting-workspace/{meetingId}/minutes` | Complete | Secretary-only creation control |
| `PUT /api/meeting-workspace/minutes/{minutesId}/{action}` | Complete | Secretary-only valid status transitions |
| `GET /api/meetings/{meetingId}/action-items` | Complete | Existing panel |
| `POST /api/meetings/{meetingId}/action-items` | Complete | Manager assignment and Member self-assignment |
| `PUT /api/meetings/{meetingId}/action-items/{id}/status` | Complete | Manager/assignee controls with completion note |
| `DELETE /api/meetings/{meetingId}/action-items/{id}` | Complete | Manager or creator visibility |

### Papers, files and collaboration

| Endpoint | Web status | Required action/rationale |
|---|---|---|
| `POST /api/papers` | Complete | Primary file uploads before paper metadata creation |
| `GET /api/papers` | Complete | Existing library |
| `GET /api/papers/{paperId}` | Complete | Paper workspace header/detail |
| `GET /api/papers/meeting/{meetingId}` | Complete | Existing meeting tab |
| `GET /api/papers/agenda-item/{agendaItemId}` | Complete | Agenda item paper counts |
| `PUT /api/papers/{paperId}/read` | Complete | Called when paper header/reader opens |
| `GET /api/papers/{paperId}/versions` | Complete | Existing versions panel |
| `POST /api/papers/{paperId}/versions` | Complete | Existing revision upload |
| `POST /api/papers/share` | Complete | Secretary recipient picker |
| `GET /api/paper-read-states/recent` | Complete | Recent-papers library tab |
| `GET /api/paper-read-states/{paperId}` | Complete | Restores PDF position and displays progress |
| `PUT /api/paper-read-states/{paperId}` | Complete | Debounced PDF progress update |
| `POST /api/attachments` | Complete | Existing upload metadata call |
| `GET /api/attachments/paper/{paperId}` | Complete | Existing attachments panel |
| `POST /api/attachments/{attachmentId}/reaction` | Complete | LIKE, LOVE and DISLIKE controls |
| `POST /api/files/upload` | Complete | Shared multipart helper |
| `POST /api/local-files/upload` | Not applicable | Duplicate/legacy upload path; canonical web path is `/files/upload` |
| `GET /api/files/content/{token}` | Indirect | Returned URLs may use it; authenticated blob path must be verified |
| `GET /api/files/public/{token}` | Indirect | Tokenized public URLs are opened directly |
| `GET /api/secure-files/papers/{paperId}` | Complete | Protected main-paper download resolution |
| `POST /api/approvals` | Complete | Profile-gated submission |
| `GET /api/approvals/paper/{paperId}` | Complete | Existing paper tab |
| `POST /api/annotations` | Complete | Overlay and voice events |
| `GET /api/annotations/paper/{paperId}/user/{userId}` | Complete | Existing annotation load |
| `POST /api/annotations/backup/{userId}` | Complete | Existing backup action |
| `POST /api/annotations/restore` | Complete | Existing restore action |
| `POST /api/comments` | Complete | Existing compose form |
| `PUT /api/comments/{commentId}` | Complete | Existing owner edit |
| `DELETE /api/comments/{commentId}` | Complete | Existing owner delete |
| `GET /api/comments/paper/{paperId}` | Complete | Existing paper thread |
| `GET /api/comments/meeting/{meetingId}` | Complete | Existing meeting thread |
| `POST /api/comments/{commentId}/reaction` | Complete | LIKE, LOVE and DISLIKE controls |
| `POST /api/comments/{commentId}/replies` | Complete | Existing replies |
| `POST /api/comments/share` | Complete | Secretary user picker |
| `GET /api/favorites` | Complete | Existing library |
| `PUT /api/favorites/{type}/{targetId}` | Complete | Meeting and paper save toggles |
| `DELETE /api/favorites/{type}/{targetId}` | Complete | Existing remove action |

### Content, notifications and delivery

| Endpoint | Web status | Required action/rationale |
|---|---|---|
| `GET /api/news` | Complete | Existing dashboard feed |
| `POST /api/news` | Complete | Up to 10 uploaded images |
| `PUT /api/news/{id}` | Complete | Edit UI preserving existing images |
| `DELETE /api/news/{id}` | Complete | Existing Secretary action |
| `PUT /api/news/order` | Complete | Secretary move controls persist ordered IDs |
| `POST /api/news/{id}/comments` | Complete | Existing comment input |
| `POST /api/news/{id}/reactions` | Complete | LIKE, LOVE and CELEBRATE controls |
| `GET /api/notifications/user/{userId}` | Complete | Drawer and unread count |
| `POST /api/notifications/announcement` | Complete | Secretary composer |
| `PUT /api/notifications/user/{userId}/read` | Complete | Existing actions |
| `DELETE /api/notifications/user/{userId}` | Complete | Existing clear action |
| `POST /api/notifications/{notificationId}/reply` | Complete | Existing prompt workflow |
| `POST /api/notifications/{notificationId}/reaction` | Complete | LIKE/LOVE/OK controls |
| `GET /api/pack-delivery/paper/{paperId}` | Complete | Secretary-only paper workspace tab |
| `GET /api/pack-delivery/user/{userId}` | Complete | Current-user table |
| `POST /api/pack-delivery/paper/{paperId}/downloaded` | Complete | Called only after successful protected download |

### Taxonomy, privileges and settings

| Endpoint | Web status | Required action/rationale |
|---|---|---|
| `POST /api/categories` | Complete | Admin form with image upload |
| `GET /api/categories` | Complete | Navigation, forms, calendar and report filters |
| `PUT /api/categories/{id}` | Complete | Admin edit form |
| `DELETE /api/categories/{id}` | Complete | Admin delete action |
| `POST /api/subcategories` | Complete | Admin form |
| `GET /api/subcategories` | Complete | Navigation, forms and report filters |
| `PUT /api/subcategories/{id}` | Complete | Admin edit form |
| `DELETE /api/subcategories/{id}` | Complete | Admin delete action |
| `POST /api/privileges` | Complete | Admin assignment form |
| `GET /api/privileges` | Complete | Admin list |
| `GET /api/privileges/user/{userId}` | Complete | By-user filter |
| `DELETE /api/privileges` | Complete | Admin removal action |
| `POST /api/settings` | Complete | Full mobile definition catalog and bulk save |
| `GET /api/settings` | Complete | Settings overview count |
| `GET /api/settings/group/{group}` | Complete | Existing group page |
| `GET /api/settings/key/{key}` | Complete | Targeted setting lookup |
| `GET /api/workflow-settings/enabled` | Complete | Workflow state checks |

### Dashboard, reports and issues

| Endpoint | Web status | Required action/rationale |
|---|---|---|
| `GET /api/dashboard/summary/{userId}` | Complete | Role dashboard summary |
| `GET /api/activity/me` | Complete | Personal-activity route |
| `GET /api/admin-reports/user-category` | Complete | Dedicated report route |
| `GET /api/admin-reports/license-utilization` | Complete | Metric-oriented report layout |
| `GET /api/admin-reports/pending-approvals` | Complete | Permitted report and approval routes |
| `GET /api/reports/login-history` | Complete | Generic Admin report |
| `GET /api/reports/audit-logs` | Complete | Generic Admin report |
| `GET /api/reports/login-history/paged` | Complete | Server pagination and username filter |
| `GET /api/reports/audit-logs/paged` | Complete | Server pagination and username filter |
| `GET /api/reports/login-history/export` | Complete | Authenticated CSV download |
| `GET /api/reports/audit-logs/export` | Complete | Authenticated CSV download |
| `GET /api/meeting-history-report` | Complete | Category, subcategory and date filters |
| `GET /api/meeting-history-report/pdf` | Complete | Authenticated PDF download |
| `POST /api/issues` | Complete | Admin diagnostic issue form |

## Coverage summary

The React application now covers the mobile workflows and every applicable backend operation. Native-only background behavior is adapted to browser capabilities: offline papers use IndexedDB, reminders use the Notification API while the application is running, and closed-browser push requires a backend subscription contract.
