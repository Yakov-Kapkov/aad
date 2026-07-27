#Requires -Version 5.1
<#
.SYNOPSIS
    Custom install script for the standards-compliance skill.

.DESCRIPTION
    Copies the skill folder, then assembles per-language standards from
    resources/{lang}/standards/ and common-standards.md into the destination.

.PARAMETER DestFolder
    The destination folder for this skill (e.g. ~/.copilot/skills/standards-compliance).
#>

param(
    [Parameter(Mandatory)][string] $DestFolder
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Paths ────────────────────────────────────────────────────────────────────
$SkillSrc    = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent  # up from _installation/powershell/
$RepoRoot    = $SkillSrc | Split-Path -Parent | Split-Path -Parent      # repo root
$ResourceSrc = Join-Path $RepoRoot 'resources'

# ── Step 1: Clean copy of skill folder ───────────────────────────────────────
Write-Host '  Delete:'
if (Test-Path $DestFolder) {
    Remove-Item $DestFolder -Recurse -Force
    Write-Host "    $DestFolder"
} else {
    Write-Host '    (nothing to delete)'
}

Write-Host '  Copy skill:'
New-Item -ItemType Directory -Path $DestFolder -Force | Out-Null
Get-ChildItem $SkillSrc -Exclude '_installation' | ForEach-Object {
    Copy-Item $_.FullName -Destination $DestFolder -Recurse -Force
}
Get-ChildItem $SkillSrc -Recurse -File | Where-Object {
    $_.FullName -notlike "$SkillSrc\_installation\*"
} | ForEach-Object {
    $Rel = $_.FullName.Substring($SkillSrc.Length + 1)
    Write-Host "    $Rel"
}

# ── Step 2: Copy common-standards.md ─────────────────────────────────────────
$CommonSrc    = Join-Path $ResourceSrc 'common-standards.md'
$StandardsDst = Join-Path $DestFolder 'standards'
if (Test-Path $CommonSrc) {
    New-Item -ItemType Directory -Path $StandardsDst -Force | Out-Null
    Copy-Item $CommonSrc -Destination $StandardsDst -Force
    Write-Host "    standards\common-standards.md"
} else {
    Write-Warning "    Common standards not found: $CommonSrc"
}

# ── Step 3: Copy per-language standards ──────────────────────────────────────
$Languages = Get-ChildItem -Path $ResourceSrc -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'standards') } |
    ForEach-Object { $_.Name }

Write-Host '  Copy standards:'
foreach ($Lang in $Languages) {
    $Src = Join-Path $ResourceSrc "$Lang\standards"
    $Dst = Join-Path $DestFolder "standards\$Lang"
    if (Test-Path $Src) {
        New-Item -ItemType Directory -Path $Dst -Force | Out-Null
        Get-ChildItem -Path $Src -File | ForEach-Object {
            Copy-Item $_.FullName -Destination $Dst -Force
            Write-Host "    standards\$Lang\$($_.Name)"
        }
    }
}
