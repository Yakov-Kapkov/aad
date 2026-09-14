#Requires -Version 5.1
<#
.SYNOPSIS
    Manage dev-qa-cycle-state.yaml - the inner DEV+QA run-loop state (system-context
    sibling infrastructure; part of the human-orchestrated workflow layer).
.DESCRIPTION
    -Action init|read|set-sha|set-verdict|bump-run
      init        -Dir <d> -Task <name> [-Spec <path>]     create state + runs/run-01/
      read        -Dir <d> [-Field <f>]                     print state (or one field)
      set-sha     -Dir <d> -Sha <sha>                       record current run's commit
      set-verdict -Dir <d> -Gate primary|regression -Verdict PASS|FAIL [-Failures "a,b"]
      bump-run    -Dir <d> [-Spec <path>]                   advance to the next run

    Status transitions:
      init / bump-run           -> implementing
      set-verdict primary PASS  -> qa-regression   (regression gate next)
      set-verdict primary FAIL  -> rework
      set-verdict regression PASS -> passed
      set-verdict regression FAIL -> rework

    -Field one of: task | current-run | status | open-failures | spec | sha |
      verdict | failures | run-folder (runs/run-0N of the current run).

    This is the ONLY writer of dev-qa-cycle-state.yaml. On failure prints
    error=<message> and exits 1.
#>
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('init', 'read', 'set-sha', 'set-verdict', 'bump-run')][string]$Action,
    [string]$Dir = '.',
    [string]$Task,
    [string]$Spec,
    [string]$Sha,
    [ValidateSet('primary', 'regression')][string]$Gate = 'primary',
    [ValidateSet('PASS', 'FAIL')][string]$Verdict,
    [string]$Failures,
    [string]$Field
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Fail([string]$m) { Write-Output "error=$m"; exit 1 }

$stateFile = Join-Path $Dir 'dev-qa-cycle-state.yaml'

function Format-List2([string[]]$items) {
    if ($null -eq $items -or $items.Count -eq 0) { return '[]' }
    return '[' + ($items -join ', ') + ']'
}
function Parse-List2([string]$raw) {
    $t = $raw.Trim()
    if (-not ($t.StartsWith('[') -and $t.EndsWith(']'))) { return @() }
    $inner = $t.Substring(1, $t.Length - 2).Trim()
    if ($inner -eq '') { return @() }
    return @($inner -split '\s*,\s*' | Where-Object { $_ -ne '' })
}
function RunFolder([int]$n) { 'runs/run-{0:D2}' -f $n }

function Read-State {
    if (-not (Test-Path $stateFile)) { Fail "dev-qa-cycle-state: no state at $stateFile (run init first)" }
    $lines = @(Get-Content -LiteralPath $stateFile)
    $s = @{ task = ''; current = 0; status = ''; runs = New-Object System.Collections.Generic.List[hashtable]; open = @() }
    $inRuns = $false; $cur = $null
    foreach ($ln in $lines) {
        if ($ln -match '^task:\s*(.*)$') { $s.task = $Matches[1].Trim(); $inRuns = $false; continue }
        if ($ln -match '^current-run:\s*(.*)$') { $s.current = [int]$Matches[1].Trim(); $inRuns = $false; continue }
        if ($ln -match '^status:\s*(.*)$') { $s.status = $Matches[1].Trim(); $inRuns = $false; continue }
        if ($ln -match '^open-failures:\s*(.*)$') { $s.open = Parse-List2 $Matches[1]; $inRuns = $false; continue }
        if ($ln -match '^runs:\s*(\[\])?\s*$') { $inRuns = $true; continue }
        if ($inRuns -and $ln -match '^\s{2}-\s*run:\s*(.*)$') {
            $cur = @{ run = [int]$Matches[1].Trim(); spec = 'null'; sha = 'null'; verdict = 'null'; failures = @() }
            $s.runs.Add($cur); continue
        }
        if ($inRuns -and $null -ne $cur) {
            if ($ln -match '^\s{4}spec:\s*(.*)$') { $cur.spec = $Matches[1].Trim() }
            elseif ($ln -match '^\s{4}sha:\s*(.*)$') { $cur.sha = $Matches[1].Trim() }
            elseif ($ln -match '^\s{4}verdict:\s*(.*)$') { $cur.verdict = $Matches[1].Trim() }
            elseif ($ln -match '^\s{4}failures:\s*(.*)$') { $cur.failures = Parse-List2 $Matches[1] }
        }
    }
    return $s
}

