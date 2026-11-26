#Requires -Version 5.1
<#
.SYNOPSIS
    Pressure test for pull-dev-suite.ps1.

.DESCRIPTION
    Builds a throwaway repo + installed-.copilot pair under
    .test-scratch/pull-dev-suite/ and runs the pull script against it, so the
    real repo's artifacts are never touched.

    Coverage: new / updated / unchanged artifacts; model-only skip and
    -IncludeModels; unmapped source-base files; `_installation\` and
    `_*.Tests.*` never pulled or pruned; -Prune deletes repo-only skill files;
    idempotent second run; -WhatIf writes nothing; missing -SourceBase throws.

    Development-only: named '_<subject>.Tests.ps1', sits beside the script it
    tests, and never ships.

    Run from anywhere:  powershell -NoProfile -File _pull-dev-suite.Tests.ps1
    Exit code 0 = pass; 1 = failures (scratch kept for inspection).

    Scratch: .test-scratch/pull-dev-suite/ - this test creates and removes only
    its own subfolder.
#>
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptDir = $PSScriptRoot
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
$Pull      = Join-Path $ScriptDir 'pull-dev-suite.ps1'

$ScratchRoot = Join-Path $RepoRoot '.test-scratch'
$Work        = Join-Path $ScratchRoot 'pull-dev-suite'
if (Test-Path $Work) { Remove-Item -Recurse -Force $Work }
New-Item -ItemType Directory -Force -Path $Work | Out-Null

$script:Failures = 0
function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) {
        Write-Host "  ok   $Message" -ForegroundColor DarkGray
    } else {
        $script:Failures++
        Write-Host "  FAIL $Message" -ForegroundColor Red
    }
}
function Assert-FileContains {
    param([string] $Path, [string] $Text, [string] $Message)
    $Hit = (Test-Path -LiteralPath $Path) -and ((Get-Content -LiteralPath $Path -Raw) -like "*$Text*")
    Assert-True $Hit $Message
}

function Write-Text {
    param([string] $Path, [string] $Content)
    $Dir = Split-Path -Parent $Path
    if (-not (Test-Path $Dir)) { New-Item -ItemType Directory -Path $Dir -Force | Out-Null }
    Set-Content -LiteralPath $Path -Value $Content -NoNewline
}

function Get-TreeHash {
    param([string] $Root)
    Get-ChildItem -LiteralPath $Root -Recurse -File | Sort-Object FullName | ForEach-Object {
        '{0}|{1}' -f $_.FullName.Substring($Root.Length), (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }
}

# ── Fixtures ─────────────────────────────────────────────────────────────────
function New-Fixture {
    param([string] $Root)

    $Repo = Join-Path $Root 'repo'
    $Base = Join-Path $Root 'copilot'

    # Repo-side artifacts (canonical locations produced by the installer)
    Write-Text (Join-Path $Repo 'tools\sda\agents\sda-dev.agent.md')     "---`nname: sda-dev`nmodel: Claude Sonnet 5`n---`nBODY-A`n"
    Write-Text (Join-Path $Repo 'tools\sda\agents\sda-old.agent.md')     "---`nname: sda-old`n---`nnot installed`n"
    Write-Text (Join-Path $Repo 'tools\sda\agents\sda-body.agent.md')    "---`nname: sda-body`nmodel: Claude Sonnet 5`n---`nbody line`nmodel: alpha`n"
    Write-Text (Join-Path $Repo 'tools\sda\prompts\sda.setup.prompt.md') 'setup v1'
    Write-Text (Join-Path $Repo 'agents\commit\commit.agent.md')         "---`nname: commit`nmodel: Claude Haiku 4.5`n---`nCOMMIT-BODY`n"
    Write-Text (Join-Path $Repo 'prompts\commit\commit.prompt.md')       'commit v1'
    Write-Text (Join-Path $Repo 'skills\troubleshooting\SKILL.md')       'trouble v1'
    Write-Text (Join-Path $Repo 'skills\troubleshooting\assets\deep.md') 'deep v1'
    Write-Text (Join-Path $Repo 'skills\troubleshooting\assets\legacy.md') 'repo only'
    Write-Text (Join-Path $Repo 'skills\troubleshooting\_installation\powershell\install.ps1') 'canary-repo'
    Write-Text (Join-Path $Repo 'skills\troubleshooting\_helper.Tests.ps1') 'repo-only test'
    Write-Text (Join-Path $Repo 'tools\sda\skills\sda-setup\SKILL.md')   'setup skill v1'

    # Installed-side artifacts (what a .copilot folder holds)
    Write-Text (Join-Path $Base 'agents\sda-dev.agent.md')      "---`nname: sda-dev`nmodel: Claude Sonnet 5`n---`nBODY-B`n"
    Write-Text (Join-Path $Base 'agents\sda-new.agent.md')      "---`nname: sda-new`n---`nnew agent`n"
    Write-Text (Join-Path $Base 'agents\sda-body.agent.md')     "---`nname: sda-body`nmodel: Claude Sonnet 5`n---`nbody line`nmodel: beta`n"
    Write-Text (Join-Path $Base 'agents\ts-tutor.agent.md')     "---`nname: ts-tutor`n---`nnot dev suite`n"
    Write-Text (Join-Path $Base 'prompts\sda.setup.prompt.md')  'setup v1'
    Write-Text (Join-Path $Base 'prompts\sda.new.prompt.md')    'new prompt'
    Write-Text (Join-Path $Base 'agents\commit.agent.md')       "---`nname: commit`nmodel: Claude Opus 4 (Copilot)`n---`nCOMMIT-BODY`n"
    Write-Text (Join-Path $Base 'prompts\commit.prompt.md')     'commit v1'
    Write-Text (Join-Path $Base 'skills\sda-setup\SKILL.md')    'setup skill v2'
    Write-Text (Join-Path $Base 'skills\troubleshooting\SKILL.md') 'trouble v2'
    Write-Text (Join-Path $Base 'skills\troubleshooting\assets\deep.md') 'deep v1'
    Write-Text (Join-Path $Base 'skills\troubleshooting\assets\extra.md') 'extra v1'
    Write-Text (Join-Path $Base 'skills\troubleshooting\_installation\powershell\install.ps1') 'canary-source'
    Write-Text (Join-Path $Base 'skills\troubleshooting\_helper.Tests.ps1') 'installed test'
    Write-Text (Join-Path $Base 'skills\unknown-skill\SKILL.md') 'other project skill'

    return @{ Repo = $Repo; Base = $Base }
}

