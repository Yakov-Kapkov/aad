#Requires -Version 5.1
<#
.SYNOPSIS
    Checks markdown files for link and text hygiene. Model-free: no docs layout
    is assumed.

.DESCRIPTION
    Output contract - one line per finding, then a summary line:
        <path> | <check> | <status>
    A clean run reports "| links | clean". Exit code is 1 on any finding.

    -Path <p>        One or more files or folders. A folder is walked for *.md.
                     Required.
    -NoFence         Flag a code fence (```).
    -NoPathToken     Flag a path-shaped token that is not a .md link.
    -Forbid <lit>    Flag a file containing the literal <lit>.

    Every markdown link on a line is resolved. Text inside a fenced code block
    or a single-line inline code span is literal and is skipped.
#>
param(
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string[]]$Path,

    [switch]$NoFence,
    [switch]$NoPathToken,
    [string]$Forbid
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $Path -or $Path.Count -eq 0) {
    Write-Output 'error=pass -Path <file-or-dir>'
    exit 1
}

$issues = 0
$pathToken = '[A-Za-z0-9_.\-]+(?:/[A-Za-z0-9_.\-]+)+\.[A-Za-z0-9]+'
$linkPattern = '\[[^\]]+\]\(([^)]+)\)'

function Report {
    param([string]$Doc, [string]$Check, [string]$Status)
    Write-Output "$Doc | $Check | $Status"
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

$docs = foreach ($item in $Path) {
    if (Test-Path -LiteralPath $item -PathType Leaf) {
        if ($item -like '*.md') { Get-Item -LiteralPath $item }
    }
    elseif (Test-Path -LiteralPath $item -PathType Container) {
        Get-ChildItem -LiteralPath $item -Recurse -Filter '*.md' -File
    }
    else {
        Write-Output "error=path not found: $item"
        exit 1
    }
}
$docs = @($docs)

foreach ($doc in $docs) {
    $dir = $doc.DirectoryName
    $number = 0
    $inFence = $false

    foreach ($line in (Get-Content -LiteralPath $doc.FullName)) {
        $number++

        $isFence = $line -match '^\s*```'
        if ($NoFence -and $isFence) {
            Report $doc.FullName "code-fence at line $number" 'violation'
        }
        # Fenced and inline code are literal text - not markdown, not links.
        if ($isFence) { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        $probe = $line -replace '`[^`]*`', ''

        foreach ($m in [regex]::Matches($probe, $linkPattern)) {
            $resolved = Resolve-Link $dir $m.Groups[1].Value
            if ($null -ne $resolved -and -not (Test-Path -LiteralPath $resolved)) {
                Report $doc.FullName "broken-link: $($m.Groups[1].Value)" 'broken'
            }
        }

        if ($NoPathToken) {
            # URLs and link syntax are navigation, not path tokens.
            $scan = $probe -replace '(https?|mailto):\S+', ''
            $scan = $scan -replace $linkPattern, ''
            foreach ($tk in [regex]::Matches($scan, $pathToken)) {
                if ($tk.Value -match '\.md$') { continue }
                Report $doc.FullName "non-doc path at line ${number}: $($tk.Value)" 'violation'
                break
            }
        }
    }

    if ($Forbid -and (Get-Content -LiteralPath $doc.FullName -Raw) -match [regex]::Escape($Forbid)) {
        Report $doc.FullName "forbidden-literal: $Forbid" 'violation'
    }
}

if ($issues -eq 0) { Write-Output "$($Path -join ', ') | links | clean" }
if ($issues -gt 0) { exit 1 }
exit 0
