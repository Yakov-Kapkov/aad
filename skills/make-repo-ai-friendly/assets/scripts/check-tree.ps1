#Requires -Version 5.1
<#
.SYNOPSIS
    Checks a docs tree for default-profile conformance.

.DESCRIPTION
    Model-bound: assumes the default profile's routing model - an `index.md`
    router per folder, every child routed by its parent's index.

    Output contract - one line per finding, then a summary line:
        <path> | <check> | <status>
    A clean run reports "| tree | clean". Exit code is 1 on any finding.

    -Root <dir>   The docs tree to check. Required.

    Duplicate-row is reported per index; orphan is reported for any .md that no
    index references.
#>
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Root
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$issues = 0
$linkPattern = '\[[^\]]+\]\(([^)]+)\)'

function Report {
    param([string]$Path, [string]$Check, [string]$Status)
    Write-Output "$Path | $Check | $Status"
    if ($Status -ne 'ok') { $script:issues++ }
}

function Resolve-Link {
    param([string]$Dir, [string]$Target)
    $clean = $Target -replace '#.*$', ''
    if ($clean -eq '') { return $null }
    if ($clean -match '://') { return $null }
    if ([System.IO.Path]::IsPathRooted($clean)) { return [System.IO.Path]::GetFullPath($clean) }
    return [System.IO.Path]::GetFullPath((Join-Path $Dir $clean))
}

if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    Write-Output "$Root | root | MISSING"
    exit 1
}

$referenced = @{}

foreach ($index in @(Get-ChildItem -LiteralPath $Root -Recurse -Filter 'index.md' -File)) {
    $dir = $index.DirectoryName
    $seen = @{}
    foreach ($line in (Get-Content -LiteralPath $index.FullName)) {
        foreach ($m in [regex]::Matches($line, $linkPattern)) {
            $target = $m.Groups[1].Value
            $resolved = Resolve-Link $dir $target
            if ($null -eq $resolved) { continue }
            if (-not (Test-Path -LiteralPath $resolved)) {
                Report $index.FullName "broken-link: $target" 'broken'
            }
            if ($seen.ContainsKey($resolved)) {
                Report $index.FullName "duplicate-row: $target" 'duplicate'
            }
            $seen[$resolved] = $true
            $referenced[$resolved] = $true
        }
    }
}

foreach ($doc in @(Get-ChildItem -LiteralPath $Root -Recurse -Filter '*.md' -File)) {
    if ($doc.Name -eq 'index.md') { continue }
    $full = [System.IO.Path]::GetFullPath($doc.FullName)
    if (-not $referenced.ContainsKey($full)) {
        Report $doc.FullName 'orphan' 'orphan'
    }
}

if ($issues -eq 0) { Write-Output "$Root | tree | clean" }
if ($issues -gt 0) { exit 1 }
exit 0
