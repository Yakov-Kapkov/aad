#Requires -Version 5.1
<#
.SYNOPSIS
    Housekeeper for the inner DEV+QA cycle - reads dev-qa-cycle-state.yaml and reports
    the single next step. Advises only; never triggers a functional agent.
.DESCRIPTION
    dev-qa-next-step -Dir <cycle-dir>

    Reads the state via dev-qa-cycle-state and prints a `NEXT -> ...` recommendation
    for the human (or a future engine) to execute. Per the housekeeper guardrail it
    MUST NOT invoke sda-dev-task / sda-dev / sda-qa-task / sda-qa or any BC agent.
#>
param(
    [string]$Dir = '.'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$cycle = Join-Path $PSScriptRoot 'dev-qa-cycle-state.ps1'
function State([string]$field) {
    $v = & powershell -NoProfile -ExecutionPolicy Bypass -File $cycle read -Dir $Dir -Field $field 2>&1
    return ($v | Out-String).Trim()
}

$status = State 'status'
if ($status -like 'error=*') { Write-Output $status; exit 1 }

$run = State 'current-run'
$folder = State 'run-folder'
$open = State 'open-failures'

Write-Output "cycle: run $run, status $status"

switch ($status) {
    'implementing' {
        $sha = State 'sha'
        if ($sha -eq 'null' -or $sha -eq '') {
            Write-Output "NEXT -> implement $folder with sda-dev, then record the commit: dev-qa-cycle-state set-sha -Sha <sha>"
        } else {
            Write-Output "NEXT -> run PRIMARY QA with sda-qa (output -> $folder), then record: dev-qa-cycle-state set-verdict -Gate primary -Verdict PASS|FAIL [-Failures ...]"
        }
    }
    'qa-regression' {
        Write-Output "PRIMARY passed. NEXT -> update the ledgers: sda-dev-context-writer (system context) + sda-qa-context-writer (test-case library)."
        Write-Output "     then run blast-radius: if pending behaviours remain, author + run regression QA (sda-qa-task regression-only -> sda-qa) and record: dev-qa-cycle-state set-verdict -Gate regression -Verdict PASS|FAIL"
        Write-Output "     if none pending, the cycle is done: dev-qa-cycle-state set-verdict -Gate regression -Verdict PASS"
    }
    'rework' {
        Write-Output "Run $run FAILED - open failures: $open"
        Write-Output "NEXT -> author a fix task from those failures with sda-dev-task, then: dev-qa-cycle-state bump-run  (and implement the new run)"
    }
    'passed' {
        Write-Output "NEXT -> none. Cycle complete - the task is verified across both gates."
    }
    default {
        Write-Output "error=dev-qa-next-step: unknown status '$status'"; exit 1
    }
}
