# BoardPAC SQL Server migration

`LegacyStagingImporter` is the first, lossless extraction step. It reads SQL Server with Windows Authentication and writes to the `legacy_boardpac` schema of a separate PostgreSQL database. It never changes the source or the application's `public` schema. This staging schema is **not yet application data**; the old and new data models differ and require a reviewed mapping before cutover.

## Local run (PowerShell)

The Microsoft JDBC driver needs its matching Windows authentication DLL. Download the `mssql-jdbc_auth.zip` asset from the [Microsoft JDBC 12.8.1 release](https://github.com/microsoft/mssql-jdbc/releases/tag/v12.8.1) and extract the x64 DLL to `target/mssql-auth/x64`. Do not commit the DLL or credentials.

```powershell
mvn -q -DskipTests compile dependency:build-classpath '-Dmdep.outputFile=target/migration-classpath.txt'
$env:PGPASSWORD = '<PostgreSQL password>'
& 'C:\Program Files\PostgreSQL\18\bin\createdb.exe' -h localhost -U postgres boardpac_migration_stage
Remove-Item Env:PGPASSWORD
$env:MIGRATION_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_migration_stage'
$env:MIGRATION_PG_USER = 'postgres'
$env:MIGRATION_PG_PASSWORD = '<PostgreSQL password>'
$cp = 'target/classes;' + (Get-Content target/migration-classpath.txt -Raw)
java '-Djava.library.path=target/mssql-auth/x64' -cp $cp com.portSrilanka.board_admin_backend.migration.LegacyStagingImporter dbo.Categories dbo.Users
Remove-Item Env:MIGRATION_PG_URL,Env:MIGRATION_PG_USER,Env:MIGRATION_PG_PASSWORD
```

With no table arguments, it imports every source table. This local source currently contains about **21 GB of binary document content** in `dbo.FileStructures`; plan disk space and time before a full import. A table that already exists in staging causes the importer to stop rather than overwrite it. Use a fresh staging database for a repeat run. If the source is remote, set `LEGACY_SQLSERVER_URL` to a JDBC URL with the correct host/database and authentication settings.

Staging text columns are stored as `bytea` to retain invalid bytes and embedded NULs found in legacy records. `legacy_boardpac.source_columns` records the original SQL Server types so a later mapper can decode `nvarchar` as UTF-16LE and `varchar` using its source code page. SQL Server `timestamp`/`rowversion` is also binary; it is not a date.

## Mapping work still required

The destination schema is in `src/main/resources/db/migration`. The source has 87 users, 8 categories, 13 subcategories, 158 meetings, 1,462 headings, 5,084 papers, and 5,111 document versions. A full local rehearsal copied and count-checked all 74 source tables into `boardpac_migration_metadata`. `FileStructures` has 4,805 binary records; its source and staged content lengths both total **22,811,329,376 bytes**. This validates the staging copy, not the later application mapping.

Before writing to the app's tables, resolve these differences explicitly:

1. Map ASP.NET roles and legacy access records to `roles`, `user_roles`, and `user_subcategory_access`. Old password hashes are not compatible with this app's password encoder; users will need a password reset.
2. Map numeric meeting and paper statuses to the app's enum strings. The old status values need business confirmation.
3. Review the imported `Headings` and meeting-linked `Papers` in `agenda_sections`, `agenda_items`, and `papers`. The 939 papers without a meeting link now appear in a separate, read-only admin archive.
4. Review extracted `FileStructures.Content` documents and their `papers.file_path` links. The file linker handles meeting-linked papers; 783 exported current files for unplaced papers are available through the admin archive.
5. Review imported participation, comments, decision history, permissions, and version metadata. Their old numeric workflow states remain read-only or pending. Check row counts and sample records through the app before cutover.

Do not point this program at `board_admin_db` or treat the staging import as the final cutover.

## Clear core records in the new schema

`LegacyCoreMapper` runs Flyway in a **separate, empty** PostgreSQL database, then imports the legacy users, categories, subcategories, and meetings. It records source IDs in `legacy_import_map` and review items in `legacy_import_issues`. It refuses `board_admin_db` and any destination with existing core records.

```powershell
$env:MIGRATION_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_migration_metadata'
$env:MIGRATION_APP_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_app_import_test'
$env:MIGRATION_PG_USER = 'postgres'
$env:MIGRATION_PG_PASSWORD = '<PostgreSQL password>'
$cp = 'target/classes;' + (Get-Content target/migration-classpath.txt -Raw)
java -cp $cp com.portSrilanka.board_admin_backend.migration.LegacyCoreMapper
Remove-Item Env:MIGRATION_PG_URL,Env:MIGRATION_APP_PG_URL,Env:MIGRATION_PG_USER,Env:MIGRATION_PG_PASSWORD
```

The local rehearsal imported 87 users, 8 categories, 13 subcategories, and 158 meetings, with no broken meeting/user/subcategory references. There were 21 missing or duplicate user email occurrences, so those accounts received `migration.invalid` placeholder addresses and an audit issue. All imported users have random password hashes and `DEACTIVATED` status. All meetings are `DRAFT` because the legacy numeric status values and access rules have not been approved for translation.

The old deployed backend at `C:\Users\Administrator\Desktop\Boardpac\wcf\bin` includes the decryption method used for heading descriptions and paper titles. Run the local exporter, then the agenda mapper against the same isolated app database used above:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File migration/Export-LegacyText.ps1
$env:MIGRATION_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_migration_metadata'
$env:MIGRATION_APP_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_app_import_test'
$env:MIGRATION_PG_USER = 'postgres'
$env:MIGRATION_PG_PASSWORD = '<PostgreSQL password>'
$env:MIGRATION_DECRYPTED_TEXT = 'target/legacy-decrypted-text.tsv'
$cp = 'target/classes;' + (Get-Content target/migration-classpath.txt -Raw)
java -cp $cp com.portSrilanka.board_admin_backend.migration.LegacyAgendaMapper
Remove-Item Env:MIGRATION_PG_URL,Env:MIGRATION_APP_PG_URL,Env:MIGRATION_PG_USER,Env:MIGRATION_PG_PASSWORD,Env:MIGRATION_DECRYPTED_TEXT
Remove-Item -LiteralPath target/legacy-decrypted-text.tsv
```

The exporter writes decrypted text to `target` temporarily. This file contains confidential board content, even though each value is Base64 encoded. Keep it local and remove it after the mapper succeeds.

The full isolated rehearsal produced 1,462 agenda sections, 4,145 agenda items, and 4,145 linked papers. It verified matching meeting references and nonempty paper titles. One title exceeded the destination length and was recorded in `legacy_import_issues` as truncated. The source has **939 additional papers without a heading/meeting link**; these remain fully preserved in staging and require placement review. Previous-heading hierarchy is retained in staging and recorded as an issue because the destination section model is flat.

This stage alone is **not** a complete usable app import. The later sections describe document, access, and activity conversion. All imported users are disabled and meetings remain drafts until account and status mapping are reviewed.

## Documents

`Export-LegacyFiles.ps1` uses the old backend's file key derivation and AES provider. It exports `FileStructures` rows of type `BoardPaper` (RefType 0), verifies PDF/ZIP signatures, and writes a SHA-256 manifest. Any record that cannot be decrypted or identified is listed in a separate error file. Other FileTypes (annotations, annotated papers) are still preserved in staging.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File migration/Export-LegacyFiles.ps1 `
  -OutputRoot target/migration-uploads-fast `
  -Manifest target/legacy-files-fast.tsv `
  -Errors target/legacy-file-errors-fast.tsv
$env:MIGRATION_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_migration_metadata'
$env:MIGRATION_APP_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_app_import_test2'
$env:MIGRATION_PG_USER = 'postgres'
$env:MIGRATION_PG_PASSWORD = '<PostgreSQL password>'
$env:MIGRATION_UPLOAD_ROOT = (Resolve-Path target/migration-uploads-fast).Path
$env:MIGRATION_FILE_MANIFEST = 'target/legacy-files-fast.tsv'
$env:MIGRATION_FILE_ERRORS = 'target/legacy-file-errors-fast.tsv'
$env:MIGRATION_FILE_BASE_URL = 'http://localhost:8081'
$cp = 'target/classes;' + (Get-Content target/migration-classpath.txt -Raw)
java -cp $cp com.portSrilanka.board_admin_backend.migration.LegacyFileLinker
```

For a local app test, set `APP_FILE_UPLOAD_DIR` to the absolute `target/migration-uploads-fast` path. The linker checks each file's size, SHA-256, and source paper/version relationship before updating `papers.file_path`. It records files for papers without an imported meeting in `legacy_import_issues`. It refuses the configured `board_admin_db` database.

The local rehearsal exported **4,771 readable files** and recorded **10 decryption failures** in `target/legacy-file-errors-fast.tsv`. The linker verified all 4,771 hashes, linked **3,988** files to the 4,145 imported papers, and recorded **783** exported files belonging to papers without a meeting placement. There are 157 imported papers without a linked file (including failed or absent legacy versions). The original encrypted bytes remain in the staging database for review.

The file export and the linked test database contain confidential board documents. Keep them in local, access-controlled storage. The `/api/files/content/{token}` route now checks active status, paper/token correspondence, and a subcategory grant for `legacy-papers/*`. Other application file paths continue to use their existing access behavior.

## Roles, permissions, and account reset

Run `LegacyAccessMapper` once after `LegacyCoreMapper` on the same isolated app database. It reads the old ASP.NET user roles and `Accesses` table from staging and keeps all imported users disabled.

```powershell
$env:MIGRATION_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_migration_metadata'
$env:MIGRATION_APP_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_app_import_test2'
$env:MIGRATION_PG_USER = 'postgres'
$env:MIGRATION_PG_PASSWORD = '<PostgreSQL password>'
$cp = 'target/classes;' + (Get-Content target/migration-classpath.txt -Raw)
java -cp $cp com.portSrilanka.board_admin_backend.migration.LegacyAccessMapper
Remove-Item Env:MIGRATION_PG_URL,Env:MIGRATION_APP_PG_URL,Env:MIGRATION_PG_USER,Env:MIGRATION_PG_PASSWORD
```

The isolated rehearsal mapped **87 user roles** (4 ADMIN, 9 SECRETARY, 74 MEMBER) and **50 explicit subcategory grants** (40 MEMBER, 4 SECRETARY, 6 SECRETARY_ASSISTANT), with no broken references. Five old `Support Team` accounts were given `MEMBER_VIEW_ONLY` until their broader permissions are reviewed. Only 25 users have explicit subcategory grants; the other 62 need an access decision before activation. The old ASP.NET membership table contains one record with no matching `dbo.Users` row.

All 87 imported accounts have random, unknown password hashes and remain `DEACTIVATED`. Before allowing logins, review `legacy_import_issues`, resolve the 21 missing/duplicate email occurrences that received `migration.invalid` addresses, confirm each user's role and grants, and then activate approved users through the admin user endpoint (`PUT /api/users/{id}/activate`). Each user can request a single-use reset link at `POST /api/auth/password-reset/request` and set a new password at `POST /api/auth/reset-password`. Password reset alone does not activate an account. The admin reset endpoint now generates a different random temporary password for each reset; it should not be used for a bulk migration reset.

## Step 4 rehearsal (2026-09-28)

A fresh isolated PostgreSQL database, `boardpac_cutover_rehearsal`, was built with all four import stages. It contains 87 imported users plus the app bootstrap admin, 158 meetings, 4,145 papers, 3,988 linked paper files, and 50 subcategory grants. The decrypted text export was removed after import. The existing `board_admin_db` was not changed.

The backend was started on `127.0.0.1:18081` against that rehearsal database and the exported file directory. HTTP checks passed:

| Check | Result |
| --- | --- |
| Bootstrap admin login | Success |
| Imported paper file without subcategory grant | 403 |
| Imported paper file without authentication | 403 |
| Imported paper file with temporary subcategory grant | 200; downloaded SHA-256 matched exported file |
| Temporarily activated imported member login | Success |
| Imported paper and subcategory meeting APIs | Paper ID 208 returned; 124 meetings returned |
| Imported member document download | 200; downloaded SHA-256 matched exported file |

The temporary member password/status, device, and admin grant were restored or removed. The test server was stopped. All 87 imported users remain `DEACTIVATED`; the rehearsal database still has 50 grants and no bootstrap admin grant.

**Cutover is not ready:** 939 source papers still need a meeting placement; 10 source file versions failed decryption; 157 imported papers have no linked file; 21 email occurrences need correction; 62 imported users have no explicit subcategory grant. Meeting status mapping and other dependent records such as participants, comments, and approvals also need review or conversion. Keep the live database unchanged until these items and account activation are resolved.

## Extended isolated migration (2026-09-29)

The user selected a separate legacy archive for papers without a meeting link and read-only handling for unconfirmed workflow statuses. New migration stages now import:

| Destination | Rows | Handling |
| --- | ---: | --- |
| `legacy_paper_archive` | 939 | Admin-only archive; 783 current document files available |
| `meeting_participants` | 2,073 | `PENDING`; old attendance codes recorded in `legacy_import_issues` |
| `paper_read_states` | 12,377 | Read timestamps; 538 views for unplaced papers remain in staging |
| `comments` / `comment_shares` / `meeting_notes` | 21 / 134 / 5 | Decrypted and imported |
| `legacy_archive_comments` / `legacy_approval_comments` | 4 / 23 | Read-only; 29 access rows for archived comments remain in staging |
| `legacy_paper_decisions` | 69,322 | Read-only numeric decision history |
| `legacy_document_versions` | 5,111 | Version metadata; original encrypted content remains in staging |
| `legacy_audit_events` | 189,806 | Old system and organization audit events, separate from live audit logs |
| `legacy_device_inventory` | 23 | Old devices for admin review; no new device approvals |

The frontend has an admin-only **Legacy archive** page for all 5,084 imported old papers: 4,145 placed in meetings and 939 unplaced. It shows current document downloads, comments, approval comments, and historical decision codes. It does not translate those codes into new approval actions. The archive API is under `/api/legacy-archive/papers` and requires the `ADMIN` role. Local HTTP checks returned 200 for both a meeting-linked and an unplaced document, with matching downloaded file hashes. Anonymous access and a signed-in member both received 403 for archive documents. The temporary member account was restored to `DEACTIVATED` and its test device removed. The frontend production build and backend test suite passed.

The admin-only **Legacy audit** page shows paginated old system and organization events. It reads `/api/legacy-archive/audit-events`; a local HTTP check returned 100 records on the first page for an admin and 403 for anonymous access. The old events remain separate from the new app's `audit_logs` table.

The admin-only **Legacy devices** page lists the 23 old device records without granting them access to the new app. Its API returned all 23 records for an admin and 403 for anonymous access.

Key source table counts were compared again on 2026-09-29: users 87, meetings 158, papers 5,084, document versions 5,111, file structures 4,805, comments 25, system audit events 150,003, and organization audit events 39,803. These match the staging counts. Matching counts do not prove that rows were not edited, so a final source freeze and fresh staging comparison are still needed at cutover.

To rebuild an isolated database from the existing lossless staging copy and file export, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File migration/Run-IsolatedMigration.ps1 -TargetDatabase boardpac_full_rehearsal_2
```

The script refuses `board_admin_db`, requires a fresh destination, runs the full mapper sequence, verifies the exported file manifest, and removes temporary decrypted text exports. A fresh run completed successfully in `boardpac_full_rehearsal`. For a local backend test against it, set `DB_URL=jdbc:postgresql://localhost:5432/boardpac_full_rehearsal` and `APP_FILE_UPLOAD_DIR` to the absolute `target/migration-uploads-fast` directory, then start the backend on a loopback port. The live app database has not been changed.

For local review with the frontend's default API URL, build the backend and run it on loopback port 8081, then start the frontend development server in `../board-admin-frontend/frontend_web`:

```powershell
$env:DB_URL = 'jdbc:postgresql://localhost:5432/boardpac_full_rehearsal'
$env:APP_FILE_UPLOAD_DIR = (Resolve-Path target/migration-uploads-fast).Path
mvn -q -DskipTests package
java -jar target/board-admin-backend-0.0.1-SNAPSHOT.jar --server.address=127.0.0.1 --server.port=8081
```

Use a separate terminal for `npm run dev` in the frontend directory. The isolated database includes a bootstrap admin account created by the existing app initializer; secure or replace its default password before any network exposure. All imported accounts remain disabled. After review, stop the backend and remove the temporary environment variables from that terminal.

**Still required before live use:** Resolve the 10 failed document decryptions and 157 meeting-linked papers without a file (149 have no matching current `FileStructures` row in the source; 8 have a decryption failure); review 939 archive papers for meeting placement if they should appear in regular meetings; map or approve meeting, attendance, and decision statuses; review the 21 email conflicts and 62 users without grants; plan password resets and account activation. Older document binaries, product settings, old PIN/password material, and other legacy-only records remain fully preserved in the staging database but are not usable in the new app's normal screens. Do not switch the live database until those decisions and a cutover plan are complete.

## Document gap decision

On 2026-09-29, a full SQL Server backup from 2026-09-22 at `D:\Backup\20260922.bak` was restored into the separate `BoardPAC_recovery_20260922` database for comparison. It contains **none of the 303 missing current file rows** across all 5,084 papers, including the 149 meeting-linked papers. All 10 file rows that failed decryption are present in that backup, but their encrypted bytes are identical to the current database. Two older backup files found under `C:\Users\Administrator\Desktop\Boardpac\BoardpacDB` are dated 2021 and cannot cover later papers. The 149 missing meeting-linked records also have no stored `DocVersions.FilePath` or previous version reference in the current database.

Document recovery may be deferred if the business accepts that **313 papers will have no download** (303 with no current file row and 10 whose file cannot be decrypted). The admin paper archive now displays **Document unavailable** when `has_file` is false and retains the paper title, reference, meeting placement, comments, and history. This decision does not recover the files or make the other cutover items complete. The separate recovery database and original backup are retained for further investigation.

## Step 2: account review

`LegacyAccountReviewExporter` reads the staged source users and an isolated app rehearsal database. It writes `target/legacy-account-review.csv` with each imported user's original and imported email, role, access profile, explicit subcategory grants, and review columns. It changes no database records and refuses `board_admin_db`. The exporter will not overwrite an existing review file.

```powershell
mvn -q -DskipTests compile
$env:MIGRATION_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_migration_metadata'
$env:MIGRATION_APP_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_full_rehearsal'
$env:MIGRATION_PG_USER = 'postgres'
$env:MIGRATION_PG_PASSWORD = '<PostgreSQL password>'
$cp = 'target/classes;' + (Get-Content target/migration-classpath.txt -Raw)
java -cp $cp com.portSrilanka.board_admin_backend.migration.LegacyAccountReviewExporter
Remove-Item Env:MIGRATION_PG_URL,Env:MIGRATION_APP_PG_URL,Env:MIGRATION_PG_USER,Env:MIGRATION_PG_PASSWORD
```

The review generated on 2026-09-29 lists **87 disabled accounts**, **21 duplicate board email occurrences**, and **62 users without explicit subcategory grants**. All 21 conflicting users have a board email in the old source; no office email or ASP.NET membership email provides a unique unused replacement automatically. For each flagged account, enter a verified unique address in `approved_unique_email`, list only approved subcategory IDs and scoped roles in `approved_grants`, and set `approved_for_activation` to `YES` only after the role, grants, and reset path have been approved. `current_grants` uses `subcategory_id:role` entries separated by semicolons. An empty `approved_grants` should mean the reviewer intentionally approved no new grants, and this should be explained in `review_notes`.

This CSV is a review document, not an automatic account update. Keep it access controlled because it contains names and email addresses. Imported passwords remain unknown random hashes; approved users need password reset links after their addresses are corrected and accounts are activated. Do not bulk activate accounts or grant every subcategory by default.

## Step 3: workflow status review

`LegacyStatusReviewExporter` creates `target/legacy-status-review.csv` from the staged SQL Server data and isolated app rehearsal. It counts each old meeting status, paper status, attendance flag pair, and paper decision/notification/permission code. The blank approval columns let a business owner record the old meaning and any approved new status. It makes no database changes and will not overwrite an existing review file.

```powershell
mvn -q -DskipTests compile
$env:MIGRATION_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_migration_metadata'
$env:MIGRATION_APP_PG_URL = 'jdbc:postgresql://localhost:5432/boardpac_full_rehearsal'
$env:MIGRATION_PG_USER = 'postgres'
$env:MIGRATION_PG_PASSWORD = '<PostgreSQL password>'
$cp = 'target/classes;' + (Get-Content target/migration-classpath.txt -Raw)
java -cp $cp com.portSrilanka.board_admin_backend.migration.LegacyStatusReviewExporter
Remove-Item Env:MIGRATION_PG_URL,Env:MIGRATION_APP_PG_URL,Env:MIGRATION_PG_USER,Env:MIGRATION_PG_PASSWORD
```

The 2026-09-29 report has 24 code groups. Meeting codes 0–5 total 158 rows; paper codes 0, 4, 5, 6 total 5,084; attendance pairs `4/0` and `4/1` total 2,073; each decision column totals 69,322. These are numeric distributions, not confirmed meanings. The app still holds imported meetings in `DRAFT`, participants in `PENDING`, and old decisions as read-only history. In particular, do not infer that old `IsPresent=4` means the new app's `ACCEPTED` or that numeric paper decisions match the new approval enum. Review the code definitions in the old backend and confirm with the business owner before translating any workflow states.

## Step 4: cutover readiness check

Run the read-only check against the isolated rehearsal database:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File migration/Check-CutoverReadiness.ps1
```

It writes `target/cutover-readiness.md` and refuses the live `board_admin_db`. The report must have a new filename for each rerun because the script does not overwrite prior evidence (`-Report target/cutover-readiness-2.md`). The 2026-09-29 check matched the expected imported totals: 87 disabled users, 158 meetings, 5,084 papers across the app and archive, 2,073 participants, and 69,322 historical decisions. It also recorded 21 placeholder emails, 62 users without explicit grants, 313 unavailable paper files, and 10 file export errors. Neither review CSV has approved entries yet.

This is a rehearsal check, not permission to change the live database. Before cutover, complete the account and workflow review files, record acceptance of unavailable documents, freeze the old source, refresh staging and file exports, repeat the isolated import, verify representative records and file hashes, and prepare live backup and rollback steps. The report currently says **NOT APPROVED FOR LIVE CUTOVER**.

## Rehearsal account activation (2026-09-29)

At the user's request, `migration/Activate-ImportedAccounts.ps1` activated all **87 imported users** in the isolated `boardpac_full_rehearsal` database. A query verified 87 active imported users, zero disabled imported users, and one separate bootstrap account. The live `board_admin_db` was not changed. The script requires exactly 87 disabled imported users, updates only users in `legacy_import_map`, and refuses the live database.

Activation alone does not let users sign in: imported accounts have random unknown passwords. The 21 accounts with `migration.invalid` placeholder emails need verified unique addresses before email-based password reset can reach them. The 62 accounts without explicit subcategory grants will have limited content access until their permissions are reviewed. Four imported users have the `ADMIN` role, so do not expose the rehearsal server to an untrusted network or bulk issue passwords before their privileges are checked. The account review CSV still has no approved entries, and live cutover remains pending.

To refresh the readiness report after this activation without replacing the earlier evidence:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File migration/Check-CutoverReadiness.ps1 -Report target/cutover-readiness-after-activation.md
```

## Test from another PC on the same network

The backend PC's static Ethernet address is `10.105.4.183`. The frontend API client uses `VITE_API_BASE_URL` when set; otherwise it calls port 8081 on the hostname from which the frontend page was opened. If the frontend is served from this backend PC, the other PC can open `http://10.105.4.183:5173/` and the API client will call `http://10.105.4.183:8081/api`. If the frontend runs on a different PC, set `VITE_API_BASE_URL=http://10.105.4.183:8081/api` in that frontend's environment before starting Vite.

On the backend PC, start a LAN test with the rehearsal database (PowerShell):

```powershell
$env:DB_URL = 'jdbc:postgresql://localhost:5432/boardpac_full_rehearsal'
$env:APP_FILE_UPLOAD_DIR = (Resolve-Path target/migration-uploads-fast).Path
$env:SERVER_ADDRESS = '10.105.4.183'
$env:APP_CORS_ALLOWED_ORIGIN_PATTERNS = 'http://localhost:*,http://127.0.0.1:*,http://10.105.4.183:5173'
mvn -q -DskipTests package
java -jar target/board-admin-backend-0.0.1-SNAPSHOT.jar
```

In a second terminal on the same PC, start the frontend from `../board-admin-frontend/frontend_web` with `npm run dev -- --host 10.105.4.183`. For a frontend hosted on a different PC, add that PC's exact frontend origin (scheme, IP, and port) to `APP_CORS_ALLOWED_ORIGIN_PATTERNS`; restart the backend after changing it. Restart Vite after changing `VITE_API_BASE_URL`. Permit inbound TCP ports 8081 and 5173 on the backend PC's Windows firewall for the trusted local network if connections fail. Set `PASSWORD_RESET_FRONTEND_URL` to the reachable frontend address if testing email reset links.

The rehearsal contains confidential board data. On 2026-09-29 the bootstrap admin's development password was replaced with a random password before LAN access. The credential is in the local, ignored `target/lan-bootstrap-admin.txt` file with access restricted to the Windows Administrator account. Keep this file private and delete it after testing. Do not use this LAN test as live cutover.

For the public test endpoint `https://apds.slpa.lk`, see [`migration/public-test/README.md`](public-test/README.md) and its Caddyfile. Caddy is running with a public certificate and forwards HTTPS to the isolated rehearsal backend at `10.105.4.183:8081`. The live database remains unchanged.
