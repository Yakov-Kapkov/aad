#Requires -Version 5.1
# End-to-end test for the DEV+QA cycle-state + next-step scripts.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$dir = Join-Path ([System.IO.Path]::GetTempPath()) ("wf-" + [guid]::NewGuid().ToString('N').Substring(0, 8))

$fail = 0
function Check($name, $cond) {
    if ($cond) { Write-Host "PASS $name" -ForegroundColor Green } else { Write-Host "FAIL $name" -ForegroundColor Red; $script:fail++ }
}
function Cyc { param($a) (& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'dev-qa-cycle-state.ps1') @a 2>&1) | Out-String }
function Next { (& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'dev-qa-next-step.ps1') -Dir $dir 2>&1) | Out-String }
function Field($f) { (Cyc @('read', '-Dir', $dir, '-Field', $f)).Trim() }

try {
    $o = Cyc @('init', '-Dir', $dir, '-Task', 'add-auth')
    Check 'init ok' ($o -match 'initialized cycle')
    Check 'run-01 folder' (Test-Path (Join-Path $dir 'runs/run-01'))
    Check 'status implementing' ((Field 'status') -eq 'implementing')
    Check 'spec default' ((Field 'spec') -eq 'runs/run-01/task.md')
    Check 'sha null' ((Field 'sha') -eq 'null')

    Check 'next=implement' ((Next) -match 'implement runs/run-01 with sda-dev')

    $o = Cyc @('set-sha', '-Dir', $dir, '-Sha', 'abc123')
    Check 'sha set' ((Field 'sha') -eq 'abc123')
    Check 'next=primary QA' ((Next) -match 'PRIMARY QA with sda-qa')

    $o = Cyc @('set-verdict', '-Dir', $dir, '-Gate', 'primary', '-Verdict', 'FAIL', '-Failures', 'FR-3,NFR-1')
    Check 'status rework' ((Field 'status') -eq 'rework')
    Check 'open-failures set' ((Field 'open-failures') -eq '[FR-3, NFR-1]')
    Check 'verdict recorded' ((Field 'verdict') -eq 'FAIL')
    Check 'next=rework' ((Next) -match 'author a fix task')
    Check 'next shows failures' ((Next) -match 'FR-3, NFR-1')

    $o = Cyc @('bump-run', '-Dir', $dir)
    Check 'bumped to 2' ((Field 'current-run') -eq '2')
    Check 'run-02 folder' (Test-Path (Join-Path $dir 'runs/run-02'))
    Check 'status implementing again' ((Field 'status') -eq 'implementing')
    Check 'open cleared' ((Field 'open-failures') -eq '[]')

    $o = Cyc @('set-sha', '-Dir', $dir, '-Sha', 'def456')
    $o = Cyc @('set-verdict', '-Dir', $dir, '-Gate', 'primary', '-Verdict', 'PASS')
    Check 'status qa-regression' ((Field 'status') -eq 'qa-regression')
    Check 'next=ledgers+regression' ((Next) -match 'sda-dev-context-writer.*sda-qa-context-writer')

    $o = Cyc @('set-verdict', '-Dir', $dir, '-Gate', 'regression', '-Verdict', 'PASS')
    Check 'status passed' ((Field 'status') -eq 'passed')
    Check 'next=done' ((Next) -match 'Cycle complete')

    # both runs recorded
    $yaml = Get-Content -Raw (Join-Path $dir 'dev-qa-cycle-state.yaml')
    Check 'two runs recorded' (@($yaml -split "`n" | Where-Object { $_ -match '^\s+- run:' }).Count -eq 2)
    Check 'run1 sha' ($yaml -match 'sha: abc123')
    Check 'run2 sha' ($yaml -match 'sha: def456')

    # error paths
    Check 'read missing dir errors' ((Cyc @('read', '-Dir', (Join-Path $dir 'nope'))) -match 'error=')
    Check 'double init errors' ((Cyc @('init', '-Dir', $dir, '-Task', 'x')) -match 'error=')

    # === outer SDLC-workflow scripts: workflow-state + workflow-next-step ===
    $wdir = Join-Path ([System.IO.Path]::GetTempPath()) ("ws-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    function Wf { param($a) (& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'workflow-state.ps1') @a 2>&1) | Out-String }
    function WNext($d) { (& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'workflow-next-step.ps1') -Dir $d 2>&1) | Out-String }
    function WField($f) { (Wf @('read', '-Dir', $wdir, '-Field', $f)).Trim() }

    $o = Wf @('init', '-Dir', $wdir, '-Id', '0007-login')
    Check 'wf init ok' ($o -match 'initialized workflow')
    Check 'wf subfolders BA..DEP' ((Test-Path (Join-Path $wdir 'BA')) -and (Test-Path (Join-Path $wdir 'DEV')) -and (Test-Path (Join-Path $wdir 'DEP')))
    Check 'wf current-bc BA' ((WField 'current-bc') -eq 'BA')
    Check 'wf branch default' ((WField 'branch') -eq 'story/0007-login')
    Check 'wf status.ba active' ((WField 'status.ba') -eq 'active')
    Check 'wf status.design pending' ((WField 'status.design') -eq 'pending')
    Check 'wf output.dev' ((WField 'output.dev') -eq 'DEV/task.md')
    Check 'wf ledger.ba pending' ((WField 'ledger.ba') -eq 'pending')
    Check 'wf next=BA' ((WNext $wdir) -match 'invoke sda-ba')
    Check 'wf next PS-native flags' ((WNext $wdir) -match '-Bc BA -Status done -Ledger done')

    $null = Wf @('update', '-Dir', $wdir, '-Bc', 'BA', '-Status', 'done', '-Ledger', 'done')
    Check 'wf BA done -> DESIGN' ((WField 'current-bc') -eq 'DESIGN')
    Check 'wf ledger.ba done' ((WField 'ledger.ba') -eq 'done')
    Check 'wf status.ba done' ((WField 'status.ba') -eq 'done')
    Check 'wf next=DESIGN' ((WNext $wdir) -match 'sda-system / sda-feature')

    $null = Wf @('update', '-Dir', $wdir, '-Bc', 'DESIGN', '-Status', 'done', '-Ledger', 'done')
    Check 'wf DESIGN done -> DEV' ((WField 'current-bc') -eq 'DEV')
    Check 'wf next=DEV span' ((WNext $wdir) -match 'DEV\+QA span')

    $null = Wf @('update', '-Dir', $wdir, '-Bc', 'DEV', '-Status', 'done', '-Ledger', 'done')
    $null = Wf @('update', '-Dir', $wdir, '-Bc', 'QA', '-Status', 'done', '-Ledger', 'done')
    Check 'wf DEV+QA done -> DEP' ((WField 'current-bc') -eq 'DEP')
    Check 'wf next=DEP' ((WNext $wdir) -match 'DEP step')

    $null = Wf @('update', '-Dir', $wdir, '-Bc', 'DEP', '-Status', 'done', '-Ledger', 'done')
    Check 'wf all done' ((WField 'current-bc') -eq 'done')
    Check 'wf next=merge' ((WNext $wdir) -match 'Human merge')

    $edir = Join-Path ([System.IO.Path]::GetTempPath()) ("we-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $null = Wf @('init', '-Dir', $edir, '-Id', 'x', '-Branch', 'story/custom')
    Check 'wf custom branch' (((Wf @('read', '-Dir', $edir, '-Field', 'branch')).Trim()) -eq 'story/custom')
    $null = Wf @('escalate', '-Dir', $edir, '-From', 'QA', '-To', 'BA', '-Reason', 'US-3 not testable')
    Check 'wf escalate -> BA' (((Wf @('read', '-Dir', $edir, '-Field', 'current-bc')).Trim()) -eq 'BA')
    Check 'wf escalate status.qa' (((Wf @('read', '-Dir', $edir, '-Field', 'status.qa')).Trim()) -eq 'escalated')
    Check 'wf escalation recorded' ((Get-Content -Raw (Join-Path $edir 'workflow-state.yaml')) -match 'reason: US-3 not testable')

    Check 'wf double init errors' ((Wf @('init', '-Dir', $wdir, '-Id', 'y')) -match 'error=')
    Check 'wf read missing errors' ((Wf @('read', '-Dir', (Join-Path $edir 'none'))) -match 'error=')

    Remove-Item -Recurse -Force $wdir, $edir -ErrorAction SilentlyContinue
}
finally {
    Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
}
if ($fail -eq 0) { Write-Host "`nALL PASS" -ForegroundColor Green; exit 0 } else { Write-Host "`n$fail FAILED" -ForegroundColor Red; exit 1 }
