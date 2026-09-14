#Requires -Version 5.1
<#
.SYNOPSIS
    Manage workflow-state.yaml - the outer SDLC-workflow state for one User Story
    across BA -> DESIGN -> DEV -> QA -> DEP (human-orchestrated workflow layer).
.DESCRIPTION
    -Action init|read|update|escalate

      init     -Dir <d> -Id <id> [-Branch <b>] [-UserStory <path>]
               create workflow-state.yaml + per-BC subfolders (BA DESIGN DEV QA DEP)

      read     -Dir <d> [-Field <f>]
               print state (or one field)

      update   -Dir <d> -Bc BA|DESIGN|DEV|QA|DEP [-Output <path>]
               [-Status pending|active|done|escalated] [-Ledger pending|done]
               record a BC's output + status, set its ledger, advance current-bc

      escalate -Dir <d> -From <bc> -To <bc> [-Reason <text>]
               append a backward send; rewind current-bc to the target

    Advance order: BA -> DESIGN -> DEV -> QA -> DEP -> done (current-bc becomes the
    next non-done BC after an update marks one done).

    -Field one of: workflow-id | user-story | current-bc | branch |
      status.<bc> | output.<bc> | ledger.<bc>   (bc lower-case: ba|design|dev|qa|dep)

    Pure state + folder manager: never runs git and never triggers an agent. This is
    the ONLY writer of workflow-state.yaml. On failure prints error=<message>, exits 1.
#>
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('init', 'read', 'update', 'escalate')][string]$Action,
    [string]$Dir = '.',
    [string]$Id,
    [string]$Branch,
    [string]$UserStory,
    [ValidateSet('BA', 'DESIGN', 'DEV', 'QA', 'DEP')][string]$Bc,
    [string]$Output,
    [ValidateSet('pending', 'active', 'done', 'escalated')][string]$Status,
    [ValidateSet('pending', 'done')][string]$Ledger,
    [string]$From,
    [string]$To,
    [string]$Reason,
    [string]$Field
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Fail([string]$m) { Write-Output "error=$m"; exit 1 }

$stateFile = Join-Path $Dir 'workflow-state.yaml'

# --- domain vocabulary (single source of truth). The [ValidateSet(...)] attributes
#     and the -match regex patterns must stay string literals - the language forbids
#     variables there - so those are the only places these values are repeated. ---
$Order       = @('BA', 'DESIGN', 'DEV', 'QA', 'DEP')                 # BC advance order
$LedgerKeys  = @($Order | ForEach-Object { $_.ToLowerInvariant() })  # ledger keys = lower(BC)
$FirstBc     = $Order[0]
$BcDone      = 'done'          # terminal current-bc (all BCs complete)
$DevCycle    = 'DEV/dev-qa-cycle-state.yaml'
$StPending   = 'pending'
$StActive    = 'active'
$StDone      = 'done'
$StEscalated = 'escalated'
$OutputPaths = [ordered]@{
    BA = 'BA/user-story.md'; DESIGN = 'DESIGN/design-delta.md'; DEV = 'DEV/task.md'
    QA = 'QA/qa-task.md'; DEP = 'DEP/'
}
function OutputFor([string]$bc) { $OutputPaths[$bc] }

function Read-State {
    if (-not (Test-Path $stateFile)) { Fail "workflow-state: no state at $stateFile (run init first)" }
    $lines = @(Get-Content -LiteralPath $stateFile)
    $s = @{
        id = ''; story = ''; current = ''; branch = ''
        bcs = [ordered]@{}; escalations = New-Object System.Collections.Generic.List[hashtable]
        ledgers = [ordered]@{}
    }
    foreach ($bc in $Order) { $s.bcs[$bc] = @{ status = $StPending; output = (OutputFor $bc); cycle = '' } }
    foreach ($k in $LedgerKeys) { $s.ledgers[$k] = $StPending }
    $section = ''; $curBc = ''; $curEsc = $null
    foreach ($ln in $lines) {
        if ($ln -match '^workflow-id:\s*(.*)$') { $s.id = $Matches[1].Trim(); $section = ''; continue }
        if ($ln -match '^user-story:\s*(.*)$') { $s.story = $Matches[1].Trim(); $section = ''; continue }
        if ($ln -match '^current-bc:\s*(.*)$') { $s.current = $Matches[1].Trim(); $section = ''; continue }
        if ($ln -match '^branch:\s*(.*)$') { $s.branch = $Matches[1].Trim(); $section = ''; continue }
        if ($ln -match '^bcs:\s*$') { $section = 'bcs'; continue }
        if ($ln -match '^escalations:\s*(\[\])?\s*$') { $section = 'esc'; continue }
        if ($ln -match '^ledgers:\s*$') { $section = 'ledgers'; continue }
        if ($section -eq 'bcs') {
            if ($ln -match '^\s{2}-\s*bc:\s*(.*)$') { $curBc = $Matches[1].Trim(); continue }
            if ($curBc -and $ln -match '^\s{4}status:\s*(.*)$') { $s.bcs[$curBc].status = $Matches[1].Trim(); continue }
            if ($curBc -and $ln -match '^\s{4}output:\s*(.*)$') { $s.bcs[$curBc].output = $Matches[1].Trim(); continue }
            if ($curBc -and $ln -match '^\s{4}cycle:\s*(.*)$') { $s.bcs[$curBc].cycle = $Matches[1].Trim(); continue }
        }
        elseif ($section -eq 'esc') {
            if ($ln -match '^\s{2}-\s*from:\s*(.*)$') { $curEsc = @{ from = $Matches[1].Trim(); to = ''; reason = '' }; $s.escalations.Add($curEsc); continue }
            if ($null -ne $curEsc -and $ln -match '^\s{4}to:\s*(.*)$') { $curEsc.to = $Matches[1].Trim(); continue }
            if ($null -ne $curEsc -and $ln -match '^\s{4}reason:\s*(.*)$') { $curEsc.reason = $Matches[1].Trim(); continue }
        }
        elseif ($section -eq 'ledgers') {
            if ($ln -match '^\s{2}([a-z]+):\s*(.*)$') { $s.ledgers[$Matches[1]] = $Matches[2].Trim() }
        }
    }
    return $s
}

