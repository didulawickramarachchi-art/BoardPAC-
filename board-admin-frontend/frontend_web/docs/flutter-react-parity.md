# Flutter to React parity audit

The Flutter client is the behavioral source of truth. This audit reflects the repository on 2026-09-22. A generic table/form is marked partial when Flutter provides a purpose-built workflow.

| Feature | Flutter source | API endpoints | Access | React state | Gap/status |
|---|---|---|---|---|---|
| Landing, login, 2FA, logout | `auth/presentation`, `auth_repository.dart` | `POST /auth/login`, `/auth/verify-2fa`, `/auth/change-password`, `/auth/reset-password`; `POST /tokens/refresh` | Public/authenticated | Dedicated pages and refresh interceptor | Password-change and current-user refresh incomplete — **partial** |
| User profile/photo | `users/presentation`, `user_repository.dart` | `GET /users/me`, `PUT /users/{id}`, multipart `POST /users/{id}/profile-picture` | Authenticated | Photo upload page | Profile fields and server refresh missing — **partial** |
| Device registration | auth/device services | login device fields; device CRUD endpoints | Login/Admin | Stable web installation id plus admin device UI | Browser identity is a web adaptation — **web-adapted** |
| Dashboard | `dashboard/**`, `news/**` | `GET /dashboard/summary/{userId}`, `GET /news?limit=15` and news mutations | All roles | Role cards, quick actions and interactive news feed | Recent-paper cards remain — **partial** |
| Meetings and circulars | `meetings/**` | `GET /meetings`, `/meetings/member`; `POST /meetings`; `PUT /meetings/{id}/open|close`; delete | Secretary manages; member views | List CRUD and workspace | Member endpoint, reminder/calendar details incomplete — **partial** |
| Participants | `participant_list_screen.dart`, meeting repository | `GET /meetings/{id}/participants`, `/participant-options`; `POST /meetings/participants`; `PUT /meetings/participants/status`, `/attendance` | Secretary manages; participants update status | List/create/status controls | Dedicated self-RSVP reason flow remains — **partial** |
| Agenda | `agendas/**` | sections/items list, create, reorder, delete | Secretary manages | Workspace CRUD | Reordering/deletion of items incomplete — **partial** |
| Private notes | meeting workspace | `/meeting-workspace/{id}/notes`, `/meeting-workspace/notes/{noteId}` | Authenticated participant | Dedicated create/edit/delete panel | **complete** |
| Minutes | meeting workspace | `GET/POST /meeting-workspace/{id}/minutes`; `PUT /meeting-workspace/minutes/{id}/{action}` | Role/action dependent | Dedicated draft/submit/review panel | Transition visibility needs backend permission confirmation — **partial** |
| Action items | action item repository | `/meetings/{id}/action-items`; status and delete endpoints | Meeting users | Create/status/delete panel | Completion-note prompt and per-action permissions remain — **partial** |
| Papers | `papers/**` | paper list/detail/by-meeting/create/version endpoints | Secretary upload; member/secretary view | List/create/workspace/revision upload | Member filtering and richer detail remain — **partial** |
| Attachments/uploads | paper repository | `GET /attachments/paper/{id}`, `POST /attachments`, `POST /files/upload`, reaction endpoint | Paper access | Multipart upload with progress, open and reaction UI | **complete** |
| Read state/recent | paper repository | `GET/PUT /paper-read-states/{paperId}`, `GET /paper-read-states/recent` | Paper access | PDF page progress is persisted | Recent-paper dashboard section remains — **partial** |
| Approvals | `approvals/**` | `GET /approvals/paper/{id}`, `POST /approvals` | Board secretary/member | Form and report table | Purpose-built status UI incomplete — **partial** |
| PDF viewing/annotations | `annotations/**` | annotations list/create/backup/restore | Board secretary/member | PDF.js viewer; page/zoom/download; pen, eraser, undo/redo, highlight, underline, strike, squiggly, sticky notes, color, voice, backup/restore | Web overlays use a documented versioned event schema; Flutter needs a renderer for visual cross-client parity — **web-adapted** |
| Paper/meeting comments | `comments/**` | list, create, update, delete, reaction, replies, comment/paper share | Profiles with comment permission | Threaded create/edit/delete/reply/react/comment-share UI | Paper sharing and selected-user picker remain — **partial** |
| Favorites/library | `favorites/**` | `GET /favorites`, `PUT/DELETE /favorites/{type}/{targetId}` | Authenticated | Library listing/open/remove | Add-favorite actions remain — **partial** |
| Notifications | `notifications/**` | user list, announcement, read, clear, reaction/reply | Authenticated; secretary announces | Drawer, read/clear/reactions/replies | Live delivery/polling strategy remains — **partial** |
| News | `news/**` | list, create/update/delete/order, comments/reactions | All view; secretary manages | Dashboard feed with image create/delete/comments/reactions | Edit, multiple images and ordering remain — **partial** |
| Categories/subcategories | corresponding feature folders | list/create/update/delete and image upload | All view; Admin manages | Generic CRUD | Permissions currently being aligned; image workflow absent — **partial** |
| Privileges | `privileges/**` | list/by-user/create/delete | Admin | Generic create/list | Delete and profile nuance incomplete — **partial** |
| Users | `users/**` | `/users`, status operations, reset, update | Admin | CRUD/status actions | Edit and access-profile fields incomplete — **partial** |
| Devices | `devices/**` | list, approve/activate/deactivate/wipe/delete | Admin | Purpose-built page | **complete** |
| Access control | `access_control/**` | `GET /access-control/validate/{userId}?channel=` | Admin | Basic actions | Result presentation incomplete — **partial** |
| Pack delivery | `pack_delivery/**` | `/pack-delivery/paper/{id}`, `/user/{id}` | Member/paper users | Tables | **partial** |
| Search | `search/presentation/global_search_screen.dart` | Client aggregation across accessible resources | Authenticated | Header-driven accessible resource search | **complete** |
| Settings | `settings/**` | list/group/create | Admin | Group pages | Definition-aware controls incomplete — **partial** |
| Reports | `reports/**` | `/reports/login-history`, `/audit-logs`, `/activity/me`, admin report endpoints and meeting history | Flutter permission rules | Generic tables | Personal activity, meeting history and filters absent — **partial** |

