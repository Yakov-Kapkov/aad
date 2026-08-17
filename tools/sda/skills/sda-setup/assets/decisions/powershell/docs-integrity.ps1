param(
    [Parameter(Mandatory=$true)][string]$DecisionsRoot
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $DecisionsRoot -PathType Container)) {
    Write-Host "$DecisionsRoot | decisions-root | MISSING"
    exit 1
}

$issues = 0

function Report {
    param($File, $Check, $Status)
    Write-Host "$File | $Check | $Status"
    if ($Status -ne 'ok') {
        $script:issues++
    }
}

$indexes = @(Get-ChildItem -LiteralPath $DecisionsRoot -Recurse -Filter 'index.md' -File)
$referenced = @{}

foreach ($index in $indexes) {
    $dir = $index.DirectoryName
    $seen = @{}
    $lines = Get-Content -LiteralPath $index.FullName
    foreach ($line in $lines) {
        if ($line -match '\[[^\]]+\]\(([^)]+)\)') {
            $target = $Matches[1] -replace '#.*$',''
            if ($target -eq '') { continue }
            if ($target -match '://') { continue }
            $resolved = [System.IO.Path]::GetFullPath((Join-Path $dir $target))
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

$topics = @(Get-ChildItem -LiteralPath $DecisionsRoot -Recurse -Filter '*.md' -File | Where-Object { $_.Name -ne 'index.md' })
foreach ($topic in $topics) {
    $full = [System.IO.Path]::GetFullPath($topic.FullName)
    if (-not $referenced.ContainsKey($full)) {
        Report $topic.FullName 'orphan' 'orphan'
    }
}

if ($issues -eq 0) {
    Write-Host "$DecisionsRoot | integrity | clean"
}

if ($issues -gt 0) { exit 1 }
