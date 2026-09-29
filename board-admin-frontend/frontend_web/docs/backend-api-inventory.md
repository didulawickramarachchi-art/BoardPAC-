# Backend API inventory

Source reviewed: all 34 controllers, request DTOs, security configuration and global exception handling under `board-admin-backend/src/main` on 2026-09-28.

## Conventions

- Base URL: `/api`; JSON unless noted otherwise.
- Security is stateless JWT bearer authentication. `/api/auth/**`, `/api/tokens/**`, API documentation and `/api/files/public/**` are public at the HTTP security layer. All other paths require authentication before method-level checks.
- `A` = any authenticated user, `AD` = Admin, `S` = Secretary, `M` = Member, `AP` = access-profile service check, `P` = public.
- Successful reads return a response DTO, a direct JSON array, `PageResponse<T>`, file bytes, or CSV as identified below. Mutations return a response DTO, success string, or `204 No Content`.
- Standard error body: `{timestamp, status, error, message, path}`. Validation errors add `validationErrors`. Expected statuses are 400 validation/business/constraint, 401 authentication, 403 authorization, 404 missing resource, 405 wrong method, and 500 unexpected error.

## Authentication, users and devices

| Method and path | Access | Request | Response/purpose |
|---|---|---|---|
| `POST /api/auth/register` | P | `RegisterRequest` | Success string; self-registration contract, not used by clients |
| `POST /api/auth/login` JSON | P | `LoginRequest` | `LoginResponse`; tokens or 2FA challenge |
| `POST /api/auth/login` form | P | form `LoginRequest` | Same response; compatibility variant |
| `POST /api/auth/verify-2fa` | P | `TwoFactorVerifyRequest` | `LoginResponse` |
| `POST /api/auth/password-reset/request` | P | `PasswordResetEmailRequest` | Generic success string, including unknown email |
| `POST /api/auth/reset-password` | P | `PasswordResetRequest` | Success string; one-time unexpired token required |
| `POST /api/tokens/refresh` | P | `RefreshTokenRequest` | `RefreshTokenResponse` |
| `POST /api/users` | AD | `RegisterRequest` | `UserResponse` |
| `GET /api/users/me` | A | - | Current `UserResponse` |
| `PUT /api/users/me/two-factor` | A | `TwoFactorSettingsRequest` | Updated `UserResponse` |
| `POST /api/users/me/profile-picture` | A | multipart `file` | Updated `UserResponse` |
| `GET /api/users` | AD/S | - | `UserResponse[]` |
| `GET /api/users/{id}` | AD | - | `UserResponse` |
| `PUT /api/users/{id}` | AD | `UserRequest` | Updated `UserResponse` |
| `PUT /api/users/{id}/deactivate` | AD | - | Success string |
| `PUT /api/users/{id}/activate` | AD | - | Success string |
| `DELETE /api/users/{id}` | AD | - | `204` |
| `PUT /api/users/{id}/reset-password` | AD | - | Success string |
| `PUT /api/users/{id}/lock` | AD | - | Success string |
| `PUT /api/users/{id}/unlock` | AD | - | Success string |
| `GET /api/users/paged?page=&size=&search=&status=` | AD | query parameters | `PageResponse<UserResponse>` |
| `POST /api/devices` | AD | `DeviceRequest` | `DeviceResponse` |
| `GET /api/devices` | AD | - | `DeviceResponse[]` |
| `PUT /api/devices/{id}/approve` | AD | - | Success string |
| `PUT /api/devices/{id}/deactivate` | AD | - | Success string |
| `PUT /api/devices/{id}/activate` | AD | - | Success string |
| `PUT /api/devices/{id}/wipe` | AD | - | Success string |
| `DELETE /api/devices/{id}` | AD | - | `204` |
| `GET /api/access-control/validate/{userId}?channel=` | A | `WEB` or `DEVICE` | `AccessValidationResponse` |

## Meetings, agenda and workspace

