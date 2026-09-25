$ErrorActionPreference = 'Stop'

$projectDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$jar = Join-Path $projectDir 'target\board-admin-backend-0.0.1-SNAPSHOT.jar'
$logDir = Join-Path $projectDir 'logs'

if (-not (Test-Path -LiteralPath $jar)) {
    throw "Backend JAR not found: $jar. Run mvn.cmd -DskipTests package first."
}

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Set-Location -LiteralPath $projectDir

& java -jar $jar *>> (Join-Path $logDir 'backend.log')
exit $LASTEXITCODE
