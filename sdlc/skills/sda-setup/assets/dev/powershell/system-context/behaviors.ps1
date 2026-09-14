#Requires -Version 5.1
<#
.SYNOPSIS
    Manage behaviours in a domain file or cross-domain.yaml (system context).
.DESCRIPTION
    -Action add|update|delete
      Domain behaviour (via is one component):
        add    -Domain <d> -Id -Claim -Via <componentId> -Status <s> [-VerifiedBy id] [-Note text]
        update -Domain <d> -Id [-Claim] [-Via] [-Status] [-VerifiedBy] [-Note]
        delete -Domain <d> -Id
      Cross-domain behaviour (via + domains are lists) - use -Domain cross-domain:
        add    -Domain cross-domain -Id -Claim -Via "a,b" -Domains "d1,d2" -Status <s> [-VerifiedBy id]
    Status is verified | pending-reverification.
#>
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('add', 'update', 'delete')][string]$Action,
    [Parameter(Mandatory)][string]$Domain,
    [Parameter(Mandatory)][string]$Id,
    [string]$Claim,
    [string]$Via,
    [string]$Domains,
    [ValidateSet('verified', 'pending-reverification')][string]$Status,
    [string]$VerifiedBy,
    [string]$Note,
    [string]$Root = 'docs/system-context'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_sc-common.ps1"

$isCross = ($Domain -eq 'cross-domain')
$file = Join-Path $Root "$Domain.yaml"
if ($isCross) { Initialize-ScListFile $file @('behaviors') }
elseif (-not (Test-Path $file)) { Write-ScError "behaviors: domain '$Domain' not found (create it with domains -Action add)" }
$lines = Read-ScLines $file

$sec = Get-ScSection $lines 'behaviors'
if ($null -eq $sec) { Write-ScError "behaviors: section missing in $Domain.yaml" }
$existing = Get-ScItem $lines $sec.Start $sec.End 'id' $Id

switch ($Action) {
    'add' {
        if ($existing) { Write-ScError "behaviors: '$Id' already exists in $Domain" }
        if (-not $Claim) { Write-ScError 'behaviors add: -Claim is required' }
        if (-not $Via) { Write-ScError 'behaviors add: -Via is required' }
        if (-not $Status) { Write-ScError 'behaviors add: -Status is required' }
        if ($isCross) {
            if (-not $Domains) { Write-ScError 'behaviors add (cross-domain): -Domains is required' }
            $item = New-ScItemLines @(
                @{ Name = 'id'; Value = $Id },
                @{ Name = 'claim'; Value = $Claim },
                @{ Name = 'via'; Value = @($Via -split '\s*,\s*'); List = $true },
                @{ Name = 'domains'; Value = @($Domains -split '\s*,\s*'); List = $true },
                @{ Name = 'status'; Value = $Status },
                @{ Name = 'verified_by'; Value = $VerifiedBy }
            )
        } else {
            $item = New-ScItemLines @(
                @{ Name = 'id'; Value = $Id },
                @{ Name = 'claim'; Value = $Claim },
                @{ Name = 'via'; Value = $Via },
                @{ Name = 'status'; Value = $Status },
                @{ Name = 'verified_by'; Value = $VerifiedBy },
                @{ Name = 'note'; Value = $Note }
            )
        }
        $lines = Add-ScItem $lines 'behaviors' $item
        Write-ScLines $file $lines
        Write-Output "ok: added behaviour $Id ($Domain, $Status)"
    }
    'update' {
        if (-not $existing) { Write-ScError "behaviors: '$Id' not found in $Domain" }
        foreach ($pair in @(@('claim', $Claim), @('status', $Status), @('verified_by', $VerifiedBy), @('note', $Note))) {
            if ($pair[1]) {
                $sec = Get-ScSection $lines 'behaviors'
                $it = Get-ScItem $lines $sec.Start $sec.End 'id' $Id
                $lines = Set-ScItemField $lines $it.Start $it.End $pair[0] $pair[1]
            }
        }
        if ($Via) {
            $sec = Get-ScSection $lines 'behaviors'
            $it = Get-ScItem $lines $sec.Start $sec.End 'id' $Id
            if ($isCross) { $lines = Set-ScItemFieldList $lines $it.Start $it.End 'via' @($Via -split '\s*,\s*') }
            else { $lines = Set-ScItemField $lines $it.Start $it.End 'via' $Via }
        }
        Write-ScLines $file $lines
        Write-Output "ok: updated behaviour $Id ($Domain)"
    }
    'delete' {
        if (-not $existing) { Write-ScError "behaviors: '$Id' not found in $Domain" }
        $lines = Remove-ScItem $lines 'behaviors' $existing.Start $existing.End
        Write-ScLines $file $lines
        Write-Output "ok: deleted behaviour $Id ($Domain)"
    }
}