| Method and path | Access | Request | Response/purpose |
|---|---|---|---|
| `POST /api/meetings` | S | `MeetingRequest` | `MeetingResponse` |
| `GET /api/meetings` | S | - | Accessible `MeetingResponse[]` |
| `GET /api/meetings/member` | M | - | Member-visible `MeetingResponse[]` |
| `GET /api/meetings/subcategory/{subcategoryId}` | S/M | - | `MeetingResponse[]` |
| `PUT /api/meetings/{meetingId}/open` | S | - | Updated `MeetingResponse` |
| `PUT /api/meetings/{meetingId}/close` | S | - | Updated `MeetingResponse` |
| `DELETE /api/meetings/{meetingId}` | S | - | Success string |
| `POST /api/meetings/participants` | S | `MeetingParticipantRequest` | `MeetingParticipantResponse` |
| `GET /api/meetings/{meetingId}/participants` | S/M | - | `MeetingParticipantResponse[]` |
| `GET /api/meetings/{meetingId}/participant-options` | S | - | `ParticipantOptionResponse[]` |
| `PUT /api/meetings/participants/status` | S/M | `ParticipantStatusUpdateRequest` | Updated participant |
| `PUT /api/meetings/{meetingId}/rsvp` | S/M | `ParticipantStatusUpdateRequest` | Updated participant scoped to caller |
| `POST /api/agendas/sections` | S | `AgendaSectionRequest` | `AgendaSectionResponse` |
| `GET /api/agendas/sections/{meetingId}` | S/M | - | `AgendaSectionResponse[]` |
| `DELETE /api/agendas/sections/{sectionId}` | S | - | `204` |
| `PUT /api/agendas/sections/{meetingId}/order` | S | `AgendaOrderRequest` | `204` |
| `POST /api/agendas/items` | S | `AgendaItemRequest` | `AgendaItemResponse` |
| `GET /api/agendas/items/{meetingId}` | S/M | - | `AgendaItemResponse[]` |
| `DELETE /api/agendas/items/{itemId}` | S | - | `204` |
| `PUT /api/agendas/items/{meetingId}/order` | S | `AgendaOrderRequest` | `204` |
| `POST /api/agendas/share` | S | `ShareAgendaItemRequest` | `SharedAgendaItemResponse` |
| `GET /api/agendas/shared/subcategory/{subcategoryId}` | S/M | - | `SharedAgendaItemResponse[]` |
| `GET /api/meeting-workspace/{meetingId}/notes` | S/M | - | `PrivateMeetingNoteResponse[]` |
| `POST /api/meeting-workspace/{meetingId}/notes` | S/M | `MeetingNoteRequest` | Note response |
| `PUT /api/meeting-workspace/notes/{noteId}` | S/M | `MeetingNoteRequest` | Updated note |
| `DELETE /api/meeting-workspace/notes/{noteId}` | S/M | - | `204` |
| `GET /api/meeting-workspace/{meetingId}/minutes` | S/M | - | Visible `MeetingMinutesResponse[]` |
| `POST /api/meeting-workspace/{meetingId}/minutes` | S | `MeetingMinutesRequest` | Minutes response |
| `PUT /api/meeting-workspace/minutes/{minutesId}/{action}` | S | optional `MeetingMinutesRequest` | Transitioned minutes |
| `GET /api/meetings/{meetingId}/action-items` | A + service scope | - | `ActionItemResponse[]` |
| `POST /api/meetings/{meetingId}/action-items` | A + service scope | `ActionItemRequest` | Action item response |
| `PUT /api/meetings/{meetingId}/action-items/{id}/status` | A + service scope | `ActionItemStatusRequest` | Updated action item |
| `DELETE /api/meetings/{meetingId}/action-items/{id}` | A + service scope | - | `204` |

## Papers, files and collaboration

