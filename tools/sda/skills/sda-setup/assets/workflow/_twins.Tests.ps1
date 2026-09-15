#Requires -Version 5.1
<#
.SYNOPSIS
    Differential test harness for the two workflow state-script twins.

.DESCRIPTION
    Runs one scenario sequence against workflow.ps1 and workflow.sh in separate
    temp roots and compares stdout, stderr, exit code, and the resulting
    workflow.json. Any difference is a bug in one of the twins.

    Development-only: tests are named '_<subject>.Tests.ps1' and sit beside the
    code they test. They never ship - the skill installers prune them from the
    installed copy, and none is copied into a project's .sda/.

    Every step is declared once, in bash flag syntax; the PowerShell arguments
    are derived (--slug -> -Slug). '@ROOT' expands to the container root.

    Coverage: the stage machine and its artifact gate; the escalation brief gate
    (missing, absent, outside escalations/); --to jumps; derived open-ness; LIFO
    unwind; resolve advancing exactly one stage; brief=- on a pre-brief state;
    and CLI misuse.

    Run from anywhere:  powershell -NoProfile -File _twins.Tests.ps1
    Exit code 0 = twins agree; 1 = divergences (transcripts kept for inspection).

    Scratch: .test-scratch/workflow-twins/ - the shared, gitignored test scratch
    root. This test creates and removes only its own subfolder.
#>
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptDir = $PSScriptRoot
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir '..\..\..\..\..\..')).Path
$PsTwin    = Join-Path $ScriptDir 'powershell\workflow.ps1'
$ShTwin    = Join-Path $ScriptDir 'bash\workflow.sh'
$Bash      = 'C:\Program Files\Git\bin\bash.exe'
if (-not (Test-Path $Bash)) {
    $onPath = Get-Command bash -ErrorAction SilentlyContinue
    if ($null -eq $onPath) {
        Write-Output 'SKIP: Git Bash not found - the bash twin cannot be tested on this machine.'
        exit 0
    }
    $Bash = $onPath.Source
}

foreach ($f in @($PsTwin, $ShTwin, $Bash)) {
    if (-not (Test-Path $f)) { throw "missing: $f" }
}

# Tests that write files use one shared scratch root, with a subfolder per
# test. Only this test's own subfolder is ever created or removed.
$ScratchRoot = Join-Path $RepoRoot '.test-scratch'
$Work        = Join-Path $ScratchRoot 'workflow-twins'
if (Test-Path $Work) { Remove-Item -Recurse -Force $Work }
$PsRoot = Join-Path $Work 'ps\wf'
$ShRoot = Join-Path $Work 'sh\wf'
New-Item -ItemType Directory -Force -Path $PsRoot, $ShRoot | Out-Null

function ConvertTo-Posix([string]$p) {
    $d = $p.Substring(0, 1).ToLower()
    return '/' + $d + '/' + ((($p.Substring(3)) -replace '\\', '/'))
}
$ShRootPosix = ConvertTo-Posix $ShRoot
$ShTwinPosix = ConvertTo-Posix $ShTwin

