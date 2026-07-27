#Requires -Version 5.1
<#
.SYNOPSIS
    Patches model: lines in agent frontmatter YAML.

.DESCRIPTION
    Walks each "agentname=model" assignment, finds the installed .agent.md
    file under TargetBase/agents/, and updates or inserts the model: line.

.PARAMETER TargetBase
    Path to the .copilot folder containing agents/.

.PARAMETER Models
    Array of "agentname=model" assignments.
    Example: @('sda-coder=Claude Opus 4 (Copilot)', 'commit=Claude Haiku 4.5')
#>

param(
    [Parameter(Mandatory)][string] $TargetBase,
    [string[]] $Models
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Models -or $Models.Count -eq 0) { return }

$AgentsDst = Join-Path $TargetBase 'agents'

foreach ($Assignment in $Models) {
    $idx = $Assignment.IndexOf('=')
    if ($idx -lt 0) {
        Write-Host ("  {0,-20}: SKIP (bad format, expected agent=model)" -f $Assignment)
        continue
    }
    $Agent = $Assignment.Substring(0, $idx)
    $Model = $Assignment.Substring($idx + 1)
    $File  = Join-Path $AgentsDst "$Agent.agent.md"

    if (-not (Test-Path $File)) {
        Write-Host ("  {0,-20}: SKIP (not installed)" -f $Agent)
        continue
    }

    $Content = Get-Content $File -Raw
    if ($Content -match '(?m)^model:') {
        $Updated = $Content -replace '(?m)^model:\s*.+$', "model: $Model"
    } elseif ($Content -match '(?m)^tools:') {
        $Updated = $Content -replace '(?m)(^tools:\s*.+$)', "`$1`nmodel: $Model"
    } else {
        Write-Host ("  {0,-20}: FAIL (no model: or tools: line)" -f $Agent)
        continue
    }

    Set-Content -Path $File -Value $Updated -NoNewline
    Write-Host ("  {0,-20}: OK -> {1}" -f $Agent, $Model)
}
