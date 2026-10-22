param(
    [string]$StateRoot = 'C:\BoardPAC-AutoDeploy',
    [string]$Branch = 'main',
    [switch]$Initialize
)

$ErrorActionPreference = 'Stop'
$repositoryUrl = 'https://github.com/didulawickramarachchi-art/BoardPAC-.git'
$serverBackend = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$repositoryRoot = (Resolve-Path (Join-Path $serverBackend '..')).Path
$webRoot = Join-Path $repositoryRoot 'board-admin-frontend\frontend_web\dist'
$source = Join-Path $StateRoot 'source'
$stateFile = Join-Path $StateRoot 'state.json'
$releaseRoot = Join-Path $StateRoot 'releases'
$logRoot = Join-Path $StateRoot 'logs'
$lockFile = Join-Path $StateRoot 'deployment.lock'
$healthUrl = 'http://10.105.4.183:8081/api/auth/login'
$backendServiceName = 'BoardPACBackend'
$serviceJar = Join-Path $StateRoot 'active\backend.jar'

function Run([string]$program, [string[]]$arguments) {
    & $program @arguments
    if ($LASTEXITCODE -ne 0) { throw "$program failed with exit code $LASTEXITCODE" }
}

function Wait-ForBackend {
    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [TimeSpan]::FromSeconds(3)
    try {
        for ($attempt = 0; $attempt -lt 45; $attempt++) {
            try {
                $response = $client.GetAsync($healthUrl).GetAwaiter().GetResult()
                if ([int]$response.StatusCode -lt 500) { return $true }
            } catch { }
            Start-Sleep -Seconds 2
        }
        return $false
    } finally { $client.Dispose() }
}

function Stop-Backend {
    $listeners = @(Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue)
    foreach ($listener in $listeners) {
        $process = Get-CimInstance Win32_Process -Filter "ProcessId = $($listener.OwningProcess)"
        if (-not $process -or $process.Name -notin @('java.exe', 'javaw.exe') -or
            $process.CommandLine -notmatch 'board-admin-backend|backend\.jar') {
            throw "Port 8081 is owned by an unexpected process (PID $($listener.OwningProcess))."
        }
        Stop-Process -Id $listener.OwningProcess -Force
        $deadline = (Get-Date).AddSeconds(20)
        while ((Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
            Start-Sleep -Milliseconds 250
        }
        if (Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue) {
            throw "Backend PID $($listener.OwningProcess) did not stop."
        }
    }
}

function Start-Backend([string]$jarPath) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    Start-Process -FilePath 'java.exe' -ArgumentList @('-jar', ('"' + $jarPath + '"')) `
        -WorkingDirectory $serverBackend -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $logRoot "backend-$stamp.out.log") `
        -RedirectStandardError (Join-Path $logRoot "backend-$stamp.err.log") | Out-Null
}

function Switch-ServiceJar([string]$newJar, [string]$rollbackJar) {
    $service = Get-Service -Name $backendServiceName -ErrorAction Stop
    if ($service.Status -ne 'Stopped') {
        Stop-Service -Name $backendServiceName -ErrorAction Stop
        $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(60))
    }
    $deadline = (Get-Date).AddSeconds(30)
    while ((Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
    }
    if (Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue) {
        throw 'Port 8081 remained in use after stopping the backend service.'
    }
    try {
        Copy-Item -LiteralPath $newJar -Destination $serviceJar -Force
        Start-Service -Name $backendServiceName -ErrorAction Stop
        if (-not (Wait-ForBackend)) { throw 'New backend failed its HTTP check.' }
    } catch {
        $deploymentError = $_
        $service = Get-Service -Name $backendServiceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -ne 'Stopped') {
            Stop-Service -Name $backendServiceName -ErrorAction SilentlyContinue
            $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(60))
        }
        if (Test-Path -LiteralPath $rollbackJar) {
            Copy-Item -LiteralPath $rollbackJar -Destination $serviceJar -Force
            Start-Service -Name $backendServiceName -ErrorAction Stop
        }
        throw "Backend deployment failed and previous JAR was restored: $deploymentError"
    }
}