# The twins default to <cwd>/.sda/workflows, so fixtures go there too.
$SubRel  = '.sda/workflows'
$PsCont  = Join-Path $PsRoot ($SubRel -replace '/', '\')
$ShContP = "$ShRootPosix/$SubRel"

$PsLog = New-Object System.Collections.Generic.List[string]
$ShLog = New-Object System.Collections.Generic.List[string]
$expect = New-Object System.Collections.Generic.List[string]

function Expand-Token([string]$token, [bool]$posix) {
    if ($token -notmatch '@ROOT') { return $token }
    # Relative brief paths are what callers actually pass, and they save the
    # comparison from reconciling two absolute-path syntaxes.
    if ($posix) { return ($token -replace '@ROOT', $SubRel) }
    return ($token -replace '@ROOT', $SubRel) -replace '/', '\'
}

# Windows argv quoting, so paths with spaces survive intact.
function Quote-Arg([string]$a) {
    if ($a -eq '') { return '""' }
    if ($a -notmatch '[\s"]') { return $a }
    $b = $a -replace '(\\*)"', '$1$1\"'
    $b = $b -replace '(\\+)$', '$1$1'
    return '"' + $b + '"'
}

# Direct process redirection: PS 5.1 turns a native command's stderr into a
# terminating NativeCommandError under $ErrorActionPreference='Stop'.
function Run-Process([string]$exe, [string[]]$argv, [string]$cwd) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $exe
    $psi.WorkingDirectory       = $cwd
    $psi.UseShellExecute        = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.CreateNoWindow         = $true
    $psi.Arguments              = (($argv | ForEach-Object { Quote-Arg $_ }) -join ' ')

    $p = [System.Diagnostics.Process]::Start($psi)
    $o = $p.StandardOutput.ReadToEndAsync()
    $e = $p.StandardError.ReadToEndAsync()
    # A parameter-binding prompt would block forever, so cap the wait.
    $done = $p.WaitForExit(30000)
    if (-not $done) {
        try { $p.Kill() } catch { }
        return @{ out = '<TIMEOUT: process did not exit in 30s>'; code = -99 }
    }
    $text = $o.Result
    if ($e.Result) { $text += "`n[stderr] $($e.Result)" }
    return @{ out = $text; code = $p.ExitCode }
}

function Invoke-Twin([string[]]$tokens, [bool]$posix) {
    if ($posix) {
        $parts = foreach ($t in $tokens) { "'" + (Expand-Token $t $true) + "'" }
        $cmd   = "cd '$ShRootPosix' && bash '$ShTwinPosix' " + ($parts -join ' ')
        return Run-Process $Bash @('-c', $cmd) $ShRoot
    }
    $argv = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PsTwin)
    for ($i = 0; $i -lt $tokens.Count; $i++) {
        $t = $tokens[$i]
        if ($t.StartsWith('--')) {
            $argv += ('-' + $t.Substring(2, 1).ToUpper() + $t.Substring(3))
            $i++
            $argv += (Expand-Token $tokens[$i] $false)
        } else {
            $argv += (Expand-Token $t $false)
        }
    }
    return Run-Process 'powershell.exe' $argv $PsRoot
}

