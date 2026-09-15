#Requires -Version 5.1
<#
.SYNOPSIS
    Verifies the integrity of a docs tree, or of a single document.

.DESCRIPTION
    Output contract - one line per finding, then a summary line:
        <path> | <check> | <status>
    A finding carries a keyword status; a clean run reports "| integrity | clean".
    Exit code is 1 when anything is not ok.

    -Root <dir>   Docs tree. Every index link resolves, no duplicate row within
                  one index, no orphaned document, and no durable doc naming a
                  `.sda/` path (the one-way link rule).

    -File <path>  One document. Every relative link resolves, no code fence, and
                  no path token that is not a `.md` link - the design.md
                  altitude check.

    Only the first link on a line is resolved. Every document shape this checks
    keeps one link per line.
#>
param(
    [Parameter(Position = 0)]
    [Alias('DecisionsRoot')]
    [string]$Root,

    [string]$File
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$issues = 0
$pathToken = '[A-Za-z0-9_.\-]+(?:/[A-Za-z0-9_.\-]+)+\.[A-Za-z0-9]+'

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

function Test-Tree {
    param([string]$TreeRoot)

    $indexes = @(Get-ChildItem -LiteralPath $TreeRoot -Recurse -Filter 'index.md' -File)
    $referenced = @{}

    foreach ($index in $indexes) {
        $dir = $index.DirectoryName
        $seen = @{}
        foreach ($line in (Get-Content -LiteralPath $index.FullName)) {
            if ($line -match '\[[^\]]+\]\(([^)]+)\)') {
                $target = $Matches[1]
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

    foreach ($doc in @(Get-ChildItem -LiteralPath $TreeRoot -Recurse -Filter '*.md' -File)) {
        if ($doc.Name -ne 'index.md') {
            $full = [System.IO.Path]::GetFullPath($doc.FullName)
            if (-not $referenced.ContainsKey($full)) {
                Report $doc.FullName 'orphan' 'orphan'
            }
        }
        # One-way link rule: a durable doc never names a transient .sda path.
        if ((Get-Content -LiteralPath $doc.FullName -Raw) -match '\.sda/') {
            Report $doc.FullName 'sda-reference' 'violation'
        }
    }
}

function Test-SingleFile {
    param([string]$Path)

    $dir = Split-Path -Parent ([System.IO.Path]::GetFullPath($Path))
    $seen = @{}
    $number = 0

    foreach ($line in (Get-Content -LiteralPath $Path)) {
        $number++

        if ($line -match '^\s*```') {
            Report $Path "code-fence at line $number" 'violation'
        }

        # URLs and link syntax are navigation, not altitude violations.
        $scan = $line -replace '(https?|mailto):\S+', ''
        $scan = $scan -replace '\[[^\]]+\]\([^)]+\)', ''

        if ($line -match '\[[^\]]+\]\(([^)]+)\)') {
            $target = $Matches[1]
            $resolved = Resolve-Link $dir $target
            if ($null -ne $resolved) {
                if (-not (Test-Path -LiteralPath $resolved)) {
                    Report $Path "broken-link: $target" 'broken'
                }
                if ($seen.ContainsKey($resolved)) {
                    Report $Path "duplicate-link: $target" 'duplicate'
                }
                $seen[$resolved] = $true
            }
        }

        foreach ($match in [regex]::Matches($scan, $pathToken)) {
            if ($match.Value -match '\.md$') { continue }
            Report $Path "non-doc path at line ${number}: $($match.Value)" 'violation'
            break
        }
    }
}

if ($Root -and $File) {
    Write-Output 'error=pass either -Root or -File, not both'
    exit 1
}
if (-not $Root -and -not $File) {
    Write-Output 'error=pass -Root <dir> (docs tree) or -File <path> (one document)'
    exit 1
}

if ($File) {
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        Write-Output "$File | file | MISSING"
        exit 1
    }
    Test-SingleFile $File
    if ($issues -eq 0) { Write-Output "$File | integrity | clean" }
} else {
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        Write-Output "$Root | root | MISSING"
        exit 1
    }
    Test-Tree $Root
    if ($issues -eq 0) { Write-Output "$Root | integrity | clean" }
}

if ($issues -gt 0) { exit 1 }
exit 0
