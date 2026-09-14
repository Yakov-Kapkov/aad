#Requires -Version 5.1
<#
.SYNOPSIS
    Manage domain files and their index.yaml registration (system context).
.DESCRIPTION
    -Action add|delete
      add    -Name [-Project]   creates <Name>.yaml (empty decisions/behaviors) and
                                registers it in index.yaml (creating index.yaml if absent)
      delete -Name              removes <Name>.yaml and unregisters it; its behaviours
                                and decisions are cascade-deleted with the file (listed)
#>
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('add', 'delete')][string]$Action,
    [Parameter(Mandatory)][string]$Name,
    [string]$Project,
    [string]$Root = 'docs/system-context'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_sc-common.ps1"

if ($Name -in @('index', 'dependency-map', 'cross-domain')) { Write-ScError "domains: '$Name' is a reserved file name" }

$indexFile = Join-Path $Root 'index.yaml'
$domainFile = Join-Path $Root "$Name.yaml"
$domainRel = "$Root/$Name.yaml" -replace '\\', '/'

# ensure index.yaml exists
if (-not (Test-Path $indexFile)) {
    if (-not $Project) { $Project = Split-Path -Leaf (Get-Location).Path }
    Write-ScLines $indexFile @("project: $Project", "last_updated: $(Get-ScToday)", 'domains: []')
}
$ilines = Read-ScLines $indexFile
$isec = Get-ScSection $ilines 'domains'
$registered = Get-ScItem $ilines $isec.Start $isec.End 'name' $Name

switch ($Action) {
    'add' {
        if ($registered -or (Test-Path $domainFile)) { Write-ScError "domains: '$Name' already exists" }
        Write-ScLines $domainFile @('decisions: []', 'behaviors: []')
        $item = New-ScItemLines @(
            @{ Name = 'name'; Value = $Name },
            @{ Name = 'file'; Value = $domainRel }
        )
        $ilines = Add-ScItem $ilines 'domains' $item
        $ilines = Set-ScScalar $ilines 'last_updated' (Get-ScToday)
        Write-ScLines $indexFile $ilines
        Write-Output "ok: added domain $Name"
    }
    'delete' {
        if (-not $registered -and -not (Test-Path $domainFile)) { Write-ScError "domains: '$Name' not found" }
        $removed = New-Object System.Collections.Generic.List[string]
        if (Test-Path $domainFile) {
            $dlines = Read-ScLines $domainFile
            foreach ($section in @('decisions', 'behaviors')) {
                $s = Get-ScSection $dlines $section
                if ($null -ne $s) {
                    for ($k = $s.Start; $k -lt $s.End; $k++) {
                        if ($dlines[$k] -match '^\s{2}-\s*id:\s*(.*)$') { $removed.Add("$section $((Read-ScValue $Matches[1]))") | Out-Null }
                    }
                }
            }
            Remove-Item -LiteralPath $domainFile -Force
        }
        if ($registered) {
            $ilines = Remove-ScItem $ilines 'domains' $registered.Start $registered.End
            $ilines = Set-ScScalar $ilines 'last_updated' (Get-ScToday)
            Write-ScLines $indexFile $ilines
        }
        Write-Output "ok: deleted domain $Name"
        foreach ($r in $removed) { Write-Output "  removed: $r" }
    }
}
