#Requires -Version 5.1
<#
.SYNOPSIS
    Read-only regression blast-radius query over the system-context graph.
.DESCRIPTION
    Given the changed components, reverse-traverse dependency-map.yaml (a
    dependent is a node that depends on a changed node), collect every at-risk
    component, then report the behaviours routed through them and their status.
    No writes.

      blast-radius -Components "auth-api,token-service" [-Root <dir>]

    Output:
      at-risk-components=[...]
      behaviour=<id> domain=<file> via=<...> status=<...>
      pending-count=<n>
      at-risk-count=<n>
#>
param(
    [Parameter(Mandatory)][string]$Components,
    [string]$Root = 'docs/system-context'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_sc-common.ps1"

$mapFile = Join-Path $Root 'dependency-map.yaml'
if (-not (Test-Path $mapFile)) { Write-ScError "blast-radius: dependency-map.yaml not found under $Root" }
$lines = Read-ScLines $mapFile

$seed = @($Components -split '\s*,\s*' | Where-Object { $_ -ne '' })
if ($seed.Count -eq 0) { Write-ScError 'blast-radius: -Components is empty' }

# Build reverse adjacency: dependents[b] = list of nodes that depend on b.
$dependents = @{}
$dsec = Get-ScSection $lines 'dependencies'
$curFrom = $null
for ($i = $dsec.Start; $i -lt $dsec.End; $i++) {
    if ($lines[$i] -match '^\s{2}-\s*from:\s*(.*)$') { $curFrom = (Read-ScValue $Matches[1]) }
    elseif ($lines[$i] -match '^\s{4}to:\s*(\[.*\])\s*$' -and $curFrom) {
        foreach ($t in (Read-ScList $Matches[1])) {
            if (-not $dependents.ContainsKey($t)) { $dependents[$t] = New-Object System.Collections.Generic.List[string] }
            $dependents[$t].Add($curFrom)
        }
    }
}

# BFS over reverse edges from the seed set.
$atRisk = New-Object System.Collections.Generic.HashSet[string]
$queue = New-Object System.Collections.Generic.Queue[string]
foreach ($s in $seed) { [void]$atRisk.Add($s); $queue.Enqueue($s) }
while ($queue.Count -gt 0) {
    $n = $queue.Dequeue()
    if ($dependents.ContainsKey($n)) {
        foreach ($dep in $dependents[$n]) {
            if ($atRisk.Add($dep)) { $queue.Enqueue($dep) }
        }
    }
}

Write-Output "at-risk-components=$(Format-ScList (@($atRisk) | Sort-Object))"

# Report behaviours routed through any at-risk component.
$pending = 0
$count = 0
foreach ($f in (Get-ChildItem -LiteralPath $Root -Filter '*.yaml' -File | Where-Object { $_.Name -notin @('index.yaml', 'dependency-map.yaml') } | Sort-Object Name)) {
    $flines = Read-ScLines $f.FullName
    $bsec = Get-ScSection $flines 'behaviors'
    if ($null -eq $bsec) { continue }
    $cur = -1
    $ends = New-Object System.Collections.Generic.List[int]
    $starts = New-Object System.Collections.Generic.List[int]
    for ($k = $bsec.Start; $k -lt $bsec.End; $k++) {
        if ($flines[$k] -match '^\s{2}-\s') {
            if ($cur -ge 0) { $starts.Add($cur); $ends.Add($k) }
            $cur = $k
        }
    }
    if ($cur -ge 0) { $starts.Add($cur); $ends.Add($bsec.End) }
    for ($b = 0; $b -lt $starts.Count; $b++) {
        $bs = $starts[$b]; $be = $ends[$b]
        $bid = Get-ScItemField $flines $bs $be 'id'
        $viaRaw = Get-ScItemFieldRaw $flines $bs $be 'via'
        $viaSet = if ($viaRaw -match '^\s*\[') { @(Read-ScList $viaRaw) } else { @(Read-ScValue $viaRaw) }
        $hit = $false
        foreach ($v in $viaSet) { if ($atRisk.Contains($v)) { $hit = $true; break } }
        if ($hit) {
            $status = Get-ScItemField $flines $bs $be 'status'
            Write-Output "behaviour=$bid domain=$($f.Name) via=$($viaSet -join '|') status=$status"
            $count++
            if ($status -eq 'pending-reverification') { $pending++ }
        }
    }
}
Write-Output "pending-count=$pending"
Write-Output "at-risk-count=$($atRisk.Count)"