## Request contracts confirmed from Flutter

- Annotation create: `{paperId, userId, annotationType, annotationDataJson, pageNumber}`.
- File upload: multipart field `file`, optional `meetingId`, optional `paperId`; response can be a string or any of `filePath`, `fileUrl`, `url`, `path`, `publicUrl`.
- Action item create: `{title, description, assigneeUserId, dueDate}`; status update: `{status, completionNote}`.
- Private note create/update: `{noteText}`. Minutes create: `{content}`; transition: `{reviewComment}`.
- Paper read state update: `{lastPage, totalPages}`.

Response collections are direct arrays in Flutter. The React compatibility layer also accepts `content` and `items` wrappers because deployments may paginate.

## Implementation order

1. Central permissions, API/file helpers, reusable states and error boundary.
2. Auth/current-user correctness.
3. Meeting notes/minutes/actions and participant state.
4. Actual attachment upload, paper detail/version/read state.
5. Comments/favorites/news/notifications.
6. PDF viewer and interoperable annotation workspace.
7. Search, reports, administration refinements, tests and final verification.

## Annotation interoperability decision

Flutter currently persists only `AUDIO` records through the annotation repository; native Syncfusion text markup and ink are maintained/exported inside PDF bytes. The web editor consequently stores overlay mutations as append-only `WEB_OVERLAY_V1` records using schema `boardpac.web-annotation/v1`. Add and delete events work with the backend's create-only annotation API, and normalized coordinates survive zoom/resizing. Flutter preserves these records but will not visually render them until it implements the same schema. A future shared annotated-PDF endpoint could replace this adaptation.
