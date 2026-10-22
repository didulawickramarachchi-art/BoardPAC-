param(
    [int]$IntervalSeconds = 15,
    [int]$StartupGraceSeconds = 15,
    [int]$ConsecutiveChecks = 2,
    [switch]$Once
)

$ErrorActionPreference = 'Stop'
$maintenanceFlag = 'C:\BoardPAC-AutoDeploy\backend-maintenance.flag'
$services = @('BoardPACBackend', 'BoardPACCaddy')
$stoppedChecks = @{}
foreach ($name in $services) { $stoppedChecks[$name] = 0 }

if ($IntervalSeconds -lt 5 -or $ConsecutiveChecks -lt 1 -or $StartupGraceSeconds -lt 0) {
    throw 'Invalid watchdog timing settings.'
}

if (-not $Once -and $StartupGraceSeconds -gt 0) {
    Start-Sleep -Seconds $StartupGraceSeconds
}
Write-Output "$(Get-Date -Format o) BoardPAC watchdog started."

while ($true) {
    foreach ($name in $services) {
        try {
            if ($name -eq 'BoardPACBackend' -and (Test-Path -LiteralPath $maintenanceFlag)) {
                $age = (Get-Date).ToUniversalTime() - (Get-Item -LiteralPath $maintenanceFlag).LastWriteTimeUtc
                if ($age.TotalMinutes -lt 10) {
                    $stoppedChecks[$name] = 0
                    continue
                }
                Write-Output "$(Get-Date -Format o) Backend maintenance marker is stale; checking service."
            }

            $service = Get-Service -Name $name -ErrorAction Stop
            if ($service.Status -eq 'Running') {
                $stoppedChecks[$name] = 0
                continue
            }
            if ($service.Status -ne 'Stopped') {
                $stoppedChecks[$name] = 0
                continue
            }

            $stoppedChecks[$name]++
            if ($stoppedChecks[$name] -lt $ConsecutiveChecks) { continue }
            Write-Output "$(Get-Date -Format o) $name is stopped; attempting restart."
            Start-Service -Name $name -ErrorAction Stop
            $stoppedChecks[$name] = 0
            Write-Output "$(Get-Date -Format o) Start command sent to $name."
        } catch {
            Write-Output "$(Get-Date -Format o) $name check failed: $($_.Exception.Message)"
        }
    }
    if ($Once) { break }
    Start-Sleep -Seconds $IntervalSeconds
}