| Method and path | Access | Request | Response/purpose |
|---|---|---|---|
| `POST /api/papers` | S + upload AP | `PaperRequest` | `PaperResponse` |
| `GET /api/papers` | S/M | - | Accessible `PaperResponse[]` |
| `GET /api/papers/{paperId}` | S/M | - | `PaperResponse` |
| `GET /api/papers/meeting/{meetingId}` | S/M | - | `PaperResponse[]` |
| `GET /api/papers/agenda-item/{agendaItemId}` | S/M | - | `PaperResponse[]` |
| `PUT /api/papers/{paperId}/read` | S/M | - | Success string |
| `GET /api/papers/{paperId}/versions` | S/M | - | `PaperResponse[]` |
| `POST /api/papers/{paperId}/versions` | S + upload AP | `PaperRevisionRequest` | Revised `PaperResponse` |
| `POST /api/papers/share` | S | `SharePaperRequest` | Success string |
| `GET /api/paper-read-states/recent` | S/M | - | `RecentPaperResponse[]` |
| `GET /api/paper-read-states/{paperId}` | S/M | - | `PaperReadStateResponse` |
| `PUT /api/paper-read-states/{paperId}` | S/M | `PaperReadStateRequest` | Updated read state |
| `POST /api/attachments` | S + upload AP | `PaperAttachmentRequest` | `PaperAttachmentResponse` |
| `GET /api/attachments/paper/{paperId}` | S/M | - | `PaperAttachmentResponse[]` |
| `POST /api/attachments/{attachmentId}/reaction` | S/M | `ReactionRequest` | Updated attachment |
| `POST /api/files/upload` | AD/S or annotate AP | multipart `file`, optional `meetingId`, `paperId` | `FileUploadResponse` |
| `POST /api/local-files/upload` | S | multipart file | File upload response |
| `GET /api/files/content/{token}` | A | - | File bytes/resource |
| `GET /api/files/public/{token}` | P | - | Public tokenized file bytes |
| `GET /api/secure-files/papers/{paperId}?userId=&action=&channel=` | A + service policy | query parameters | Authorized file response |
| `POST /api/approvals` | A + approve AP | `ApprovalRequest` | `ApprovalResponse` |
| `GET /api/approvals/paper/{paperId}` | A | - | `ApprovalResponse[]` |
| `POST /api/annotations` | A + annotate AP | `AnnotationRequest` | `AnnotationResponse` |
| `GET /api/annotations/paper/{paperId}/user/{userId}` | A | - | `AnnotationResponse[]` |
| `POST /api/annotations/backup/{userId}` | A + annotate AP | - | `AnnotationBackupResponse` |
| `POST /api/annotations/restore` | A + annotate AP | `AnnotationRestoreRequest` | Success string |
| `POST /api/comments` | S/M + comment AP | `CommentRequest` | `CommentResponse` |
| `PUT /api/comments/{commentId}` | S/M + comment AP | `CommentRequest` | Updated comment |
| `DELETE /api/comments/{commentId}` | S/M + comment AP | - | `204` |
| `GET /api/comments/paper/{paperId}` | S/M | - | `CommentResponse[]` |
| `GET /api/comments/meeting/{meetingId}` | S/M | - | `CommentResponse[]` |
| `POST /api/comments/{commentId}/reaction` | S/M + comment AP | `ReactionRequest` | Updated comment |
| `POST /api/comments/{commentId}/replies` | S/M + comment AP | `CommentReplyRequest` | Updated comment |
| `POST /api/comments/share` | S | `ShareCommentRequest` | Success string |
| `GET /api/favorites` | S/M | - | `FavoriteResponse[]` |
| `PUT /api/favorites/{type}/{targetId}` | S/M | - | `FavoriteResponse` |
| `DELETE /api/favorites/{type}/{targetId}` | S/M | - | `204` |

## Content, notifications and delivery

| Method and path | Access | Request | Response/purpose |
|---|---|---|---|
| `GET /api/news?limit=15` | A | query limit 1-100 | `NewsResponse[]` |
| `POST /api/news` | S | `NewsRequest` | `NewsResponse` |
| `PUT /api/news/{id}` | S | `NewsRequest` | Updated news |
| `DELETE /api/news/{id}` | S | - | `204` |
| `PUT /api/news/order` | S | `NewsRequest.orderedIds` | `204` |
| `POST /api/news/{id}/comments` | A | `NewsRequest.message` | Updated news |
| `POST /api/news/{id}/reactions` | A | `NewsRequest.reactionType` | Updated news |
| `GET /api/notifications/user/{userId}?limit=20` | AD/S/M + ownership service check | query limit | `NotificationResponse[]` |
| `POST /api/notifications/announcement` | S | `NotificationRequest` | Success string |
| `PUT /api/notifications/user/{userId}/read` | AD/S/M + ownership service check | - | Success string |
| `DELETE /api/notifications/user/{userId}` | AD/S/M + ownership service check | - | Success string |
| `POST /api/notifications/{notificationId}/reply` | AD/S/M | `NotificationReplyRequest` | Updated notification |
| `POST /api/notifications/{notificationId}/reaction` | AD/S/M | `NotificationReactionRequest` | Updated notification |
| `GET /api/pack-delivery/paper/{paperId}` | S | - | `PackDeliveryResponse[]` |
| `GET /api/pack-delivery/user/{userId}` | S/M | - | `PackDeliveryResponse[]` |
| `POST /api/pack-delivery/paper/{paperId}/downloaded` | S/M | - | Updated delivery response/string |

## Taxonomy, privilege and settings

| Method and path | Access | Request | Response/purpose |
|---|---|---|---|
| `POST /api/categories` | AD | `CategoryRequest` | `CategoryResponse` |
| `GET /api/categories` | AD/S/M | - | `CategoryResponse[]` |
| `PUT /api/categories/{id}` | AD | `CategoryRequest` | Updated category |
| `DELETE /api/categories/{id}` | AD | - | `204` |
| `POST /api/subcategories` | AD | `SubcategoryRequest` | `SubcategoryResponse` |
| `GET /api/subcategories` | AD/S/M | - | `SubcategoryResponse[]` |
| `PUT /api/subcategories/{id}` | AD | `SubcategoryRequest` | Updated subcategory |
| `DELETE /api/subcategories/{id}` | AD | - | `204` |
| `POST /api/privileges` | AD | `PrivilegeAssignRequest` | `PrivilegeResponse` |
| `GET /api/privileges` | AD | - | `PrivilegeResponse[]` |
| `GET /api/privileges/user/{userId}` | AD or same M | - | `PrivilegeResponse[]` |
| `DELETE /api/privileges?userId=&subcategoryId=` | AD | query identifiers | `204` |
| `POST /api/settings` | AD | `SettingRequest` | `SettingResponse` |
| `GET /api/settings` | AD | - | `SettingResponse[]` |
| `GET /api/settings/group/{group}` | AD | - | `SettingResponse[]` |
| `GET /api/settings/key/{key}` | AD | - | `SettingResponse` |
| `GET /api/workflow-settings/enabled?key=` | A | setting key | `WorkflowSettingCheckResponse` |