New-Item -ItemType Directory -Path $StateRoot, $releaseRoot, $logRoot -Force | Out-Null
$transcript = Join-Path $logRoot 'deploy.log'
Start-Transcript -LiteralPath $transcript -Append | Out-Null
$lock = $null
try {
    try {
        $lock = [System.IO.File]::Open($lockFile, 'OpenOrCreate', 'ReadWrite', 'None')
    } catch [System.IO.IOException] {
        Write-Output 'Another deployment check is running.'
        exit 0
    }

    if (-not (Test-Path -LiteralPath (Join-Path $source '.git'))) {
        Run 'git.exe' @('clone', '--no-checkout', '--filter=blob:none', $repositoryUrl, $source)
    }
    Run 'git.exe' @('-C', $source, 'fetch', '--depth=1', 'origin', $Branch)
    $commit = (& git.exe -C $source rev-parse FETCH_HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $commit -notmatch '^[0-9a-f]{40}$') { throw 'Could not identify the remote commit.' }

    if ($Initialize) {
        if (Test-Path -LiteralPath $stateFile) { throw 'Deployment is already initialized.' }
        @{ lastCommit = $commit; activeJar = $null } | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding UTF8
        Write-Output "Initialized at $commit. Future pushes to $Branch will deploy."
        exit 0
    }
    if (-not (Test-Path -LiteralPath $stateFile)) { throw 'Run once with -Initialize before enabling the task.' }
    $state = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
    if ($state.lastCommit -eq $commit) { Write-Output 'No new push.'; exit 0 }

    Run 'git.exe' @('-C', $source, 'checkout', '--force', '--detach', $commit)
    $backendSource = Join-Path $source 'board-admin-backend'
    $webSource = Join-Path $source 'board-admin-frontend\frontend_web'
    Push-Location $backendSource
    try { Run 'mvn.cmd' @('-B', 'test', 'package') } finally { Pop-Location }
    Push-Location $webSource
    try {
        $previousApiBase = $env:VITE_API_BASE_URL
        try {
            $env:VITE_API_BASE_URL = 'https://apds.slpa.lk/api'
            Run 'npm.cmd' @('ci')
            Run 'npm.cmd' @('run', 'build')
        } finally {
            if ($null -eq $previousApiBase) { Remove-Item Env:VITE_API_BASE_URL -ErrorAction SilentlyContinue }
            else { $env:VITE_API_BASE_URL = $previousApiBase }
        }
    } finally { Pop-Location }

    $release = Join-Path $releaseRoot $commit
    New-Item -ItemType Directory -Path $release -Force | Out-Null
    $jar = Join-Path $release 'backend.jar'
    Copy-Item -LiteralPath (Join-Path $backendSource 'target\board-admin-backend-0.0.1-SNAPSHOT.jar') -Destination $jar -Force
    $oldJar = $state.activeJar
    if (-not $oldJar) {
        $currentJar = Join-Path $serverBackend 'target\board-admin-backend-0.0.1-SNAPSHOT.jar'
        if (Test-Path -LiteralPath $currentJar) {
            $oldJar = Join-Path $releaseRoot 'pre-automation-backend.jar'
            Copy-Item -LiteralPath $currentJar -Destination $oldJar -Force
        }
    }

    if (Get-Service -Name $backendServiceName -ErrorAction SilentlyContinue) {
        $rollbackJar = Join-Path $releaseRoot "rollback-$commit.jar"
        Copy-Item -LiteralPath $serviceJar -Destination $rollbackJar -Force
        Switch-ServiceJar $jar $rollbackJar
    } else {
        Stop-Backend
        Start-Backend $jar
        if (-not (Wait-ForBackend)) {
            Stop-Backend
            if ($oldJar -and (Test-Path -LiteralPath $oldJar)) { Start-Backend $oldJar }
            throw 'New backend failed its HTTP check; previous JAR was restarted.'
        }
    }

    # Copy assets first and index.html last so browsers do not request missing hashed assets.
    $builtWeb = Join-Path $webSource 'dist'
    New-Item -ItemType Directory -Path $webRoot -Force | Out-Null
    Get-ChildItem -LiteralPath $builtWeb -Force | Where-Object Name -NE 'index.html' | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $webRoot -Recurse -Force
    }
    Copy-Item -LiteralPath (Join-Path $builtWeb 'index.html') -Destination (Join-Path $webRoot 'index.html') -Force
    @{ lastCommit = $commit; activeJar = $jar } | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding UTF8
    Write-Output "Deployed $commit"
} finally {
    if ($lock) { $lock.Dispose() }
    Stop-Transcript | Out-Null
}
