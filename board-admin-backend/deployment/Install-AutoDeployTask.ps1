param([string]$StateRoot = 'C:\BoardPAC-AutoDeploy')

$ErrorActionPreference = 'Stop'
$script = (Resolve-Path (Join-Path $PSScriptRoot 'Invoke-AutoDeploy.ps1')).Path
$powershell = (Get-Command powershell.exe).Source
$taskName = 'BoardPAC Auto Deploy'

# Record the currently deployed state before scheduling any updates. This keeps
# uncommitted local work and the currently running JAR untouched on installation.
& $script -StateRoot $StateRoot -Initialize
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'Initialization failed.' }

$quotedScript = '"' + $script + '"'
$quotedState = '"' + $StateRoot + '"'
$action = New-ScheduledTaskAction -Execute $powershell -Argument "-NoProfile -ExecutionPolicy Bypass -File $quotedScript -StateRoot $quotedState"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 2) -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description 'Build and deploy new BoardPAC main commits every five minutes while this user is signed in.' -Force | Out-Null
Write-Output "Installed '$taskName'. It checks for pushes to main every five minutes while this Windows user is signed in."
