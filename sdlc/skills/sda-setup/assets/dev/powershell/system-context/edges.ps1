#Requires -Version 5.1
<#
.SYNOPSIS
    Manage dependency-map.yaml edges between existing component nodes.
.DESCRIPTION
    -Action add|delete
      add    -From -To     (both nodes must exist; deduped)
      delete -From -To     (removes the edge; empties collapse the `from` item)
#>
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('add', 'delete')][string]$Action,
    [Parameter(Mandatory)][string]$From,
    [Parameter(Mandatory)][string]$To,
    [string]$Root = 'docs/system-context'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_sc-common.ps1"

$mapFile = Join-Path $Root 'dependency-map.yaml'
Initialize-ScListFile $mapFile @('components', 'dependencies')
$lines = Read-ScLines $mapFile

# both nodes must exist
$csec = Get-ScSection $lines 'components'
foreach ($n in @($From, $To)) {
    if (-not (Get-ScItem $lines $csec.Start $csec.End 'id' $n)) { Write-ScError "edges: component '$n' not found" }
}

$dsec = Get-ScSection $lines 'dependencies'
$fromItem = Get-ScItem $lines $dsec.Start $dsec.End 'from' $From

switch ($Action) {
    'add' {
        if ($fromItem) {
            $raw = Get-ScItemFieldRaw $lines $fromItem.Start $fromItem.End 'to'
            $to = @(Read-ScList $raw)
            if ($to -contains $To) { Write-Output "ok: edge $From -> $To already present"; exit 0 }
            $to += $To
            $lines = Set-ScItemFieldList $lines $fromItem.Start $fromItem.End 'to' $to
        } else {
            $item = New-ScItemLines @(
                @{ Name = 'from'; Value = $From },
                @{ Name = 'to'; Value = @($To); List = $true }
            )
            $lines = Add-ScItem $lines 'dependencies' $item
        }
        Write-ScLines $mapFile $lines
        Write-Output "ok: added edge $From -> $To"
    }
    'delete' {
        if (-not $fromItem) { Write-ScError "edges: no dependencies from '$From'" }
        $raw = Get-ScItemFieldRaw $lines $fromItem.Start $fromItem.End 'to'
        $to = @(Read-ScList $raw | Where-Object { $_ -ne $To })
        if ((Read-ScList $raw) -notcontains $To) { Write-ScError "edges: edge $From -> $To not found" }
        if ($to.Count -eq 0) {
            $lines = Remove-ScItem $lines 'dependencies' $fromItem.Start $fromItem.End
        } else {
            $lines = Set-ScItemFieldList $lines $fromItem.Start $fromItem.End 'to' $to
        }
        Write-ScLines $mapFile $lines
        Write-Output "ok: deleted edge $From -> $To"
    }
}
