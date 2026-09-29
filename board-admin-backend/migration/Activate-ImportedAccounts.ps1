param([string]$Database = 'boardpac_full_rehearsal')

$ErrorActionPreference = 'Stop'
if ($Database -notmatch '^[a-z][a-z0-9_]*$' -or $Database -eq 'board_admin_db') {
    throw 'Only an isolated rehearsal database is allowed.'
}
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $root
try {
    $password = $env:DB_PASSWORD
    if (-not $password) {
        $line = Get-Content -LiteralPath '.env' | Where-Object { $_ -match '^DB_PASSWORD=' } | Select-Object -First 1
        if (-not $line) { throw 'DB_PASSWORD is required.' }
        $password = ($line -split '=', 2)[1]
    }
    $env:PGPASSWORD = $password
    $psql = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
    if (-not (Test-Path -LiteralPath $psql)) { throw 'PostgreSQL psql.exe was not found.' }
    $sql = @'
BEGIN;
DO $$
DECLARE imported_count integer; disabled_count integer;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE u.status='DEACTIVATED')
    INTO imported_count, disabled_count
    FROM users u JOIN legacy_import_map m ON m.entity='users' AND m.app_id=u.id;
  IF imported_count <> 87 OR disabled_count <> 87 THEN
    RAISE EXCEPTION 'Expected exactly 87 disabled imported users; found % imported, % disabled', imported_count, disabled_count;
  END IF;
END $$;
UPDATE users SET status='ACTIVE', updated_at=now()
WHERE id IN (SELECT app_id FROM legacy_import_map WHERE entity='users') AND status='DEACTIVATED';
DO $$
BEGIN
  IF (SELECT count(*) FROM users u JOIN legacy_import_map m ON m.entity='users' AND m.app_id=u.id WHERE u.status='ACTIVE') <> 87 THEN
    RAISE EXCEPTION 'Imported user activation verification failed';
  END IF;
END $$;
COMMIT;
SELECT count(*) AS active_imported_users FROM users u JOIN legacy_import_map m ON m.entity='users' AND m.app_id=u.id WHERE u.status='ACTIVE';
'@
    $result = $sql | & $psql -X -q -t -A -v ON_ERROR_STOP=1 -h localhost -U postgres -d $Database
    if ($LASTEXITCODE -ne 0) { throw 'Imported account activation failed; transaction was rolled back.' }
    if (($result | Select-Object -Last 1) -ne '87') { throw 'Unexpected active imported account count.' }
    Write-Output "Activated 87 imported accounts in isolated database $Database. Password resets are still required."
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    Pop-Location
}
