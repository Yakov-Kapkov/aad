#Requires -Version 5.1
<#
.SYNOPSIS
    Differential test for the check-tree twins.

.DESCRIPTION
    Runs check-tree.ps1 and check-tree.sh over one fixture tree and compares
    stdout and exit codes, then asserts the expected findings. Any difference is
    a bug in one of the twins.

    Development-only: tests are named '_<subject>.Tests.ps1' and sit beside the
    code they test. They never ship - the skill installers prune them.

    Run from anywhere:  powershell -NoProfile -File _check-tree.Tests.ps1
    Exit code 0 = pass; 1 = divergence or a wrong finding.

    Scratch: .test-scratch/check-tree/ - the shared, gitignored scratch root.
    This test creates and removes only its own subfolder.
#>
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptDir = $PSScriptRoot
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..\..\..\..')).Path
$PsTwin = Join-Path $ScriptDir 'check-tree.ps1'
$ShTwin = Join-Path $ScriptDir 'check-tree.sh'

$Bash = 'C:\Program Files\Git\bin\bash.exe'
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

$ScratchRoot = Join-Path $RepoRoot '.test-scratch'
$Work = Join-Path $ScratchRoot 'check-tree'
if (Test-Path $Work) { Remove-Item -Recurse -Force $Work }
New-Item -ItemType Directory -Force -Path $Work | Out-Null

function ConvertTo-Posix([string]$p) {
    $d = $p.Substring(0, 1).ToLower()
    return '/' + $d + '/' + ((($p.Substring(3)) -replace '\\', '/'))
}

# --- fixtures ---
$bad = Join-Path $Work 'bad'
$clean = Join-Path $Work 'clean'
New-Item -ItemType Directory -Force -Path $bad, $clean | Out-Null

foreach ($dir in @($bad, $clean)) {
    Set-Content -Path (Join-Path $dir 'a.md') -Value '# A'
    Set-Content -Path (Join-Path $dir 'b.md') -Value '# B'
}
Set-Content -Path (Join-Path $bad 'orphan.md') -Value '# Nobody links here'
Set-Content -Path (Join-Path $bad 'index.md') -Value @(
    '[A](a.md)',
    '[A again](a.md)',
    '[Missing](missing.md)'
)
Set-Content -Path (Join-Path $clean 'index.md') -Value @('[A](a.md)', '[B](b.md)')

$pass = 0
$fail = 0
function Assert([string]$name, [bool]$cond) {
    if ($cond) { Write-Output "ok   $name"; $script:pass++ }
    else { Write-Output "FAIL $name"; $script:fail++ }
}

# Compare on the <check>|<status> columns only - the path column carries the
# platform's separator, which is not the script's contract.
function Get-Key([object[]]$lines) {
    $out = foreach ($l in @($lines)) {
        $t = [string]$l
        $parts = $t -split '\s*\|\s*'
        if ($parts.Count -ge 3) { "$($parts[$parts.Count - 2])|$($parts[$parts.Count - 1])" }
        else { "raw:$t" }
    }
    return @($out | Sort-Object)
}

# --- flagged run ---
$psOut = & $PsTwin -Root $bad
$psExit = $LASTEXITCODE
$shOut = & $Bash (ConvertTo-Posix $ShTwin) --root (ConvertTo-Posix $bad)
$shExit = $LASTEXITCODE

$psKeys = Get-Key $psOut
$shKeys = Get-Key $shOut

Assert 'flagged run: both twins exit 1' (($psExit -eq 1) -and ($shExit -eq 1))
Assert 'flagged run: twins agree' (($psKeys -join "`n") -eq ($shKeys -join "`n"))
Assert 'flags a broken link' ($psKeys -contains 'broken-link: missing.md|broken')
Assert 'flags a duplicate row' ($psKeys -contains 'duplicate-row: a.md|duplicate')
Assert 'flags an orphan' ($psKeys -contains 'orphan|orphan')

# --- clean run ---
$psClean = & $PsTwin -Root $clean
$psCleanExit = $LASTEXITCODE
$shClean = & $Bash (ConvertTo-Posix $ShTwin) --root (ConvertTo-Posix $clean)
$shCleanExit = $LASTEXITCODE

Assert 'clean run: both twins exit 0' (($psCleanExit -eq 0) -and ($shCleanExit -eq 0))
Assert 'clean run: reports clean' (((Get-Key $psClean) -contains 'tree|clean') -and ((Get-Key $shClean) -contains 'tree|clean'))

Write-Output "`n$pass passed, $fail failed"

if ($fail -eq 0) {
    Remove-Item -Recurse -Force $Work
    exit 0
}
Write-Output "scratch kept for inspection: $Work"
exit 1
