#Requires -Version 5.1
<#
.SYNOPSIS
    Installs a tool's agent and prompt files in the target .copilot folder.

.DESCRIPTION
    If the source tool contains _installation/powershell/install.ps1, that script is invoked
    with -TargetBase and any additional arguments (ScriptArgs). Otherwise
    agents and prompts are copied using the default logic.

.PARAMETER TargetBase
    Path to the .copilot folder (e.g. C:\Users\USERNAME\.copilot).

.PARAMETER Name
    Tool name (e.g. sda). Expects source at: tools/{Name}/agents/ and tools/{Name}/prompts/.

.PARAMETER AgentFilter
    Optional array of agent basenames (without .agent.md) to install.
    If omitted, all agents in the source folder are installed.
    Passed through to custom install scripts as-is.

.PARAMETER AgentExclude
    Optional array of agent basenames (without .agent.md) to exclude.
    Applied after AgentFilter. Passed through to custom install scripts.

.PARAMETER ScriptArgs
    Opaque string passed through to a custom scripts/install.ps1.
#>

param(
    [Parameter(Mandatory)] [string] $TargetBase,
    [Parameter(Mandatory)] [string] $Name,
    [string[]] $AgentFilter = @(),
    [string[]] $AgentExclude = @(),
    [string] $ScriptArgs = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Paths ────────────────────────────────────────────────────────────────────
$RepoRoot    = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
$ToolSrc     = Join-Path $RepoRoot "tools\$Name"

# ── Custom install script? ───────────────────────────────────────────────────
$CustomScript = Join-Path $ToolSrc '_installation\powershell\install.ps1'
if (Test-Path $CustomScript) {
    Write-Host "=== Installing tool: $Name (custom) ==="
    $passArgs = @{ TargetBase = $TargetBase }
    if ($AgentFilter -and $AgentFilter.Count -gt 0) {
        $passArgs['AgentFilter'] = $AgentFilter
    }
    if ($AgentExclude -and $AgentExclude.Count -gt 0) {
        $passArgs['AgentExclude'] = $AgentExclude
    }
    if ($ScriptArgs) {
        $passArgs['ScriptArgs'] = $ScriptArgs
    }
    & $CustomScript @passArgs
    Write-Host "  Done.`n"
    return
}

# ── Default: copy agents + prompts ───────────────────────────────────────────
$AgentsSrc  = Join-Path $ToolSrc 'agents'
$PromptsSrc = Join-Path $ToolSrc 'prompts'
$AgentsDst  = Join-Path $TargetBase 'agents'
$PromptsDst = Join-Path $TargetBase 'prompts'

# ── Discover managed files from source ────────────────────────────────────────
function Get-SourceFiles($Path, $Filter) {
    if (Test-Path $Path) {
        Get-ChildItem -Path $Path -Filter $Filter -File | Select-Object -ExpandProperty Name
    } else {
        @()
    }
}

[string[]] $AgentFiles  = @(Get-SourceFiles $AgentsSrc  '*.agent.md')
[string[]] $PromptFiles = @(Get-SourceFiles $PromptsSrc '*.prompt.md')

# ── Apply agent filter if specified ───────────────────────────────────────────
if ($AgentFilter -and $AgentFilter.Count -gt 0) {
    $Allowed = $AgentFilter | ForEach-Object { "${_}.agent.md" }
    $AgentFiles = @($AgentFiles | Where-Object { $_ -in $Allowed })
}
if ($AgentExclude -and $AgentExclude.Count -gt 0) {
    $Excluded = $AgentExclude | ForEach-Object { "${_}.agent.md" }
    $AgentFiles = @($AgentFiles | Where-Object { $_ -notin $Excluded })
}

if ($AgentFiles.Count -eq 0 -and $PromptFiles.Count -eq 0) {
    Write-Warning "No agent or prompt files found in tools\$Name. Nothing to do."
    return
}

Write-Host "=== Installing tool: $Name ==="

# DELETE
Write-Host '  Delete:'
foreach ($F in $AgentFiles) {
    $Target = Join-Path $AgentsDst $F
    if (Test-Path $Target) { Remove-Item $Target -Force; Write-Host "    agents\$F" }
}
foreach ($F in $PromptFiles) {
    $Target = Join-Path $PromptsDst $F
    if (Test-Path $Target) { Remove-Item $Target -Force; Write-Host "    prompts\$F" }
}

# COPY
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

Write-Host "  Done.`n"