function Write-State($s) {
    $out = New-Object System.Collections.Generic.List[string]
    $out.Add("task: $($s.task)")
    $out.Add("current-run: $($s.current)")
    $out.Add("status: $($s.status)")
    if ($s.runs.Count -eq 0) { $out.Add('runs: []') }
    else {
        $out.Add('runs:')
        foreach ($r in $s.runs) {
            $out.Add("  - run: $($r.run)")
            $out.Add("    spec: $($r.spec)")
            $out.Add("    sha: $($r.sha)")
            $out.Add("    verdict: $($r.verdict)")
            $out.Add("    failures: $(Format-List2 $r.failures)")
        }
    }
    $out.Add("open-failures: $(Format-List2 $s.open)")
    $text = ($out -join "`n") + "`n"
    if (-not (Test-Path $Dir)) { New-Item -ItemType Directory -Force -Path $Dir | Out-Null }
    [System.IO.File]::WriteAllText($stateFile, $text, (New-Object System.Text.UTF8Encoding($false)))
}

switch ($Action) {
    'init' {
        if (Test-Path $stateFile) { Fail "dev-qa-cycle-state: state already exists at $stateFile" }
        if (-not $Task) { Fail 'init: -Task is required' }
        $spec1 = if ($Spec) { $Spec } else { "$(RunFolder 1)/task.md" }
        $s = @{ task = $Task; current = 1; status = 'implementing'; runs = New-Object System.Collections.Generic.List[hashtable]; open = @() }
        $s.runs.Add(@{ run = 1; spec = $spec1; sha = 'null'; verdict = 'null'; failures = @() })
        New-Item -ItemType Directory -Force -Path (Join-Path $Dir (RunFolder 1)) | Out-Null
        Write-State $s
        Write-Output "ok: initialized cycle for '$Task' at run 1"
    }
    'read' {
        $s = Read-State
        $cur = $s.runs | Where-Object { $_.run -eq $s.current } | Select-Object -First 1
        if (-not $Field) { Get-Content -LiteralPath $stateFile; return }
        switch ($Field) {
            'task' { Write-Output $s.task }
            'current-run' { Write-Output $s.current }
            'status' { Write-Output $s.status }
            'open-failures' { Write-Output (Format-List2 $s.open) }
            'run-folder' { Write-Output (RunFolder $s.current) }
            'spec' { Write-Output $cur.spec }
            'sha' { Write-Output $cur.sha }
            'verdict' { Write-Output $cur.verdict }
            'failures' { Write-Output (Format-List2 $cur.failures) }
            default { Fail "read: unknown field '$Field'" }
        }
    }
    'set-sha' {
        if (-not $Sha) { Fail 'set-sha: -Sha is required' }
        $s = Read-State
        ($s.runs | Where-Object { $_.run -eq $s.current } | Select-Object -First 1).sha = $Sha
        Write-State $s
        Write-Output "ok: run $($s.current) sha=$Sha"
    }
    'set-verdict' {
        if (-not $Verdict) { Fail 'set-verdict: -Verdict is required' }
        $s = Read-State
        $cur = $s.runs | Where-Object { $_.run -eq $s.current } | Select-Object -First 1
        $cur.verdict = $Verdict
        $fails = if ($Failures) { @($Failures -split '\s*,\s*' | Where-Object { $_ -ne '' }) } else { @() }
        $cur.failures = $fails
        if ($Verdict -eq 'FAIL') { $s.status = 'rework'; $s.open = $fails }
        else { $s.status = if ($Gate -eq 'primary') { 'qa-regression' } else { 'passed' }; $s.open = @() }
        Write-State $s
        Write-Output "ok: run $($s.current) $Gate verdict=$Verdict status=$($s.status)"
    }
    'bump-run' {
        $s = Read-State
        $n = $s.current + 1
        $spec = if ($Spec) { $Spec } else { "$(RunFolder $n)/task.md" }
        $s.runs.Add(@{ run = $n; spec = $spec; sha = 'null'; verdict = 'null'; failures = @() })
        $s.current = $n; $s.status = 'implementing'; $s.open = @()
        New-Item -ItemType Directory -Force -Path (Join-Path $Dir (RunFolder $n)) | Out-Null
        Write-State $s
        Write-Output "ok: advanced to run $n"
    }
}