## Dashboard, reports and issues

| Method and path | Access | Request | Response/purpose |
|---|---|---|---|
| `GET /api/dashboard/summary/{userId}` | A + service visibility | - | `DashboardSummaryResponse` |
| `GET /api/activity/me` | A | - | Caller `AuditLogResponse[]` |
| `GET /api/admin-reports/user-category` | AD | - | `UserCategoryReportResponse[]` |
| `GET /api/admin-reports/license-utilization` | AD | - | `LicenseUtilizationResponse` |
| `GET /api/admin-reports/pending-approvals` | AD or approve AP | - | `PendingApprovalReportResponse[]` |
| `GET /api/reports/login-history` | AD | - | `LoginHistoryResponse[]` |
| `GET /api/reports/audit-logs` | AD | - | `AuditLogResponse[]` |
| `GET /api/reports/login-history/paged?page=&size=&username=` | AD | query filters | `PageResponse<LoginHistoryResponse>` |
| `GET /api/reports/audit-logs/paged?page=&size=&username=` | AD | query filters | `PageResponse<AuditLogResponse>` |
| `GET /api/reports/login-history/export` | AD | - | `text/csv` attachment |
| `GET /api/reports/audit-logs/export` | AD | - | `text/csv` attachment |
| `GET /api/meeting-history-report?categoryId=&subcategoryId=&from=&to=` | S | ISO-date filters | `MeetingHistoryReportResponse[]` |
| `GET /api/meeting-history-report/pdf?categoryId=&subcategoryId=&from=&to=` | S | ISO-date filters | PDF bytes |
| `POST /api/issues` | AD | `IssueReportRequest` | Issue response/success |

## Request DTO dictionary

| DTO | Fields |
|---|---|
| `LoginRequest` | `username`, `password`, `deviceId`, `deviceInfo`, `boardPacVersion`, `osVersion`, `description` |
| `TwoFactorVerifyRequest` | `username`, `code`, plus the same device fields |
| `PasswordResetEmailRequest` | `email` |
| `PasswordResetRequest` | `token`, `newPassword` (8-128 chars, uppercase, lowercase and digit) |
| `RegisterRequest` | `username`, `password`, `firstName`, `lastName`, `boardEmail`, `role`, `boardType`, `accessProfile` |
| `UserRequest` | profile/contact fields, `twoStepEnabled`, `role`, `boardType`, `accessProfile` |
| `MeetingRequest` | title/type/date fields, location, description, image, category/subcategory and creator IDs |
| `ParticipantStatusUpdateRequest` | `meetingId`, `userId`, `participantStatus`, `statusReason` |
| `AgendaSectionRequest` / `AgendaItemRequest` | meeting/section IDs, labels, order and item content/media |
| `PaperRequest` | meeting/agenda IDs, type, title/reference, file data, version, approval/main flags, disclaimer |
| `CommentRequest` | meeting/paper IDs, text, annotation flag, visibility and page |
| `NotificationRequest` | title/message/type, creator/target/related IDs and announcement flag |
| `NewsRequest` | title, content, badge, one/many image URLs, message, reaction type and ordered IDs |
| Other request DTOs | Their fields are represented by the endpoint-specific names above and defined under `dto/{domain}` |

## Audit findings

1. The backend contains 146 mapped controller operations. This document lists every operation, including the two `/auth/login` content-type variants.
2. Password-reset tokens are generated with 256 bits of randomness, stored as SHA-256 hashes, expire after a configurable period (30 minutes by default), are single-use, and revoke refresh tokens and sessions after reset.
3. The local reset-link default now uses `http://localhost:5174/reset-password`; deployments must set `PASSWORD_RESET_FRONTEND_URL` to the public React BrowserRouter URL.
4. `PasswordResetEmailRequest` does not contain `resetUrl`, despite Flutter sending it. The backend configuration is the source of the reset destination.
5. Several ID-based authenticated routes depend on service-layer ownership checks rather than explicit method expressions, notably action items, dashboard summary, secure files and access validation. Web UI visibility must not be treated as the security boundary.
6. `POST /api/issues` is Admin-only, so it is an administrative issue-recording endpoint rather than a general user support form.
7. Public file access is intentionally limited to tokenized `/api/files/public/{token}`; `/api/files/content/{token}` still requires authentication.
