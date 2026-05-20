# Uninstall-CatFacts.ps1
#
# Removes the scheduled task and installed script created by Install-CatFacts.ps1.
# Safe to run even if nothing is installed.

[CmdletBinding()]
param(
    [string]$TaskName   = 'OfficePranks-CatFacts',
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'OfficePranks')
)

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed scheduled task '$TaskName'."
} else {
    Write-Host "No scheduled task named '$TaskName' found."
}

if (Test-Path $InstallDir) {
    if (Test-Path (Join-Path $InstallDir '.git')) {
        Write-Host "Install directory $InstallDir looks like a git clone — leaving it in place."
    } else {
        Remove-Item -Path $InstallDir -Recurse -Force
        Write-Host "Removed install directory $InstallDir."
    }
} else {
    Write-Host "No install directory at $InstallDir."
}

Write-Host "Uninstall complete."
