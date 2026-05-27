# Install-CatFacts.ps1
#
# Installs CatFacts.ps1 and registers a Scheduled Task that runs it every
# 30 minutes, weekdays 9 AM - 5 PM, under the current user (no admin needed).
#
# Source-selection logic:
#   * If this installer is sitting next to a CatFacts.ps1 (i.e. you ran it
#     from inside the cloned repo), it uses that file in-place. No copy.
#   * Otherwise it downloads the latest CatFacts.ps1 from GitHub into
#     %LOCALAPPDATA%\OfficePranks\.
#
# Idempotent: re-running replaces the scheduled task. Fires the task once
# at the end (with -Force) so you can verify it works.
#
# Usage:
#   .\Install-CatFacts.ps1
#   .\Install-CatFacts.ps1 -StartTime 08:00 -EndTime 18:00 -IntervalMinutes 15
#   .\Install-CatFacts.ps1 -SourceUrl https://raw.githubusercontent.com/<you>/OfficePranks/main/CatFacts.ps1

[CmdletBinding()]
param(
    [string]$TaskName        = 'OfficePranks-CatFacts',
    [string]$SourceUrl       = 'https://raw.githubusercontent.com/TX-RX/OfficePranks/main/CatFacts.ps1',
    [datetime]$StartTime     = (Get-Date '09:00'),
    [datetime]$EndTime       = (Get-Date '17:00'),
    [int]$IntervalMinutes    = 30,
    [switch]$SkipVerifyRun
)

$ErrorActionPreference = 'Stop'

# 1. Locate (or fetch) the payload.
#    $PSScriptRoot is empty when this script is run via `iex (irm ...)`
#    (no file on disk), which PowerShell 7's Join-Path rejects — guard it.
$LocalClone = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'CatFacts.ps1' } else { $null }

if ($LocalClone -and (Test-Path $LocalClone)) {
    $TargetScript = $LocalClone
    Write-Host "Using existing CatFacts.ps1 from clone: $TargetScript"
} else {
    $InstallDir = Join-Path $env:LOCALAPPDATA 'OfficePranks'
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir | Out-Null
    }
    $TargetScript = Join-Path $InstallDir 'CatFacts.ps1'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host "Downloading CatFacts.ps1 from $SourceUrl"
    Invoke-WebRequest -Uri $SourceUrl -OutFile $TargetScript -UseBasicParsing
    Write-Host "Saved to $TargetScript"
}

# 2. Build the scheduled task: weekdays, every N minutes between
#    StartTime and EndTime, hidden window, current-user context.
$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$TargetScript`""

$trigger = New-ScheduledTaskTrigger `
    -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday `
    -At $StartTime

$duration = $EndTime - $StartTime
$trigger.Repetition = (New-ScheduledTaskTrigger `
    -Once -At $StartTime `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
    -RepetitionDuration $duration).Repetition

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action -Trigger $trigger -Settings $settings -Principal $principal `
    -Description 'OfficePranks: random cat facts during work hours.' | Out-Null

Write-Host "Scheduled task '$TaskName' registered: every $IntervalMinutes min, $($StartTime.ToString('HH:mm'))-$($EndTime.ToString('HH:mm')) Mon-Fri."

# 3. Fire once to verify (bypasses the random gate via -Force).
if (-not $SkipVerifyRun) {
    Write-Host "Firing CatFacts.ps1 -Force once to verify (you should hear a fact)..."
    & $TargetScript -Force
}

Write-Host "Done. To remove: .\Uninstall-CatFacts.ps1"
