param(
    [string]$Database = 'boardpac_full_rehearsal',
    [string]$Report = 'target/cutover-readiness.md'
)

$ErrorActionPreference = 'Stop'
if ($Database -notmatch '^[a-z][a-z0-9_]*$' -or $Database -eq 'board_admin_db') {
    throw 'Only an isolated rehearsal database is allowed.'
}
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $root
try {
    if (Test-Path -LiteralPath $Report) { throw "Report already exists: $Report" }
    $password = $env:DB_PASSWORD
    if (-not $password) {
        $line = Get-Content -LiteralPath '.env' | Where-Object { $_ -match '^DB_PASSWORD=' } | Select-Object -First 1
        if (-not $line) { throw 'DB_PASSWORD is required.' }
        $password = ($line -split '=', 2)[1]
    }
    $env:PGPASSWORD = $password
    $psql = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
    if (-not (Test-Path -LiteralPath $psql)) { throw 'PostgreSQL psql.exe was not found.' }
    function Count([string]$sql) {
        $result = $sql | & $psql -X -q -t -A -v ON_ERROR_STOP=1 -h localhost -U postgres -d $Database
        if ($LASTEXITCODE -ne 0) { throw "Database count query failed: $sql" }
        return [long]($result | Select-Object -First 1)
    }
    $users = Count "SELECT count(*) FROM legacy_import_map WHERE entity='users'"
    $disabled = Count "SELECT count(*) FROM users u JOIN legacy_import_map m ON m.entity='users' AND m.app_id=u.id WHERE u.status='DEACTIVATED'"
    $active = Count "SELECT count(*) FROM users u JOIN legacy_import_map m ON m.entity='users' AND m.app_id=u.id WHERE u.status='ACTIVE'"
    $placeholders = Count "SELECT count(*) FROM users u JOIN legacy_import_map m ON m.entity='users' AND m.app_id=u.id WHERE u.board_email LIKE '%@migration.invalid'"
    $noGrants = Count "SELECT count(*) FROM users u JOIN legacy_import_map m ON m.entity='users' AND m.app_id=u.id WHERE NOT EXISTS (SELECT 1 FROM user_subcategory_access a WHERE a.user_id=u.id)"
    $meetings = Count 'SELECT count(*) FROM meetings'
    $papers = Count 'SELECT count(*) FROM papers'
    $archive = Count 'SELECT count(*) FROM legacy_paper_archive'
    $unavailable = Count 'SELECT count(*) FROM papers WHERE file_path IS NULL OR file_path='''' '
    $archiveUnavailable = Count 'SELECT count(*) FROM legacy_paper_archive WHERE file_relative_path IS NULL OR file_relative_path='''' '
    $participants = Count 'SELECT count(*) FROM meeting_participants'
    $decisions = Count 'SELECT count(*) FROM legacy_paper_decisions'
    $issues = Count 'SELECT count(*) FROM legacy_import_issues'
    $accountFile = 'target/legacy-account-review.csv'
    $statusFile = 'target/legacy-status-review.csv'
    $accountReview = if (Test-Path -LiteralPath $accountFile) { @(Import-Csv -LiteralPath $accountFile) } else { @() }
    $statusReview = if (Test-Path -LiteralPath $statusFile) { @(Import-Csv -LiteralPath $statusFile) } else { @() }
    $approvedAccounts = @($accountReview | Where-Object { $_.approved_for_activation -eq 'YES' }).Count
    $approvedStatuses = @($statusReview | Where-Object { -not [string]::IsNullOrWhiteSpace($_.approved_meaning) }).Count
    $errors = if (Test-Path -LiteralPath 'target/legacy-file-errors-fast.tsv') {
        @(Get-Content -LiteralPath 'target/legacy-file-errors-fast.tsv' | Select-Object -Skip 1 | Where-Object { $_ -and $_ -notmatch '^\s*#' }).Count
    } else { -1 }
    $consistent = $users -eq 87 -and $meetings -eq 158 -and ($papers + $archive) -eq 5084 -and
                  $participants -eq 2073 -and $decisions -eq 69322 -and ($unavailable + $archiveUnavailable) -eq 313
    $reportText = @"
# Isolated cutover readiness check

Database: ``$Database``. Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'). Read-only checks only.

| Check | Result |
| --- | ---: |
| Imported users | $users |
| Imported users still disabled | $disabled |
| Imported users active | $active |
| Placeholder emails | $placeholders |
| Users without explicit subcategory grants | $noGrants |
| Meetings | $meetings |
| Linked papers | $papers |
| Archived papers | $archive |
| Papers without a downloadable file | $($unavailable + $archiveUnavailable) |
| Participants | $participants |
| Historical decisions | $decisions |
| Import audit issues | $issues |
| File export error lines | $errors |
| Accounts marked approved in review CSV | $approvedAccounts / $($accountReview.Count) |
| Workflow code groups with approved meaning | $approvedStatuses / $($statusReview.Count) |
| Expected rehearsal totals match | $consistent |

## Remaining decisions

- Verify unique email addresses and exact grants in ``$accountFile``. Any active rehearsal account still needs a usable password reset path and approved access before live cutover.
- Confirm the old workflow code meanings in ``$statusFile``. Imported meetings stay DRAFT; attendance stays PENDING; decisions stay read-only.
- Accept the **313 unavailable documents** in writing or recover them. The 10 failed decryptions are included in this total.
- Confirm whether the 939 archived papers should stay in the separate legacy archive.
- Freeze the source, refresh staging and file export, repeat an isolated import, and compare the final source records before a live switch.
- Back up the live app database and uploaded files, then schedule a reviewed cutover and rollback plan.

Readiness: **NOT APPROVED FOR LIVE CUTOVER**. This report does not approve any business decision or change production data.
"@
    $path = [System.IO.Path]::GetFullPath((Join-Path $root $Report))
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($path)) | Out-Null
    [System.IO.File]::WriteAllText($path, $reportText, [System.Text.UTF8Encoding]::new($false))
    Write-Output "Readiness report written: $path; expected totals match: $consistent"
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    Pop-Location
}
