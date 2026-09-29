param(
    [string]$TargetDatabase = 'boardpac_full_rehearsal',
    [string]$StagingDatabase = 'boardpac_migration_metadata',
    [string]$FileBaseUrl = 'http://localhost:8081'
)

$ErrorActionPreference = 'Stop'
if ($TargetDatabase -notmatch '^[a-z][a-z0-9_]*$' -or
    $StagingDatabase -notmatch '^[a-z][a-z0-9_]*$' -or
    $TargetDatabase -eq $StagingDatabase -or
    $TargetDatabase -eq 'board_admin_db' -or
    $StagingDatabase -eq 'board_admin_db') {
    throw 'Use distinct, isolated database names. The live app database is not allowed.'
}
if ($FileBaseUrl -notmatch '^https?://') { throw 'FileBaseUrl must start with HTTP(S).' }

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $root
$password = $env:DB_PASSWORD
if (-not $password) {
    $line = Get-Content -LiteralPath '.env' | Where-Object { $_ -match '^DB_PASSWORD=' } | Select-Object -First 1
    if (-not $line) { throw 'DB_PASSWORD is required in the environment or .env.' }
    $password = ($line -split '=', 2)[1]
}
$createdText = $false
$createdActivity = $false
try {
    foreach ($file in @('target/legacy-files-fast.tsv', 'target/legacy-file-errors-fast.tsv', 'target/migration-uploads-fast')) {
        if (-not (Test-Path -LiteralPath $file)) { throw "Required file export is missing: $file" }
    }
    foreach ($file in @('target/legacy-decrypted-text.tsv', 'target/legacy-activity-text.tsv', 'target/legacy-activity-text-errors.tsv')) {
        if (Test-Path -LiteralPath $file) { throw "Remove or move the existing sensitive export before running: $file" }
    }
    mvn -q -DskipTests compile dependency:build-classpath '-Dmdep.outputFile=target/migration-classpath.txt'
    if ($LASTEXITCODE -ne 0) { throw 'Maven compile failed.' }
    $env:PGPASSWORD = $password
    $createdb = 'C:\Program Files\PostgreSQL\18\bin\createdb.exe'
    & $createdb -h localhost -U postgres $TargetDatabase
    if ($LASTEXITCODE -ne 0) { throw 'Could not create the isolated database; it may already exist.' }

    $createdText = $true
    powershell -NoProfile -ExecutionPolicy Bypass -File migration/Export-LegacyText.ps1
    if ($LASTEXITCODE -ne 0) { throw 'Legacy text export failed.' }
    $createdActivity = $true
    powershell -NoProfile -ExecutionPolicy Bypass -File migration/Export-LegacyActivityText.ps1
    if ($LASTEXITCODE -ne 0) { throw 'Legacy activity text export failed.' }
    if ((Get-Item 'target/legacy-activity-text-errors.tsv').Length -ne 0) {
        throw 'Some activity text could not be decrypted; inspect the error manifest.'
    }

    $env:MIGRATION_PG_URL = "jdbc:postgresql://localhost:5432/$StagingDatabase"
    $env:MIGRATION_APP_PG_URL = "jdbc:postgresql://localhost:5432/$TargetDatabase"
    $env:MIGRATION_PG_USER = 'postgres'
    $env:MIGRATION_PG_PASSWORD = $password
    $env:MIGRATION_DECRYPTED_TEXT = 'target/legacy-decrypted-text.tsv'
    $env:MIGRATION_ACTIVITY_TEXT = 'target/legacy-activity-text.tsv'
    $env:MIGRATION_UPLOAD_ROOT = (Resolve-Path 'target/migration-uploads-fast').Path
    $env:MIGRATION_FILE_MANIFEST = 'target/legacy-files-fast.tsv'
    $env:MIGRATION_FILE_ERRORS = 'target/legacy-file-errors-fast.tsv'
    $env:MIGRATION_FILE_BASE_URL = $FileBaseUrl
    $classpath = 'target/classes;' + (Get-Content 'target/migration-classpath.txt' -Raw)
    foreach ($name in @('LegacyCoreMapper', 'LegacyAgendaMapper', 'LegacyAccessMapper', 'LegacyFileLinker',
            'LegacyActivityMapper', 'LegacyArchiveMapper', 'LegacyCommentMapper', 'LegacyDecisionMapper',
            'LegacyVersionMapper', 'LegacyAuditMapper', 'LegacyDeviceMapper')) {
        Write-Output "Running $name"
        java -cp $classpath "com.portSrilanka.board_admin_backend.migration.$name"
        if ($LASTEXITCODE -ne 0) { throw "$name failed; inspect the isolated database." }
    }
    Write-Output "Isolated migration complete: $TargetDatabase"
} finally {
    Remove-Item Env:PGPASSWORD,Env:MIGRATION_PG_URL,Env:MIGRATION_APP_PG_URL,Env:MIGRATION_PG_USER,Env:MIGRATION_PG_PASSWORD,Env:MIGRATION_DECRYPTED_TEXT,Env:MIGRATION_ACTIVITY_TEXT,Env:MIGRATION_UPLOAD_ROOT,Env:MIGRATION_FILE_MANIFEST,Env:MIGRATION_FILE_ERRORS,Env:MIGRATION_FILE_BASE_URL -ErrorAction SilentlyContinue
    if ($createdText) { Remove-Item -LiteralPath 'target/legacy-decrypted-text.tsv' -ErrorAction SilentlyContinue }
    if ($createdActivity) { Remove-Item -LiteralPath 'target/legacy-activity-text.tsv','target/legacy-activity-text-errors.tsv' -ErrorAction SilentlyContinue }
    Pop-Location
}
