# Validate-Pranks.ps1
#
# Enforces the contribution rules in CONTRIBUTING.md. Runs locally and in
# CI via .github/workflows/validate.yml.
#
# Exits 0 on pass, 1 on any failure. The malicious-pattern denylist and
# the network allowlist are loaded from .\denylist.json so that this
# script itself contains no literal strings that would trip static AV
# heuristics.
#
# Run from the repo root:
#   .\.github\scripts\Validate-Pranks.ps1

[CmdletBinding()]
param(
    [string]$RepoRoot     = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$DenylistPath = (Join-Path $PSScriptRoot 'denylist.json')
)

$ErrorActionPreference = 'Stop'
$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$m) { $script:failures.Add($m) }
function Add-Warning([string]$m) { $script:warnings.Add($m) }

function Get-PrankScripts {
    Get-ChildItem -Path $RepoRoot -Filter '*.ps1' -File |
        Where-Object { $_.FullName -notlike '*\.github\*' }
}

# ---------------------------------------------------------------------------
# Load the denylist + network allowlist (external data only).
# ---------------------------------------------------------------------------
if (-not (Test-Path $DenylistPath)) {
    throw "Denylist not found at $DenylistPath"
}
$config = Get-Content -Raw -Path $DenylistPath | ConvertFrom-Json

# ---------------------------------------------------------------------------
# Check 1: PowerShell parse errors across every .ps1 in the repo.
# ---------------------------------------------------------------------------
Write-Host "==> Parsing all .ps1 files..."
$allScripts = Get-ChildItem -Path $RepoRoot -Filter '*.ps1' -File -Recurse
foreach ($file in $allScripts) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        foreach ($e in $parseErrors) {
            Add-Failure "Parse error in $($file.Name) line $($e.Extent.StartLineNumber): $($e.Message)"
        }
    }
}

# ---------------------------------------------------------------------------
# Check 2: PSScriptAnalyzer (errors fail; warnings are advisory).
# ---------------------------------------------------------------------------
Write-Host "==> Running PSScriptAnalyzer..."
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Add-Warning "PSScriptAnalyzer not installed. Skipping. Install with: Install-Module PSScriptAnalyzer -Scope CurrentUser"
} else {
    Import-Module PSScriptAnalyzer
    foreach ($file in $allScripts) {
        $results = Invoke-ScriptAnalyzer -Path $file.FullName -Severity @('Error','Warning')
        foreach ($r in $results) {
            $line = "$($file.Name):$($r.Line) [$($r.Severity)] $($r.RuleName): $($r.Message)"
            if ($r.Severity -eq 'Error') { Add-Failure $line } else { Add-Warning $line }
        }
    }
}

# ---------------------------------------------------------------------------
# Check 3: Paired Install-/Uninstall- for every top-level payload.
# ---------------------------------------------------------------------------
Write-Host "==> Checking install/uninstall pairing..."
$prankScripts = Get-PrankScripts
$payloadNames = $prankScripts |
    Where-Object { $_.BaseName -notlike 'Install-*' -and $_.BaseName -notlike 'Uninstall-*' } |
    ForEach-Object { $_.BaseName }

foreach ($name in $payloadNames) {
    $installer   = Join-Path $RepoRoot "Install-$name.ps1"
    $uninstaller = Join-Path $RepoRoot "Uninstall-$name.ps1"
    if (-not (Test-Path $installer)) {
        Add-Failure "Payload '$name.ps1' has no matching 'Install-$name.ps1'. See CONTRIBUTING.md rule 5."
    }
    if (-not (Test-Path $uninstaller)) {
        Add-Failure "Payload '$name.ps1' has no matching 'Uninstall-$name.ps1'. See CONTRIBUTING.md rule 5."
    }
}

# ---------------------------------------------------------------------------
# Check 4: Apply the JSON-driven denylist and network allowlist.
#   Exclude this script and the denylist itself from the scan to avoid
#   self-matches on the rule definitions.
# ---------------------------------------------------------------------------
Write-Host "==> Scanning for forbidden patterns..."
$selfPaths = @(
    (Resolve-Path $PSCommandPath).Path
    (Resolve-Path $DenylistPath).Path
)
$scanScripts = $allScripts | Where-Object { $selfPaths -notcontains $_.FullName }

foreach ($file in $scanScripts) {
    $content = Get-Content -Raw -Path $file.FullName
    if (-not $content) { continue }

    foreach ($entry in $config.denylist) {
        $rxMatches = [regex]::Matches($content, $entry.pattern, 'IgnoreCase')
        foreach ($m in $rxMatches) {
            $lineNo = ($content.Substring(0, $m.Index) -split "`n").Count
            $line = "$($file.Name):$lineNo  $($entry.message)  (matched: '$($m.Value)')"
            if ($entry.severity -eq 'fail') { Add-Failure $line } else { Add-Warning $line }
        }
    }

    $urlMatches = [regex]::Matches($content, 'https?://([^\s''")]+)', 'IgnoreCase')
    foreach ($u in $urlMatches) {
        $endpoint = $u.Groups[1].Value
        $allowed = $false
        foreach ($pat in $config.networkAllowlist) {
            if ($endpoint -match $pat) { $allowed = $true; break }
        }
        if (-not $allowed) {
            $lineNo = ($content.Substring(0, $u.Index) -split "`n").Count
            Add-Warning "$($file.Name):$lineNo  Network endpoint '$endpoint' is not on the allowlist. Add it to .github/scripts/denylist.json if intentional."
        }
    }
}

# ---------------------------------------------------------------------------
# Check 5: README mentions every top-level payload.
# ---------------------------------------------------------------------------
Write-Host "==> Checking README mentions every payload..."
$readme = Join-Path $RepoRoot 'README.md'
if (-not (Test-Path $readme)) {
    Add-Failure "README.md is missing."
} else {
    $readmeText = Get-Content -Raw -Path $readme
    foreach ($name in $payloadNames) {
        if ($readmeText -notmatch [regex]::Escape("$name.ps1")) {
            Add-Failure "README.md does not mention '$name.ps1'. New payloads must be documented (rule 5)."
        }
    }
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
Write-Host ""
if ($warnings.Count -gt 0) {
    Write-Host "Warnings ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  $w" -ForegroundColor Yellow }
    Write-Host ""
}

if ($failures.Count -gt 0) {
    Write-Host "Failures ($($failures.Count)):" -ForegroundColor Red
    foreach ($f in $failures) { Write-Host "  $f" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Validation FAILED. See CONTRIBUTING.md for the rules." -ForegroundColor Red
    exit 1
}

Write-Host "Validation passed." -ForegroundColor Green
exit 0
