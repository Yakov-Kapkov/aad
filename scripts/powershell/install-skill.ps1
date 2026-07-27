#Requires -Version 5.1
<#
.SYNOPSIS
    Installs a skill folder in the target .copilot folder.

.DESCRIPTION
    If the source skill contains _installation/powershell/install.ps1, that script is invoked
    with -DestFolder and any additional arguments (ScriptArgs). Otherwise
    the skill folder is copied as-is.

.PARAMETER TargetBase
    Path to the .copilot folder (e.g. C:\Users\USERNAME\.copilot).

.PARAMETER Name
    Skill name (e.g. commit, standards-compliance). Expects source at: skills/{Name}/.

.PARAMETER SourcePath
    Optional override for the source skill folder. If omitted, defaults to
    skills/{Name}/ relative to the repo root.

.PARAMETER ScriptArgs
    Additional arguments passed through to a custom scripts/install.ps1.
#>

param(
    [Parameter(Mandatory)] [string] $TargetBase,
    [Parameter(Mandatory)] [string] $Name,
    [string] $SourcePath,
    [string] $ScriptArgs = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Paths ────────────────────────────────────────────────────────────────────
$RepoRoot    = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent

if ($SourcePath) {
    $SkillSrc = Join-Path $RepoRoot $SourcePath
} else {
    $SkillSrc = Join-Path $RepoRoot "skills\$Name"
}
$SkillDst = Join-Path $TargetBase "skills\$Name"

if (-not (Test-Path $SkillSrc)) {
    Write-Warning "Source skill folder not found: $SkillSrc. Nothing to do."
    return
}

# ── Custom install script? ───────────────────────────────────────────────────
$CustomScript = Join-Path $SkillSrc '_installation\powershell\install.ps1'
if (Test-Path $CustomScript) {
    Write-Host "=== Installing skill: $Name (custom) ==="
    if ($ScriptArgs) {
        & $CustomScript -DestFolder $SkillDst -ScriptArgs $ScriptArgs
    } else {
        & $CustomScript -DestFolder $SkillDst
    }
    Write-Host "  Done.`n"
    return
}

# ── Default: delete + copy ───────────────────────────────────────────────────
Write-Host "=== Installing skill: $Name ==="

Write-Host '  Delete:'
if (Test-Path $SkillDst) {
    Remove-Item $SkillDst -Recurse -Force
    Write-Host "    $SkillDst"
} else {
    Write-Host '    (nothing to delete)'
}

Write-Host '  Copy:'
New-Item -ItemType Directory -Path $SkillDst -Force | Out-Null
Get-ChildItem $SkillSrc -Exclude '_installation' | ForEach-Object {
    Copy-Item $_.FullName -Destination $SkillDst -Recurse -Force
}
Get-ChildItem $SkillSrc -Recurse -File | Where-Object {
    $_.FullName -notlike "$SkillSrc\_installation\*"
} | ForEach-Object {
    $Rel = $_.FullName.Substring($SkillSrc.Length + 1)
    Write-Host "    $Rel"
}

Write-Host "  Done.`n"
