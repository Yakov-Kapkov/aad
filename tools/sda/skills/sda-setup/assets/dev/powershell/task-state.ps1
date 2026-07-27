#Requires -Version 5.1
<#
.SYNOPSIS
    Manages state.json for SDA task tracking.

.DESCRIPTION
    Creates, reads, and updates state.json in a task folder.
    Handles automatic task-level status transitions.

.PARAMETER Command
    One of: init, get, next, update

.PARAMETER TaskFolder
    Path to the task folder containing (or to contain) state.json.

.PARAMETER TaskName
    (init only) Task name in kebab-case.

.PARAMETER Units
    (init only) JSON array of units: [{"name":"...", "scenarios": N}, ...]

.PARAMETER UnitNumber
    (update only) Unit number to update (1-based).

.PARAMETER State
    (update only) New state: PENDING, RED, GREEN, DONE
#>

param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('init', 'get', 'next', 'update')]
    [string] $Command,

    [Parameter(Mandatory, Position = 1)]
    [string] $TaskFolder,

    [Parameter(Position = 2)]
    [string] $TaskName,

    [Parameter(Position = 3)]
    [string] $Units,

    [Parameter(Position = 4)]
    [int] $UnitNumber,

    [Parameter(Position = 5)]
    [ValidateSet('PENDING', 'RED', 'GREEN', 'DONE')]
    [string] $State
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve task folder — accept full path or just folder name
function Resolve-TaskFolder([string]$folder) {
    # Already a valid path with state.json or task.md
    if (Test-Path (Join-Path $folder 'state.json')) { return $folder }
    if (Test-Path (Join-Path $folder 'task.md')) { return $folder }

    # Search known locations
    $candidates = @(
        ".sda/tasks/$folder"
        ".sda/backlog/$folder"
    )
    # Feature tasks: .sda/features/*/tasks/<folder>
    if (Test-Path '.sda/features') {
        Get-ChildItem '.sda/features' -Directory | ForEach-Object {
            $candidates += Join-Path $_.FullName "tasks/$folder"
        }
    }

    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }

    # Init command — folder may not exist yet, return as-is
    if ($Command -eq 'init') { return $folder }

    Write-Host "Error: Task folder '$folder' not found in .sda/tasks/, .sda/features/*/tasks/, or .sda/backlog/." -ForegroundColor Red
    exit 1
}

$TaskFolder = Resolve-TaskFolder $TaskFolder
# Anchor relative paths to PowerShell's $PWD so .NET methods resolve correctly
if (-not [System.IO.Path]::IsPathRooted($TaskFolder)) {
    $TaskFolder = Join-Path $PWD $TaskFolder
}
$StateFile = Join-Path $TaskFolder 'state.json'

function Format-Json {
    param($obj, [int]$depth = 0)
    $pad   = '  ' * $depth
    $inner = '  ' * ($depth + 1)
    if ($null -eq $obj)                                          { return 'null' }
    if ($obj -is [bool])                                         { return $obj.ToString().ToLower() }
    if ($obj -is [int] -or $obj -is [long] -or
        $obj -is [double] -or $obj -is [decimal])                { return "$obj" }
    if ($obj -is [string])                                       { return '"' + ($obj -replace '\\','\\' -replace '"','\"') + '"' }
    if ($obj -is [array] -or $obj -is [System.Collections.IList]) {
        if ($obj.Count -eq 0) { return '[]' }
        $items = $obj | ForEach-Object { "$inner$(Format-Json $_ ($depth + 1))" }
        return "[`n$($items -join ",`n")`n$pad]"
    }
    if ($obj -is [System.Collections.IDictionary]) {
        $props = @($obj.GetEnumerator())
        if ($props.Count -eq 0) { return '{}' }
        $entries = $props | ForEach-Object {
            $k = '"' + $_.Key + '"'
            $v = Format-Json $_.Value ($depth + 1)
            "$inner$k`: $v"
        }
        return "{`n$($entries -join ",`n")`n$pad}"
    }
    if ($obj -is [PSCustomObject]) {
        $props = @($obj.PSObject.Properties)
        if ($props.Count -eq 0) { return '{}' }
        $entries = $props | ForEach-Object {
            $k = '"' + $_.Name + '"'
            $v = Format-Json $_.Value ($depth + 1)
            "$inner$k`: $v"
        }
        return "{`n$($entries -join ",`n")`n$pad}"
    }
    return '"' + "$obj" + '"'
}

function Write-State($obj) {
    $json = Format-Json $obj
    [System.IO.File]::WriteAllText($StateFile, $json, [System.Text.Encoding]::UTF8)
}

function Read-State {
    if (-not (Test-Path $StateFile)) {
        Write-Host "Error: state.json not found in $TaskFolder" -ForegroundColor Red
        exit 1
    }
    Get-Content $StateFile -Raw | ConvertFrom-Json
}

function Update-TaskStatus($obj) {
    $allDone = $true
    $anyStarted = $false
    foreach ($u in $obj.units) {
        if ($u.state -ne 'DONE') { $allDone = $false }
        if ($u.state -ne 'PENDING') { $anyStarted = $true }
    }
    if ($allDone) {
        $obj.status = 'DONE'
    }
    elseif ($anyStarted) {
        $obj.status = 'IN-PROGRESS'
    }
    return $obj
}

switch ($Command) {
    'init' {
        if (-not $TaskName) {
            Write-Host "Error: TaskName is required for init command." -ForegroundColor Red
            exit 1
        }
        if (-not $Units) {
            Write-Host "Error: Units JSON is required for init command." -ForegroundColor Red
            exit 1
        }

        $unitList = $Units | ConvertFrom-Json
        $numbered = @()
        $i = 1
        foreach ($u in $unitList) {
            $num = if ($u.PSObject.Properties['number']) { [int]$u.number } else { $i }
            $numbered += [ordered]@{
                number    = $num
                name      = $u.name
                state     = 'PENDING'
                scenarios = [int]$u.scenarios
            }
            $i++
        }

        $stateObj = [ordered]@{
            task   = $TaskName
            status = 'PENDING'
            units  = $numbered
        }

        if (-not (Test-Path $TaskFolder)) {
            New-Item -ItemType Directory -Path $TaskFolder -Force | Out-Null
        }

        Write-State $stateObj
        Write-Output "state.json created: $($numbered.Count) units."
    }

    'get' {
        $obj = Read-State
        Format-Json $obj
    }

    'next' {
        $obj = Read-State
        $found = $null
        foreach ($u in $obj.units) {
            if ($u.state -ne 'DONE') {
                $found = $u
                break
            }
        }
        if ($found) {
            Format-Json $found
        }
        else {
            Write-Output '{"done": true}'
        }
    }

    'update' {
        if ($UnitNumber -lt 1) {
            Write-Host "Error: UnitNumber must be >= 1." -ForegroundColor Red
            exit 1
        }
        if (-not $State) {
            Write-Host "Error: State is required for update command." -ForegroundColor Red
            exit 1
        }

        $obj = Read-State
        $idx = -1
        for ($i = 0; $i -lt $obj.units.Count; $i++) {
            if ([int]$obj.units[$i].number -eq $UnitNumber) { $idx = $i; break }
        }
        if ($idx -eq -1) {
            Write-Host "Error: Unit $UnitNumber not found." -ForegroundColor Red
            exit 1
        }

        $target = $obj.units[$idx]

        $target.state = $State
        $obj = Update-TaskStatus $obj
        Write-State $obj
        Write-Output "Unit $UnitNumber -> $State. Task status: $($obj.status)."
    }
}
