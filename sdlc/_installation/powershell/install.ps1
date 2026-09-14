#Requires -Version 5.1
<#
.SYNOPSIS
    Custom install script for the SDA tool.

.DESCRIPTION
    Copies agent and prompt files, then optionally patches model: in agent
    frontmatter when -Models is provided.

.PARAMETER TargetBase
    Path to the .copilot folder (e.g. C:\Users\USERNAME\.copilot).

.PARAMETER AgentFilter
    Optional array of agent basenames (without .agent.md) to install.
    If omitted, all agents are installed.

.PARAMETER AgentExclude
    Optional array of agent basenames (without .agent.md) to exclude.
    Applied after AgentFilter.

.PARAMETER ScriptArgs
    Pipe-delimited "agentname=model" assignments.
    Example: 'sda-coder=Claude Opus 4 (Copilot)|sda-dev=Claude Opus 4 (Copilot)'
#>

param(
    [Parameter(Mandatory)][string] $TargetBase,
    [string[]] $AgentFilter = @(),
    [string[]] $AgentExclude = @(),
    [string] $ScriptArgs = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Paths ────────────────────────────────────────────────────────────────────
$ToolSrc    = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent  # up from _installation/powershell/
$AgentsSrc  = Join-Path $ToolSrc 'agents'
$PromptsSrc = Join-Path $ToolSrc 'prompts'
$AgentsDst  = Join-Path $TargetBase 'agents'
$PromptsDst = Join-Path $TargetBase 'prompts'

# ── Discover source files ────────────────────────────────────────────────────
function Get-SourceFiles($Path, $Filter) {
    if (Test-Path $Path) {
        Get-ChildItem -Path $Path -Filter $Filter -File | Select-Object -ExpandProperty Name
    } else {
        @()
    }
}

[string[]] $AgentFiles  = @(Get-SourceFiles $AgentsSrc  '*.agent.md')
[string[]] $PromptFiles = @(Get-SourceFiles $PromptsSrc '*.prompt.md')

# ── Apply agent filter ───────────────────────────────────────────────────────
if ($AgentFilter -and $AgentFilter.Count -gt 0) {
    $Allowed = $AgentFilter | ForEach-Object { "${_}.agent.md" }
    $AgentFiles = @($AgentFiles | Where-Object { $_ -in $Allowed })
}
if ($AgentExclude -and $AgentExclude.Count -gt 0) {
    $Excluded = $AgentExclude | ForEach-Object { "${_}.agent.md" }
    $AgentFiles = @($AgentFiles | Where-Object { $_ -notin $Excluded })
}

if ($AgentFiles.Count -eq 0 -and $PromptFiles.Count -eq 0) {
    Write-Warning "No agent or prompt files found. Nothing to do."
    return
}

# ── Delete existing ──────────────────────────────────────────────────────────
Write-Host '  Delete:'
foreach ($F in $AgentFiles) {
    $Target = Join-Path $AgentsDst $F
    if (Test-Path $Target) { Remove-Item $Target -Force; Write-Host "    agents\$F" }
}
foreach ($F in $PromptFiles) {
    $Target = Join-Path $PromptsDst $F
    if (Test-Path $Target) { Remove-Item $Target -Force; Write-Host "    prompts\$F" }
}

# ── Copy ─────────────────────────────────────────────────────────────────────
Write-Host '  Copy:'
if ($AgentFiles.Count -gt 0) { New-Item -ItemType Directory -Path $AgentsDst -Force | Out-Null }
if ($PromptFiles.Count -gt 0) { New-Item -ItemType Directory -Path $PromptsDst -Force | Out-Null }
foreach ($F in $AgentFiles) {
    Copy-Item (Join-Path $AgentsSrc $F) -Destination (Join-Path $AgentsDst $F) -Force
    Write-Host "    agents\$F"
}
foreach ($F in $PromptFiles) {
    Copy-Item (Join-Path $PromptsSrc $F) -Destination (Join-Path $PromptsDst $F) -Force
    Write-Host "    prompts\$F"
}

# ── Patch models ─────────────────────────────────────────────────────────────
[string[]] $Models = @()
if ($ScriptArgs) { [string[]] $Models = $ScriptArgs -split '\|' }
if ($Models.Count -gt 0) {
    Write-Host '  Patch models:'
    $RepoRoot  = $ToolSrc | Split-Path -Parent | Split-Path -Parent  # up from tools/sda/ to repo root
    $ModelScript = Join-Path $RepoRoot 'scripts\powershell\set-agent-models.ps1'
    & $ModelScript -TargetBase $TargetBase -Models $Models
}
