#Requires -Version 5.1
<#
.SYNOPSIS
    Manage dependency-map.yaml component nodes (system context).
.DESCRIPTION
    -Action add|update|delete on a component node.
      add    -Id -Type -Path -Domain
      update -Id [-Type] [-Path] [-Domain]
      delete -Id            (removes node + all edges + cascades linked behaviours)
    Delete cascades: edges referencing the id, and behaviours whose `via` is the id
    (scalar in <domain>.yaml, or contained in the `via` list of cross-domain.yaml).
    Every removal is listed - no silent drops.
#>
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('add', 'update', 'delete')][string]$Action,
    [string]$Id,
    [ValidateSet('api', 'service', 'repository', 'external', 'ui', 'worker', 'job')][string]$Type,
    [string]$Path,
    [string]$Domain,
    [string]$Root = 'docs/system-context'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_sc-common.ps1"

if (-not $Id) { Write-ScError 'components: -Id is required' }

$mapFile = Join-Path $Root 'dependency-map.yaml'
Initialize-ScListFile $mapFile @('components', 'dependencies')
$lines = Read-ScLines $mapFile

$sec = Get-ScSection $lines 'components'
$existing = Get-ScItem $lines $sec.Start $sec.End 'id' $Id

switch ($Action) {
    'add' {
        if ($existing) { Write-ScError "components: '$Id' already exists" }
        if (-not $Type) { Write-ScError 'components add: -Type is required' }
        if (-not $Path) { Write-ScError 'components add: -Path is required' }
        if (-not $Domain) { Write-ScError 'components add: -Domain is required' }
        $item = New-ScItemLines @(
            @{ Name = 'id'; Value = $Id },
            @{ Name = 'type'; Value = $Type },
            @{ Name = 'path'; Value = $Path },
            @{ Name = 'domain'; Value = $Domain }
        )
        $lines = Add-ScItem $lines 'components' $item
        Write-ScLines $mapFile $lines
        Write-Output "ok: added component $Id ($Type, domain=$Domain)"
    }
    'update' {
        if (-not $existing) { Write-ScError "components: '$Id' not found" }
        foreach ($pair in @(@('type', $Type), @('path', $Path), @('domain', $Domain))) {
            if ($pair[1]) {
                $sec = Get-ScSection $lines 'components'
                $it = Get-ScItem $lines $sec.Start $sec.End 'id' $Id
                $lines = Set-ScItemField $lines $it.Start $it.End $pair[0] $pair[1]
            }
        }
        Write-ScLines $mapFile $lines
        Write-Output "ok: updated component $Id"
    }
    'delete' {
        if (-not $existing) { Write-ScError "components: '$Id' not found" }
        $removed = New-Object System.Collections.Generic.List[string]

        # 1. remove the component node
        $lines = Remove-ScItem $lines 'components' $existing.Start $existing.End
        $removed.Add("component $Id")

        # 2. remove edges: dependency items with from=Id, and Id from any `to` list
        $depSec = Get-ScSection $lines 'dependencies'
        $fromItem = Get-ScItem $lines $depSec.Start $depSec.End 'from' $Id
        if ($fromItem) {
            $lines = Remove-ScItem $lines 'dependencies' $fromItem.Start $fromItem.End
            $removed.Add("edges from $Id")
        }
        # strip Id from remaining `to` lists
        $depSec = Get-ScSection $lines 'dependencies'
        $i = $depSec.Start
        while ($i -lt (Get-ScSection $lines 'dependencies').End) {
            $line = $lines[$i]
            if ($line -match '^(\s{4}to:\s*)(\[.*\])\s*$') {
                $orig = @(Read-ScList $Matches[2])
                $toList = @($orig | Where-Object { $_ -ne $Id })
                if ($orig.Count -ne $toList.Count) {
                    $lines[$i] = "$($Matches[1])$(Format-ScList $toList)"
                    $removed.Add("edge -> $Id")
                }
            }
            $i++
        }
        Write-ScLines $mapFile $lines

        # 3. cascade behaviours whose via references the id, across all domain files
        foreach ($f in (Get-ChildItem -LiteralPath $Root -Filter '*.yaml' -File | Where-Object { $_.Name -notin @('index.yaml', 'dependency-map.yaml') })) {
            $isCross = ($f.Name -eq 'cross-domain.yaml')
            $flines = Read-ScLines $f.FullName
            $bsec = Get-ScSection $flines 'behaviors'
            if ($null -eq $bsec) { continue }
            $changed = $false
            $bStart = $bsec.Start
            $ids = New-Object System.Collections.Generic.List[string]
            # collect behaviour ids to remove first (indices shift on removal)
            $cur = -1
            for ($k = $bsec.Start; $k -lt $bsec.End; $k++) {
                if ($flines[$k] -match '^\s{2}-\s') {
                    if ($cur -ge 0) { $ids.Add((Get-ScItemField $flines $cur $k 'id')) | Out-Null }
                    $cur = $k
                }
            }
            if ($cur -ge 0) { $ids.Add((Get-ScItemField $flines $cur $bsec.End 'id')) | Out-Null }
            foreach ($bid in $ids) {
                $bsec = Get-ScSection $flines 'behaviors'
                $bit = Get-ScItem $flines $bsec.Start $bsec.End 'id' $bid
                if (-not $bit) { continue }
                $viaRaw = Get-ScItemFieldRaw $flines $bit.Start $bit.End 'via'
                $hit = $false
                if ($isCross) { $hit = ((Read-ScList $viaRaw) -contains $Id) }
                else { $hit = ((Read-ScValue $viaRaw) -eq $Id) }
                if ($hit) {
                    $flines = Remove-ScItem $flines 'behaviors' $bit.Start $bit.End
                    $removed.Add("behaviour $bid ($($f.Name))")
                    $changed = $true
                }
            }
            if ($changed) { Write-ScLines $f.FullName $flines }
        }

        Write-Output "ok: deleted component $Id"
        foreach ($r in $removed) { Write-Output "  removed: $r" }
    }
}
