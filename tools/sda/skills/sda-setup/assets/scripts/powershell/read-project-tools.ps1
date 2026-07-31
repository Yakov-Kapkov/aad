param(
    [Parameter(Mandatory=$true)][string]$Folder,
    [string]$Commands = 'test-path,type-path,format-code-path,filter-tool,validate'
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$toolsFile = '.sda/project-tools.md'

if (-not (Test-Path $toolsFile)) {
    Write-Output "error=Project not initialized. Run 'setup sda tool' to scaffold project tooling."
    exit 1
}

$requestedCmds = @($Commands -split ',') | ForEach-Object { $_.Trim().ToLower() }
$allLines = Get-Content $toolsFile

function Normalize-FolderPath([string]$p) {
    $p = $p.Trim().Replace('\', '/')
    if ($p -in @('.', './', '')) { return '' }
    return ($p -replace '^\./', '').TrimEnd('/')
}

function Test-SegmentPrefix([string]$prefix, [string]$folder) {
    if ($prefix -eq '') { return $true }
    $ps = $prefix -split '/'
    $fs = $folder -split '/'
    if ($ps.Count -gt $fs.Count) { return $false }
    for ($i = 0; $i -lt $ps.Count; $i++) {
        if ($ps[$i] -ne $fs[$i]) { return $false }
    }
    return $true
}

function Get-CommandByLabel([string[]]$srcLines, [string]$label) {
    $inBlock  = $false
    $wantNext = $false
    foreach ($line in $srcLines) {
        if ($line -match '^```') { $inBlock = -not $inBlock; $wantNext = $false; continue }
        if (-not $inBlock) { continue }
        if ($line -match "^#\s+$([regex]::Escape($label))(\s|$)") { $wantNext = $true; continue }
        if ($wantNext) {
            if ($line.Trim() -eq '') { continue }
            if ($line -match '^#') { $wantNext = $false; continue }
            return $line.Trim()
        }
    }
    return $null
}

# Parse area blocks (## headings, skipping non-area ones)
$skipHeadings = @('Area Index', 'Validators', 'Output Filter Command', 'Pre-Commit Checks')
$areas = [System.Collections.Generic.List[hashtable]]::new()
$curArea = $null

foreach ($line in $allLines) {
    if ($line -match '^## (.+)$') {
        $heading = $matches[1].Trim()
        if ($curArea) { $areas.Add($curArea) }
        if ($heading -in $skipHeadings) { $curArea = $null; continue }
        $curArea = @{ Name = $heading; WorkDir = ''; Lines = [System.Collections.Generic.List[string]]::new() }
        continue
    }
    if ($curArea) {
        $curArea.Lines.Add($line)
        if ($line -match '^\*\*Working directory:\*\*\s+`(.+)`') {
            $curArea.WorkDir = Normalize-FolderPath $matches[1]
        }
    }
}
if ($curArea) { $areas.Add($curArea) }

if ($areas.Count -eq 0) {
    Write-Output "error=No area blocks found in project-tools.md. Re-run sda-toolscan."
    exit 1
}

# Find best-matching area (longest prefix match)
$normFolder = Normalize-FolderPath $Folder
$bestArea = $null
$bestLen  = -1

foreach ($area in $areas) {
    if (Test-SegmentPrefix $area.WorkDir $normFolder) {
        $len = $area.WorkDir.Length
        if ($len -gt $bestLen) { $bestLen = $len; $bestArea = $area }
    }
}

# Fallback: root area
if (-not $bestArea) {
    $bestArea = $areas | Where-Object { $_.WorkDir -eq '' } | Select-Object -First 1
}

if (-not $bestArea) {
    Write-Output "error=No area matches folder '$Folder'. Check Working directory entries in project-tools.md."
    exit 1
}

$out = [System.Collections.Generic.List[string]]::new()
$wd  = if ($bestArea.WorkDir -eq '') { './' } else { "$($bestArea.WorkDir)/" }
$out.Add("working-dir=$wd")

$areaArr = $bestArea.Lines.ToArray()
$allArr  = $allLines

# Area-scoped command names (label name = command name — looked up directly)
$areaCommands = @(
    'test-path','test-path-coverage','test-all',
    'type-path','type-all',
    'lint-path','lint-all',
    'format-code-path',
    'app-run-start','app-run-url','app-run-healthcheck'
)
foreach ($cmd in $requestedCmds) {
    if ($cmd -in $areaCommands) {
        $v = Get-CommandByLabel $areaArr $cmd
        if ($v) { $out.Add("$cmd=$v") }
    }
}

# Global: shell
if ('shell' -in $requestedCmds) {
    $shellLine = $allArr | Where-Object { $_ -match '^\*\*Detected shell:\*\*\s+(.+)$' } | Select-Object -First 1
    if ($shellLine -match '^\*\*Detected shell:\*\*\s+(.+)$') {
        $out.Add("shell=$($matches[1].Trim())")
    }
}

# Global: filter-tool
if ('filter-tool' -in $requestedCmds) {
    $v = Get-CommandByLabel $allArr 'filter-last-n'
    if ($v) { $out.Add("filter-tool=$v") }
}

# Global: validate-*-path labels
if ('validate' -in $requestedCmds) {
    foreach ($lbl in @('validate-json-path','validate-yaml-path','validate-xml-path','validate-toml-path')) {
        $v = Get-CommandByLabel $allArr $lbl
        if ($v) { $out.Add("$lbl=$v") }
    }
}

# Global: pre-commit commands
foreach ($lbl in @('precommit-all','precommit-staged')) {
    if ($lbl -in $requestedCmds) {
        $v = Get-CommandByLabel $allArr $lbl
        if ($v) { $out.Add("$lbl=$v") }
    }
}

# Global: areas (Area Index listing — all area names, working directories, and per-area global capabilities)
if ('areas' -in $requestedCmds) {
    $capLabels = @('type-all','test-all','lint-all','build-all','precommit-all')
    foreach ($area in $areas) {
        $wd = if ($area.WorkDir -eq '') { './' } else { "$($area.WorkDir)/" }
        $out.Add("area.$($area.Name)=$wd")
        $areaArr = $area.Lines.ToArray()
        $caps = [System.Collections.Generic.List[string]]::new()
        foreach ($lbl in $capLabels) {
            $v = Get-CommandByLabel $areaArr $lbl
            if ($v) { $caps.Add($lbl) }
        }
        if ($caps.Count -gt 0) {
            $out.Add("area.$($area.Name).capabilities=$($caps -join ',')")
        }
    }
}

Write-Output ($out -join "`n")
