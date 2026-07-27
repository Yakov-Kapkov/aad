#Requires -Version 5.1
<#
.SYNOPSIS
    Installs or uninstalls the dev suite in the user's .copilot folder.

.PARAMETER Action
    'install' (default) or 'uninstall'.

.PARAMETER TargetBase
    Path to the .copilot folder. Default: $env:USERPROFILE\.copilot.

.PARAMETER Mode
    Installation mode: 'full' (all SDA agents) or 'short' (core agents only).
    Default: short. Ignored when Action is 'uninstall'.

.PARAMETER Models
    Optional array of "agentname=model" assignments for SDA agents.
    Example: @('sda-coder=Claude Opus 4 (Copilot)', 'sda-dev=Claude Opus 4 (Copilot)')
    Ignored when Action is 'uninstall'.
#>

param(
    [ValidateSet('install', 'uninstall')]
    [string] $Action = 'install',
    [string] $TargetBase = "$env:USERPROFILE\.copilot",
    [ValidateSet('full', 'short')]
    [string] $Mode = 'short',
    [string[]] $Models
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent

Write-Host "`nTarget: $TargetBase" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Cyan

# ══════════════════════════════════════════════════════════════════════════════
# UNINSTALL
# ══════════════════════════════════════════════════════════════════════════════
if ($Action -eq 'uninstall') {
    Write-Host "`n=== Uninstalling dev suite ===" -ForegroundColor Red

    # SDA agents
    $AgentsDst = Join-Path $TargetBase 'agents'
    Get-ChildItem $AgentsDst -Filter 'sda-*.agent.md' -File -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Host "  Removed agents\$($_.Name)"
    }
    # commit agent
    $CommitAgent = Join-Path $AgentsDst 'commit.agent.md'
    if (Test-Path $CommitAgent) { Remove-Item $CommitAgent -Force; Write-Host '  Removed agents\commit.agent.md' }

    # SDA prompts
    $PromptsDst = Join-Path $TargetBase 'prompts'
    Get-ChildItem $PromptsDst -Filter 'sda_*.prompt.md' -File -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Host "  Removed prompts\$($_.Name)"
    }
    # commit prompts
    Get-ChildItem $PromptsDst -Filter 'commit*.prompt.md' -File -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Host "  Removed prompts\$($_.Name)"
    }

    # Skills
    $SkillsDst = Join-Path $TargetBase 'skills'
    foreach ($Skill in @('sda-setup', 'standards-compliance', 'troubleshooting')) {
        $Dir = Join-Path $SkillsDst $Skill
        if (Test-Path $Dir) { Remove-Item $Dir -Recurse -Force; Write-Host "  Removed skills\$Skill\" }
    }

    Write-Host "`nDev suite uninstalled.`n" -ForegroundColor Green
    return
}

# ══════════════════════════════════════════════════════════════════════════════
# INSTALL
# ══════════════════════════════════════════════════════════════════════════════
Write-Host "Mode:   $Mode" -ForegroundColor Cyan

# ── SDA tool ─────────────────────────────────────────────────────────────────
Write-Host "`n=== Installing SDA tool ===" -ForegroundColor Cyan
$sdaToolArgs = @{ TargetBase = $TargetBase; Name = 'sda' }
if ($Mode -eq 'short') {
    $sdaToolArgs['AgentExclude'] = @('sda-system', 'sda-feature')
}
& (Join-Path $PSScriptRoot 'install-tool.ps1') @sdaToolArgs

# ── sda-setup skill ─────────────────────────────────────────────────────────
Write-Host "`n== Installing sda-setup skill ==" -ForegroundColor Yellow
& (Join-Path $PSScriptRoot 'install-skill.ps1') -TargetBase $TargetBase -Name 'sda-setup' -SourcePath 'tools\sda\skills\sda-setup'
Write-Host '  Copying tool-discovery assets...' -ForegroundColor Gray
$Dst = Join-Path $TargetBase 'skills\sda-setup\assets\tool-discovery'
Get-ChildItem (Join-Path $RepoRoot 'resources') -Directory | ForEach-Object {
    $Lang = $_.Name
    $Src = Join-Path $_.FullName 'tool-discovery.md'
    if (Test-Path $Src) {
        $LangDir = Join-Path $Dst $Lang
        New-Item -ItemType Directory -Path $LangDir -Force | Out-Null
        Copy-Item $Src -Destination $LangDir -Force
        Write-Host "    $Lang/tool-discovery.md"
    }
}
Write-Host '  Copying tool-catalog assets...' -ForegroundColor Gray
$Dst = Join-Path $TargetBase 'skills\sda-setup\assets\tool-catalog'
Get-ChildItem (Join-Path $RepoRoot 'resources') -Directory | ForEach-Object {
    $Lang = $_.Name
    $Src = Join-Path $_.FullName 'tool-catalog.md'
    if (Test-Path $Src) {
        $LangDir = Join-Path $Dst $Lang
        New-Item -ItemType Directory -Path $LangDir -Force | Out-Null
        Copy-Item $Src -Destination $LangDir -Force
        Write-Host "    $Lang/tool-catalog.md"
    }
}

# ── commit agent ─────────────────────────────────────────────────────────────
Write-Host "`n== Installing commit agent ==" -ForegroundColor Yellow
$CommitSrc = Join-Path $RepoRoot 'agents\commit\commit.agent.md'
$CommitDst = Join-Path $TargetBase 'agents'
New-Item -ItemType Directory -Path $CommitDst -Force | Out-Null
Copy-Item $CommitSrc -Destination (Join-Path $CommitDst 'commit.agent.md') -Force
Write-Host '  commit.agent.md'

# ── Patch agent models ───────────────────────────────────────────────────────
if ($Models -and $Models.Count -gt 0) {
    Write-Host "`n== Patching agent models ==" -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot 'set-agent-models.ps1') -TargetBase $TargetBase -Models $Models
}

# ── commit prompts ───────────────────────────────────────────────────────────
Write-Host "`n== Installing commit prompts ==" -ForegroundColor Yellow
$PromptsSrc = Join-Path $RepoRoot 'prompts\commit'
$PromptsDst = Join-Path $TargetBase 'prompts'
New-Item -ItemType Directory -Path $PromptsDst -Force | Out-Null
Get-ChildItem $PromptsSrc -Filter '*.prompt.md' -File | ForEach-Object {
    Copy-Item $_.FullName -Destination (Join-Path $PromptsDst $_.Name) -Force
    Write-Host "  $($_.Name)"
}

# ── standards-compliance skill ───────────────────────────────────────────────
Write-Host "`n== Installing standards-compliance skill ==" -ForegroundColor Yellow
& (Join-Path $PSScriptRoot 'install-skill.ps1') -TargetBase $TargetBase -Name 'standards-compliance'

# ── troubleshooting skill ────────────────────────────────────────────────────
Write-Host "`n== Installing troubleshooting skill ==" -ForegroundColor Yellow
& (Join-Path $PSScriptRoot 'install-skill.ps1') -TargetBase $TargetBase -Name 'troubleshooting'

Write-Host ''