function Write-State($s) {
    $out = New-Object System.Collections.Generic.List[string]
    $out.Add("workflow-id: $($s.id)")
    $out.Add("user-story: $($s.story)")
    $out.Add("current-bc: $($s.current)")
    $out.Add("branch: $($s.branch)")
    $out.Add('bcs:')
    foreach ($bc in $Order) {
        $b = $s.bcs[$bc]
        $out.Add("  - bc: $bc")
        $out.Add("    status: $($b.status)")
        $out.Add("    output: $($b.output)")
        if ($b.cycle) { $out.Add("    cycle: $($b.cycle)") }
    }
    if ($s.escalations.Count -eq 0) { $out.Add('escalations: []') }
    else {
        $out.Add('escalations:')
        foreach ($e in $s.escalations) {
            $out.Add("  - from: $($e.from)")
            $out.Add("    to: $($e.to)")
            $out.Add("    reason: $($e.reason)")
        }
    }
    $out.Add('ledgers:')
    foreach ($k in $LedgerKeys) { $out.Add("  ${k}: $($s.ledgers[$k])") }
    $text = ($out -join "`n") + "`n"
    if (-not (Test-Path $Dir)) { New-Item -ItemType Directory -Force -Path $Dir | Out-Null }
    [System.IO.File]::WriteAllText($stateFile, $text, (New-Object System.Text.UTF8Encoding($false)))
}

function Advance($s) {
    # current-bc becomes the first BC in order whose status is not done; else $BcDone.
    foreach ($bc in $Order) { if ($s.bcs[$bc].status -ne $StDone) { return $bc } }
    return $BcDone
}

switch ($Action) {
    'init' {
        if (Test-Path $stateFile) { Fail "workflow-state: state already exists at $stateFile" }
        if (-not $Id) { Fail 'init: -Id is required' }
        $story = if ($UserStory) { $UserStory } else { $OutputPaths[$FirstBc] }
        $br = if ($Branch) { $Branch } else { "story/$Id" }
        $s = @{
            id = $Id; story = $story
            current = $FirstBc; branch = $br
            bcs = [ordered]@{}; escalations = New-Object System.Collections.Generic.List[hashtable]
            ledgers = [ordered]@{}
        }
        foreach ($bc in $Order) { $s.bcs[$bc] = @{ status = $StPending; output = (OutputFor $bc); cycle = '' } }
        $s.bcs[$FirstBc].status = $StActive
        $s.bcs['DEV'].cycle = $DevCycle
        foreach ($k in $LedgerKeys) { $s.ledgers[$k] = $StPending }
        foreach ($bc in $Order) { New-Item -ItemType Directory -Force -Path (Join-Path $Dir $bc) | Out-Null }
        Write-State $s
        Write-Output "ok: initialized workflow '$Id' (branch $($s.branch)) at BA"
    }
    'read' {
        $s = Read-State
        if (-not $Field) { Get-Content -LiteralPath $stateFile; return }
        if ($Field -match '^(status|output|ledger)\.([a-z]+)$') {
            $kind = $Matches[1]; $key = $Matches[2]
            switch ($kind) {
                'status' { $bc = $key.ToUpper(); if (-not $s.bcs.Contains($bc)) { Fail "read: unknown bc '$key'" }; Write-Output $s.bcs[$bc].status }
                'output' { $bc = $key.ToUpper(); if (-not $s.bcs.Contains($bc)) { Fail "read: unknown bc '$key'" }; Write-Output $s.bcs[$bc].output }
                'ledger' { if (-not $s.ledgers.Contains($key)) { Fail "read: unknown ledger '$key'" }; Write-Output $s.ledgers[$key] }
            }
            return
        }
        switch ($Field) {
            'workflow-id' { Write-Output $s.id }
            'user-story' { Write-Output $s.story }
            'current-bc' { Write-Output $s.current }
            'branch' { Write-Output $s.branch }
            default { Fail "read: unknown field '$Field'" }
        }
    }
    'update' {
        if (-not $Bc) { Fail 'update: -Bc is required' }
        $s = Read-State
        if ($Output) { $s.bcs[$Bc].output = $Output }
        if ($Status) { $s.bcs[$Bc].status = $Status }
        if ($Ledger) { $s.ledgers[$Bc.ToLower()] = $Ledger }
        $s.current = Advance $s
        Write-State $s
        Write-Output "ok: $Bc updated; current-bc=$($s.current)"
    }
    'escalate' {
        if (-not $From) { Fail 'escalate: -From is required' }
        if (-not $To) { Fail 'escalate: -To is required' }
        $s = Read-State
        $fromU = $From.ToUpper(); $toU = $To.ToUpper()
        if ($Order -notcontains $fromU) { Fail "escalate: unknown -From '$From'" }
        if ($Order -notcontains $toU) { Fail "escalate: unknown -To '$To'" }
        $escReason = if ($Reason) { $Reason } else { '' }
        $s.escalations.Add(@{ from = $fromU; to = $toU; reason = $escReason })
        $s.bcs[$fromU].status = $StEscalated
        $s.bcs[$toU].status = $StActive
        $s.current = $toU
        Write-State $s
        Write-Output "ok: escalated $fromU -> $toU; current-bc=$toU"
    }
}
