#Requires -Version 5.1
<#
.SYNOPSIS
    Reports file sizes for SDA unit pre-flight checks.

.DESCRIPTION
    task   mode: outputs a table of Path, Exists, Lines for informed unit splitting.
    verify mode: outputs PASS or FAIL based on whether the total line count of
               existing files exceeds the configured limit.

.PARAMETER Mode
    'task'   - print file-size table.
    'verify' - print PASS or FAIL against the limit.

.PARAMETER Paths
    Comma-delimited file paths to measure (e.g. 'file1.ts,file2.ts').

.PARAMETER Limit
    (verify mode) Maximum total lines across existing files. Default: 1000.
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet('task', 'verify')]
    [string] $Mode,

    [Parameter(Mandatory)]
    [string] $Paths,

    [int] $Limit = 1000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$pathList    = $Paths -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
$rows        = [System.Collections.Generic.List[PSCustomObject]]::new()
$totalLines  = 0
$missingList = [System.Collections.Generic.List[string]]::new()

foreach ($p in $pathList) {
    if (Test-Path -LiteralPath $p) {
        $lines = (Get-Content -LiteralPath $p | Measure-Object -Line).Lines
        $rows.Add([PSCustomObject]@{ Path = $p; Exists = $true; Lines = $lines })
        $totalLines += $lines
    }
    else {
        $rows.Add([PSCustomObject]@{ Path = $p; Exists = $false; Lines = 0 })
        $missingList.Add($p)
    }
}

switch ($Mode) {
    'task' {
        $rows | Format-Table -Property Path, Exists, Lines -AutoSize
    }
    'verify' {
        $note = if ($missingList.Count -gt 0) {
            " ($($missingList.Count) new/missing: $($missingList -join ', '))"
        }
        else { '' }

        if ($totalLines -gt $Limit) {
            Write-Output "FAIL: $totalLines lines exceeds limit $Limit${note}"
        }
        else {
            Write-Output "PASS${note}"
        }
    }
}
