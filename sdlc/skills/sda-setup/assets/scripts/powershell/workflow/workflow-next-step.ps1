#Requires -Version 5.1
<#
.SYNOPSIS
    Housekeeper for the outer SDLC workflow - reads workflow-state.yaml and reports the
    single next BC action. Advises only; never triggers a functional agent.
.DESCRIPTION
    workflow-next-step -Dir <workflow-dir>

    Reads state via workflow-state and prints a `NEXT -> ...` recommendation for the
    human (or a future engine) to execute. Per the housekeeper guardrail it MUST NOT
    invoke sda-ba / sda-system / sda-feature / sda-dev-task / sda-dev / sda-qa-task /
    sda-qa or any BC agent - bookkeeping and "here is what is next" only.
#>
param(
    [string]$Dir = '.'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$state = Join-Path $PSScriptRoot 'workflow-state.ps1'
function State([string]$field) {
    $v = & powershell -NoProfile -ExecutionPolicy Bypass -File $state read -Dir $Dir -Field $field 2>&1
    return ($v | Out-String).Trim()
}

$cur = State 'current-bc'
if ($cur -like 'error=*') { Write-Output $cur; exit 1 }
$branch = State 'branch'
Write-Output "workflow: current-bc $cur, branch $branch"

switch ($cur) {
    'BA' {
        $o = State 'output.ba'
        Write-Output "NEXT -> invoke sda-ba with the requirement. output -> $o"
        Write-Output "     then record: workflow-state update -Bc BA -Status done -Ledger done"
    }
    'DESIGN' {
        $ba = State 'output.ba'; $o = State 'output.design'
        Write-Output "NEXT -> invoke sda-system / sda-feature with the User Story ($ba). output -> $o (staged in the pending overlay)."
        Write-Output "     then record: workflow-state update -Bc DESIGN -Status done -Ledger done"
    }
    'DEV' {
        Write-Output "DEV+QA span. NEXT -> author DEV/task.md (sda-dev-task) + QA/qa-task.md (sda-qa-task), then drive the inner cycle with dev-qa-next-step in DEV/."
        Write-Output "     when the inner cycle status is 'passed', record the span: workflow-state update -Bc DEV -Status done -Ledger done ; workflow-state update -Bc QA -Status done -Ledger done"
    }
    'QA' {
        $o = State 'output.qa'
        Write-Output "NEXT -> QA pending. If the inner DEV+QA cycle passed, record: workflow-state update -Bc QA -Status done -Ledger done."
        Write-Output "     for standalone QA, run sda-qa against $o first."
    }
    'DEP' {
        $o = State 'output.dep'
        Write-Output "NEXT -> run the DEP step (deployment context). output -> $o"
        Write-Output "     then record: workflow-state update -Bc DEP -Status done -Ledger done"
    }
    'done' {
        $pending = @()
        foreach ($k in @('ba', 'design', 'dev', 'qa', 'dep')) { if ((State "ledger.$k") -ne 'done') { $pending += $k } }
        if ($pending.Count -eq 0) {
            Write-Output "NEXT -> all BCs + ledgers done. Human merge of $branch to complete the story."
        }
        else {
            Write-Output "current-bc done, but ledgers pending: $($pending -join ', '). Resolve before merge."
        }
    }
    default {
        Write-Output "error=workflow-next-step: unknown current-bc '$cur'"; exit 1
    }
}
