#Requires -Version 5.1
<#
.SYNOPSIS
    Manage decisions in a domain file (system context).
.DESCRIPTION
    -Action add|update  (decisions are superseded, never deleted)
      add    -Domain -Id -Summary -Rationale [-Status active]
      update -Domain -Id [-Summary] [-Rationale] [-Status] [-SupersededBy]
    Supersede a decision:  update -Status superseded -SupersededBy <new-id>
#>
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('add', 'update')][string]$Action,
    [Parameter(Mandatory)][string]$Domain,
    [Parameter(Mandatory)][string]$Id,
    [string]$Summary,
    [string]$Rationale,
    [ValidateSet('active', 'superseded')][string]$Status,
    [string]$SupersededBy,
    [string]$Root = 'docs/system-context'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_sc-common.ps1"

$domainFile = Join-Path $Root "$Domain.yaml"
if (-not (Test-Path $domainFile)) { Write-ScError "decisions: domain '$Domain' not found (create it with domains -Action add)" }
$lines = Read-ScLines $domainFile

$sec = Get-ScSection $lines 'decisions'
if ($null -eq $sec) { Write-ScError "decisions: section missing in $Domain.yaml" }
$existing = Get-ScItem $lines $sec.Start $sec.End 'id' $Id

switch ($Action) {
    'add' {
        if ($existing) { Write-ScError "decisions: '$Id' already exists in $Domain" }
        if (-not $Summary) { Write-ScError 'decisions add: -Summary is required' }
        if (-not $Rationale) { Write-ScError 'decisions add: -Rationale is required' }
        if (-not $Status) { $Status = 'active' }
        $item = New-ScItemLines @(
            @{ Name = 'id'; Value = $Id },
            @{ Name = 'summary'; Value = $Summary },
            @{ Name = 'rationale'; Value = $Rationale },
            @{ Name = 'status'; Value = $Status },
            @{ Name = 'superseded_by'; Value = $SupersededBy }
        )
        $lines = Add-ScItem $lines 'decisions' $item
        Write-ScLines $domainFile $lines
        Write-Output "ok: added decision $Id ($Domain)"
    }
    'update' {
        if (-not $existing) { Write-ScError "decisions: '$Id' not found in $Domain" }
        foreach ($pair in @(@('summary', $Summary), @('rationale', $Rationale), @('status', $Status), @('superseded_by', $SupersededBy))) {
            if ($pair[1]) {
                $sec = Get-ScSection $lines 'decisions'
                $it = Get-ScItem $lines $sec.Start $sec.End 'id' $Id
                $lines = Set-ScItemField $lines $it.Start $it.End $pair[0] $pair[1]
            }
        }
        Write-ScLines $domainFile $lines
        Write-Output "ok: updated decision $Id ($Domain)"
    }
}