function Normalize([string]$text, [bool]$posix) {
    $t = $text
    $t = $t -replace "`r`n", "`n"
    $t = $t -replace "`r", "`n"
    # JSON escapes each backslash; undo that before comparing path syntax.
    $t = $t.Replace('\\', '\')
    # Both separator styles are valid on Windows; compare paths, not syntax.
    $t = $t.Replace('\', '/')
    if ($posix) {
        $t = $t.Replace($ShContP, $SubRel)
        $t = $t.Replace($ShRootPosix, '<CWD>')
    } else {
        $t = $t.Replace(($PsCont -replace '\\', '/'), $SubRel)
        $t = $t.Replace(($PsRoot -replace '\\', '/'), '<CWD>')
    }
    $t = $t.Replace(($Work -replace '\\', '/'), '<SCRATCH>')
    $t = $t -replace '[ \t]+$', ''
    return $t.TrimEnd("`r", "`n")
}

function Add-Block($log, [string]$id, [string]$label, [string]$body) {
    $log.Add("### $id  $label")
    $log.Add($body)
    $log.Add('')
}

# The bash twin needs jq; without it every bash step fails for the same reason.
$jqProbe = Run-Process $Bash @('-c', 'command -v jq') $ShRoot
if ($jqProbe.code -ne 0) {
    Remove-Item -Recurse -Force $Work
    Write-Output 'SKIP: jq not found on the bash PATH - the bash twin cannot run.'
    exit 0
}

$steps = @(
    @{ id = 'S01'; label = 'list on an empty root';               args = @('list') }
    @{ id = 'S02'; label = 'init: happy path';                    args = @('init', '--slug', 'alpha') }
    @{ id = 'S03'; label = 'init: uppercase slug refused';        args = @('init', '--slug', 'Beta') }
    @{ id = 'S04'; label = 'init: double hyphen refused';         args = @('init', '--slug', 'a--b') }
    @{ id = 'S05'; label = 'init: duplicate slug refused';        args = @('init', '--slug', 'alpha') }
    @{ id = 'S06'; label = 'init: second container numbers 002';  args = @('init', '--slug', 'beta') }
    @{ id = 'S07'; label = 'list: two containers, no escalation'; args = @('list') }
    @{ id = 'S08'; label = 'current 001';                         args = @('current', '--slug', '001') }
    @{ id = 'S09'; label = 'current 002 by slug';                 args = @('current', '--slug', 'beta') }
    @{ id = 'S10'; label = 'advance: story artifact absent';      args = @('advance', '--slug', '001') }
    @{ id = 'S11'; label = 'read: one field';                     args = @('read', '--slug', '001', '--field', 'stage') }
    @{ id = 'S12'; label = 'read: empty notes';                   args = @('read', '--slug', '001', '--field', 'notes') }
    @{ id = 'S13'; label = 'read: whole state';                   args = @('read', '--slug', '001') }
    @{ id = 'S14'; label = 'read: unknown field refused';         args = @('read', '--slug', '001', '--field', 'bogus') }
    @{ id = 'S15'; label = 'read: unknown folder refused';        args = @('read', '--slug', '999') }
    @{ id = 'S16'; label = 'fixture: 001/user-story.md';          fs = '001. alpha/user-story.md' }
    @{ id = 'S17'; label = 'advance: story -> design';            args = @('advance', '--slug', '001') }
    @{ id = 'S18'; label = 'current: design, gap design';         args = @('current', '--slug', '001') }
    @{ id = 'S19'; label = 'advance: design artifact absent';     args = @('advance', '--slug', '001') }
    @{ id = 'S20'; label = 'fixture: 001/design.md';              fs = '001. alpha/design.md' }
    @{ id = 'S21'; label = 'advance: design -> tasks';            args = @('advance', '--slug', '001') }
    @{ id = 'S22'; label = 'advance: tasks/ is empty';            args = @('advance', '--slug', '001') }
    @{ id = 'S23'; label = 'fixture: 001/tasks/001. ui/task.md';  fs = '001. alpha/tasks/001. ui/task.md' }
    @{ id = 'S24'; label = 'advance: tasks -> ready';             args = @('advance', '--slug', '001') }
    @{ id = 'S25'; label = 'advance: already at ready';           args = @('advance', '--slug', '001') }
    @{ id = 'S26'; label = 'current: ready, no gaps';             args = @('current', '--slug', '001') }
    @{ id = 'S27'; label = 'escalate from story refused';         args = @('escalate', '--slug', '002', '--reason', 'r', '--brief', '@ROOT/002. beta/escalations/001. x.md') }
    @{ id = 'S28'; label = 'escalate: brief outside refused';     args = @('escalate', '--slug', '001', '--reason', 'r', '--brief', '@ROOT/002. beta/escalations/001. x.md') }
    @{ id = 'S29'; label = 'escalate: brief absent refused';      args = @('escalate', '--slug', '001', '--reason', 'r', '--brief', '@ROOT/001. alpha/escalations/999. nope.md') }
    @{ id = 'S30'; label = 'escalate: no brief refused';          args = @('escalate', '--slug', '001', '--reason', 'r') }
    @{ id = 'S31'; label = 'escalate: no reason refused';         args = @('escalate', '--slug', '001', '--brief', '@ROOT/001. alpha/user-story.md') }
    @{ id = 'S32'; label = 'fixture: escalation brief';           fs = '001. alpha/escalations/001. fig.md' }
    @{ id = 'S33'; label = 'escalate: --to current stage';        args = @('escalate', '--slug', '001', '--to', 'ready', '--reason', 'r', '--brief', '@ROOT/001. alpha/escalations/001. fig.md') }
    @{ id = 'S34'; label = 'escalate: ready -> design (--to)';    args = @('escalate', '--slug', '001', '--to', 'design', '--reason', 'outbox assumption broken', '--brief', '@ROOT/001. alpha/escalations/001. fig.md') }
    @{ id = 'S35'; label = 'current: escalation block';           args = @('current', '--slug', '001') }
    @{ id = 'S36'; label = 'list: escalation marked';             args = @('list') }
    @{ id = 'S37'; label = 'advance blocked while open';          args = @('advance', '--slug', '001') }
    @{ id = 'S38'; label = 'fixture: second brief';               fs = '001. alpha/escalations/002. fig.md' }
    @{ id = 'S39'; label = 'escalate: default one stage back';    args = @('escalate', '--slug', '001', '--reason', 'second', '--brief', '@ROOT/001. alpha/escalations/002. fig.md') }
    @{ id = 'S40'; label = 'current: deepest is E2';              args = @('current', '--slug', '001') }
    @{ id = 'S41'; label = 'resolve: not the deepest refused';    args = @('resolve', '--slug', '001', '--id', 'E1', '--report', 'x') }
    @{ id = 'S42'; label = 'resolve: unknown id refused';         args = @('resolve', '--slug', '001', '--id', 'E9', '--report', 'x') }
    @{ id = 'S43'; label = 'resolve: no report refused';          args = @('resolve', '--slug', '001', '--id', 'E2') }
    @{ id = 'S44'; label = 'resolve E2 -> design';                args = @('resolve', '--slug', '001', '--id', 'E2', '--report', 'story renewed') }
    @{ id = 'S45'; label = 'current: E1 still open at design';    args = @('current', '--slug', '001') }
    @{ id = 'S46'; label = 'resolve E1 -> tasks';                 args = @('resolve', '--slug', '001', '--id', 'E1', '--report', 'design renewed') }
    @{ id = 'S47'; label = 'current: clear at tasks';             args = @('current', '--slug', '001') }
    @{ id = 'S48'; label = 'read: full notes history';            args = @('read', '--slug', '001', '--field', 'notes') }
    @{ id = 'S49'; label = 'fixture: pre-brief state';            legacy = '003. legacy' }
    @{ id = 'S50'; label = 'current: brief= - fallback';          args = @('current', '--slug', '003') }
    @{ id = 'S51'; label = 'fixture: truncated JSON';             write = @{ path = '004. corrupt/workflow.json'; content = '{ "id": "004", ' } }
    @{ id = 'S52'; label = 'list: corrupt container stops it';    args = @('list'); expectLines = 2 }
    @{ id = 'S53'; label = 'current: corrupt container';          args = @('current', '--slug', '004'); expectLines = 2 }
    @{ id = 'S54'; label = 'fixture: state missing stage';        write = @{ path = '004. corrupt/workflow.json'; content = '{"id":"004","slug":"corrupt","created":"2026-01-01","notes":[]}' } }
    @{ id = 'S55'; label = 'list: missing field stops it';        args = @('list'); expectLines = 2 }
    @{ id = 'S56'; label = 'fixture: state with unknown stage';   write = @{ path = '004. corrupt/workflow.json'; content = '{"id":"004","slug":"corrupt","created":"2026-01-01","stage":"nonsense","notes":[]}' } }
    @{ id = 'S57'; label = 'list: unknown stage stops it';        args = @('list'); expectLines = 2 }
    @{ id = 'S58'; label = 'fixture: repair the state';           write = @{ path = '004. corrupt/workflow.json'; content = '{"id":"004","slug":"corrupt","created":"2026-01-01","stage":"design","notes":[]}' } }
    @{ id = 'S59'; label = 'list: recovers after repair';         args = @('list') }
    @{ id = 'S60'; label = 'fixture: bare folder, no state';      bare = '005. bare' }
    @{ id = 'S61'; label = 'read: folder without workflow.json';  args = @('read', '--slug', '005'); expectLines = 2 }
    @{ id = 'S62'; label = 'list: stateless folder stops it';     args = @('list'); expectLines = 2 }
    @{ id = 'S63'; label = 'init: uppercase-only refused';        args = @('init', '--slug', 'ALPHA'); expectLines = 2 }
    @{ id = 'S64'; label = 'init: trailing hyphen refused';       args = @('init', '--slug', 'a-'); expectLines = 2 }
    @{ id = 'S65'; label = 'init: underscore refused';            args = @('init', '--slug', 'a_b'); expectLines = 2 }
    @{ id = 'S66'; label = 'read: uppercase slug resolution';     args = @('read', '--slug', 'ALPHA', '--field', 'stage'); expectLines = 2 }
    @{ id = 'S67'; label = 'escalate: unknown target stage';      args = @('escalate', '--slug', '001', '--to', 'bogus', '--reason', 'r', '--brief', '@ROOT/001. alpha/escalations/001. fig.md'); expectLines = 2 }
    @{ id = 'S68'; label = 'no command at all';                   args = @(); expectLines = 2 }
    @{ id = 'S69'; label = 'unknown command';                     args = @('frobnicate'); expectLines = 2 }
)

# A state file written before briefs existed: no 'brief' property at all.
$legacyJson = @'
{
  "id": "003",
  "slug": "legacy",
  "created": "2026-01-01",
  "stage": "design",
  "notes": [
    { "type": "escalation", "id": "E1", "from": "design", "to": "story", "reason": "pre-brief escalation", "date": "2026-01-02" }
  ]
}
'@

foreach ($s in $steps) {
    if ($s.ContainsKey('write')) {
        foreach ($root in @($PsRoot, $ShRoot)) {
            $p = Join-Path (Join-Path $root ($SubRel -replace '/', '\')) ($s.write.path -replace '/', '\')
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $p) | Out-Null
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($p, $s.write.content, $utf8NoBom)
        }
        Add-Block $PsLog $s.id $s.label '(state written in both roots)'
        Add-Block $ShLog $s.id $s.label '(state written in both roots)'
        continue
    }
    if ($s.ContainsKey('fs')) {
        foreach ($root in @($PsRoot, $ShRoot)) {
            $p = Join-Path (Join-Path $root ($SubRel -replace '/', '\')) ($s.fs -replace '/', '\')
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $p) | Out-Null
            Set-Content -Path $p -Value 'placeholder' -NoNewline
        }
        Add-Block $PsLog $s.id $s.label '(fixture created in both roots)'
        Add-Block $ShLog $s.id $s.label '(fixture created in both roots)'
        continue
    }
    if ($s.ContainsKey('legacy')) {
        foreach ($root in @($PsRoot, $ShRoot)) {
            $d = Join-Path (Join-Path $root ($SubRel -replace '/', '\')) ($s.legacy -replace '/', '\')
            New-Item -ItemType Directory -Force -Path $d | Out-Null
            New-Item -ItemType Directory -Force -Path (Join-Path $d 'tasks') | Out-Null
            Set-Content -Path (Join-Path $d 'workflow.json') -Value $legacyJson
        }
        Add-Block $PsLog $s.id $s.label '(pre-brief fixture created in both roots)'
        Add-Block $ShLog $s.id $s.label '(pre-brief fixture created in both roots)'
        continue
    }
    if ($s.ContainsKey('bare')) {
        foreach ($root in @($PsRoot, $ShRoot)) {
            New-Item -ItemType Directory -Force -Path (Join-Path (Join-Path $root ($SubRel -replace '/', '\')) ($s.bare -replace '/', '\')) | Out-Null
        }
        Add-Block $PsLog $s.id $s.label '(bare folder created in both roots)'
        Add-Block $ShLog $s.id $s.label '(bare folder created in both roots)'
        continue
    }

    $r = Invoke-Twin $s.args $false
    $psBody = ("exit=$($r.code)`n" + (Normalize $r.out $false))
    Add-Block $PsLog $s.id $s.label $psBody
    $r = Invoke-Twin $s.args $true
    $shBody = ("exit=$($r.code)`n" + (Normalize $r.out $true))
    Add-Block $ShLog $s.id $s.label $shBody

    # Equality alone would not catch both twins printing a partial list before
    # failing, so line counts are asserted against the contract where it matters.
    if ($s.ContainsKey('expectLines')) {
        foreach ($pair in @(@('ps', $psBody), @('sh', $shBody))) {
            $n = @(($pair[1]).TrimEnd() -split "`n").Count
            if ($n -ne $s.expectLines) {
                $expect.Add("$($s.id) $($s.label): $($pair[0]) output $n body lines, expected $($s.expectLines)")
            }
        }
    }
}

$PsText = ($PsLog -join "`n")
$ShText = ($ShLog -join "`n")

# Written every run; the folder is removed only when the run passes.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $Work 'ps.txt'), $PsText, $utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path $Work 'sh.txt'), $ShText, $utf8NoBom)

$psLines = $PsText -split "`n"
$shLines = $ShText -split "`n"
$diff = @()
$max = [Math]::Max($psLines.Count, $shLines.Count)
for ($i = 0; $i -lt $max; $i++) {
    $a = if ($i -lt $psLines.Count) { $psLines[$i] } else { '<missing>' }
    $b = if ($i -lt $shLines.Count) { $shLines[$i] } else { '<missing>' }
    if ($a -ne $b) {
        $ctx = ''
        for ($j = [Math]::Max(0, $i - 6); $j -lt $i; $j++) {
            if ($j -lt $psLines.Count -and $psLines[$j] -match '^### ') { $ctx = $psLines[$j] }
        }
        $diff += "at line $($i + 1) [$ctx]"
        $diff += "   ps: $a"
        $diff += "   sh: $b"
    }
}

Write-Output "steps: $($steps.Count)  output-diff lines: $($diff.Count)  contract misses: $($expect.Count)"
Write-Output ''
if ($diff.Count -eq 0) {
    Write-Output 'IDENTICAL: both twins produced the same output and exit codes for every step.'
} else {
    Write-Output 'DIVERGENCES:'
    $diff | ForEach-Object { Write-Output $_ }
}
if ($expect.Count -gt 0) {
    Write-Output 'CONTRACT MISSES:'
    $expect | ForEach-Object { Write-Output $_ }
}

# The state the two twins wrote must match too, ignoring path-separator syntax.
$psJson = Join-Path $PsCont '001. alpha\workflow.json'
$shJson = Join-Path (Join-Path $ShRoot ($SubRel -replace '/', '\')) '001. alpha\workflow.json'
$jsonOk = $true
if ((Test-Path $psJson) -and (Test-Path $shJson)) {
    # jq emits CRLF on Windows and LF elsewhere; compare the data, not the line endings.
    $psRaw = (Get-Content $psJson -Raw).Replace('\\', '\').Replace('\', '/').Replace(($PsCont -replace '\\', '/'), $SubRel) -replace "`r`n", "`n"
    $shRaw = (Get-Content $shJson -Raw).Replace('\\', '\').Replace('\', '/').Replace($ShContP, $SubRel) -replace "`r`n", "`n"
    $psRaw = $psRaw.TrimEnd()
    $shRaw = $shRaw.TrimEnd()
    if ($psRaw -eq $shRaw) {
        Write-Output 'workflow.json: identical between twins.'
    } else {
        $jsonOk = $false
        Write-Output 'workflow.json: DIFFERS between twins.'
        Write-Output '  --- ps ---'
        Write-Output $psRaw
        Write-Output '  --- sh ---'
        Write-Output $shRaw
    }
} else {
    $jsonOk = $false
    Write-Output 'workflow.json: MISSING from one of the twins.'
}

$passed = ($diff.Count -eq 0) -and $jsonOk -and ($expect.Count -eq 0)
Write-Output ''
if ($passed) {
    Remove-Item -Recurse -Force $Work
    Write-Output 'PASS - scratch removed.'
    exit 0
}

Write-Output "FAIL - transcripts kept in $Work"
exit 1