function Invoke-Pull {
    param([hashtable] $Fixture, [switch] $IncludeModels, [switch] $Prune, [switch] $WhatIf)
    & $Pull -SourceBase $Fixture.Base -RepoRoot $Fixture.Repo -Confirm:$false `
        -IncludeModels:$IncludeModels -Prune:$Prune -WhatIf:$WhatIf *>&1 | Out-Null
}

# ══════════════════════════════════════════════════════════════════════════════
# 1. Default run
# ══════════════════════════════════════════════════════════════════════════════
Write-Host "`n== Default pull ==" -ForegroundColor Cyan
$F = New-Fixture (Join-Path $Work 'default')
Invoke-Pull $F

Assert-FileContains (Join-Path $F.Repo 'tools\sda\agents\sda-dev.agent.md')     'BODY-B' 'updated agent pulled'
Assert-FileContains (Join-Path $F.Repo 'tools\sda\agents\sda-new.agent.md')     'new agent' 'new agent added'
Assert-True (-not (Test-Path (Join-Path $F.Repo 'agents\ts-tutor.agent.md'))) 'unmapped agent not copied'
Assert-FileContains (Join-Path $F.Repo 'tools\sda\agents\sda-body.agent.md') 'model: beta' 'body line starting with model: is pulled'
Assert-FileContains (Join-Path $F.Repo 'tools\sda\prompts\sda.new.prompt.md')   'new prompt' 'new prompt added'
Assert-FileContains (Join-Path $F.Repo 'agents\commit\commit.agent.md')         'model: Claude Haiku 4.5' 'model-only change skipped'
Assert-FileContains (Join-Path $F.Repo 'skills\troubleshooting\SKILL.md')       'trouble v2' 'updated skill file pulled'
Assert-FileContains (Join-Path $F.Repo 'skills\troubleshooting\assets\extra.md') 'extra v1' 'new skill file added'
Assert-FileContains (Join-Path $F.Repo 'tools\sda\skills\sda-setup\SKILL.md')   'setup skill v2' 'sda skill pulled'
Assert-True (Test-Path (Join-Path $F.Repo 'skills\troubleshooting\assets\legacy.md')) 'repo-only file kept without -Prune'
Assert-FileContains (Join-Path $F.Repo 'skills\troubleshooting\_installation\powershell\install.ps1') 'canary-repo' '_installation never overwritten'
Assert-FileContains (Join-Path $F.Repo 'skills\troubleshooting\_helper.Tests.ps1') 'repo-only test' 'Tests file never overwritten'
Assert-True (-not (Test-Path (Join-Path $F.Repo 'skills\unknown-skill'))) 'unmapped skill not copied'

# ══════════════════════════════════════════════════════════════════════════════
# 2. Idempotent second run
# ══════════════════════════════════════════════════════════════════════════════
Write-Host "`n== Second run is a no-op ==" -ForegroundColor Cyan
$Before = (Get-TreeHash $F.Repo) -join "`n"
Invoke-Pull $F
$After = (Get-TreeHash $F.Repo) -join "`n"
Assert-True ($Before -ceq $After) 'second pull changes nothing'

# ══════════════════════════════════════════════════════════════════════════════
# 3. -IncludeModels
# ══════════════════════════════════════════════════════════════════════════════
Write-Host "`n== -IncludeModels ==" -ForegroundColor Cyan
Invoke-Pull $F -IncludeModels
Assert-FileContains (Join-Path $F.Repo 'agents\commit\commit.agent.md') 'model: Claude Opus 4 (Copilot)' 'model pulled with -IncludeModels'

# ══════════════════════════════════════════════════════════════════════════════
# 4. -Prune
# ══════════════════════════════════════════════════════════════════════════════
Write-Host "`n== -Prune ==" -ForegroundColor Cyan
Invoke-Pull $F -Prune
Assert-True (-not (Test-Path (Join-Path $F.Repo 'skills\troubleshooting\assets\legacy.md'))) 'repo-only file pruned'
Assert-True (Test-Path (Join-Path $F.Repo 'skills\troubleshooting\_installation\powershell\install.ps1')) '_installation survives -Prune'
Assert-True (Test-Path (Join-Path $F.Repo 'skills\troubleshooting\_helper.Tests.ps1')) 'Tests file survives -Prune'

# ══════════════════════════════════════════════════════════════════════════════
# 5. -WhatIf writes nothing
# ══════════════════════════════════════════════════════════════════════════════
Write-Host "`n== -WhatIf ==" -ForegroundColor Cyan
$W = New-Fixture (Join-Path $Work 'whatif')
$Before = (Get-TreeHash $W.Repo) -join "`n"
Invoke-Pull $W -WhatIf
$After = (Get-TreeHash $W.Repo) -join "`n"
Assert-True ($Before -ceq $After) '-WhatIf changes nothing'

# ══════════════════════════════════════════════════════════════════════════════
# 6. Missing -SourceBase throws
# ══════════════════════════════════════════════════════════════════════════════
Write-Host "`n== Missing source base ==" -ForegroundColor Cyan
$Threw = $false
try {
    & $Pull -SourceBase (Join-Path $Work 'does-not-exist') -RepoRoot $F.Repo -Confirm:$false *>&1 | Out-Null
} catch {
    $Threw = $true
}
Assert-True $Threw 'missing -SourceBase throws'

# ══════════════════════════════════════════════════════════════════════════════
# Verdict
# ══════════════════════════════════════════════════════════════════════════════
Write-Host ''
if ($script:Failures -gt 0) {
    Write-Host "FAILED: $($script:Failures) assertion(s). Scratch kept at $Work" -ForegroundColor Red
    exit 1
}
Remove-Item -Recurse -Force $Work
Write-Host 'PASS' -ForegroundColor Green
exit 0
