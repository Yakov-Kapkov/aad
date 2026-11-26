#Requires -Version 5.1
<#
.SYNOPSIS
    Pulls dev-suite artifacts from an installed .copilot folder back into this repo.

.DESCRIPTION
    The reverse of install-dev-suite.ps1: every artifact the installer copies is
    read from -SourceBase and written back to its canonical repo location, so
    edits made against the installed copy persist here.

    Only dev-suite artifacts are pulled. Files under -SourceBase that map to no
    repo location are listed and left alone. `_installation\` folders and
    `_*.Tests.*` files are never pulled: they exist only in the repo.

    Install-time differences are filtered: when a file differs from the repo copy
    only in its `model:` frontmatter line, it is reported and skipped, so `-Models`
    overrides used at install time never leak into the repo.

.PARAMETER SourceBase
    Path to the installed .copilot folder. Default: $env:USERPROFILE\.copilot.

.PARAMETER RepoRoot
    Repo root to pull into. Default: the repo containing this script.

.PARAMETER IncludeModels
    Pull `model:`-only differences too. Without it those files are skipped.

.PARAMETER Prune
    Delete repo skill files that are absent from -SourceBase. Without it they are
    reported and kept. `_installation\` and `_*.Tests.*` are never pruned.

.EXAMPLE
    .\pull-dev-suite.ps1

.EXAMPLE
    .\pull-dev-suite.ps1 -SourceBase "C:\my\.copilot" -WhatIf

.EXAMPLE
    .\pull-dev-suite.ps1 -Prune -IncludeModels
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $SourceBase = "$env:USERPROFILE\.copilot",
    [string] $RepoRoot,
    [switch] $IncludeModels,
    [switch] $Prune
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Cmdlet = $PSCmdlet

if (-not $RepoRoot) {
    $RepoRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
}
if (-not (Test-Path -LiteralPath $SourceBase -PathType Container)) {
    throw "Source base not found: $SourceBase"
}
$SourceBase = (Resolve-Path -LiteralPath $SourceBase).Path
$RepoRoot   = (Resolve-Path -LiteralPath $RepoRoot).Path

# ── Installed artifact → repo location ───────────────────────────────────────
# Mirrors the copies performed by install-dev-suite.ps1. Keep both in sync.
$ArtifactMaps = @(
    @{ Name = 'SDA agents';     InstalledDir = 'agents';  Filter = 'sda-*.agent.md';    RepoDir = 'tools\sda\agents'  }
    @{ Name = 'SDA prompts';    InstalledDir = 'prompts'; Filter = 'sda*.prompt.md';    RepoDir = 'tools\sda\prompts' }
    @{ Name = 'commit agent';   InstalledDir = 'agents';  Filter = 'commit.agent.md';   RepoDir = 'agents\commit'     }
    @{ Name = 'commit prompts'; InstalledDir = 'prompts'; Filter = 'commit*.prompt.md'; RepoDir = 'prompts\commit'    }
)
$SkillMaps = @(
    @{ Name = 'sda-setup';                     RepoDir = 'tools\sda\skills\sda-setup'                }
    @{ Name = 'sda-workflow-guide';            RepoDir = 'tools\sda\skills\sda-workflow-guide'       }
    @{ Name = 'sda-spec-guide';                RepoDir = 'tools\sda\skills\sda-spec-guide'           }
    @{ Name = 'cli-tool-scan';                 RepoDir = 'skills\cli-tool-scan'                      }
    @{ Name = 'standards-compliance';           RepoDir = 'skills\standards-compliance'               }
    @{ Name = 'troubleshooting';                RepoDir = 'skills\troubleshooting'                    }
    @{ Name = 'software-design-best-practices'; RepoDir = 'skills\software-design-best-practices'     }
    @{ Name = 'is-repo-ai-friendly';            RepoDir = 'skills\is-repo-ai-friendly'                }
    @{ Name = 'make-repo-ai-friendly';          RepoDir = 'skills\make-repo-ai-friendly'              }
    @{ Name = 'test-driven-design';             RepoDir = 'skills\test-driven-design'                 }
    @{ Name = 'design-partner';                 RepoDir = 'skills\design-partner'                     }
)

$Stats = [pscustomobject]@{
    Considered   = 0
    Added        = 0
    Updated      = 0
    Unchanged    = 0
    ModelOnly    = 0
    Pruned       = 0
    NotInstalled = [System.Collections.Generic.List[string]]::new()
    RepoOnly     = [System.Collections.Generic.List[string]]::new()
    Skipped      = [System.Collections.Generic.List[string]]::new()
}
$Mapped = [System.Collections.Generic.HashSet[string]]::new()

# ── Helpers ──────────────────────────────────────────────────────────────────
function Test-DevOnly {
    param([System.IO.FileInfo] $File)
    if ($File.Name -like '_*.Tests.*') { return $true }
    if ($File.FullName -match '[\\/]_installation[\\/]') { return $true }
    return $false
}

function Get-NormalizedAgentText {
    param([string] $Text)

    if ($null -eq $Text) { return '' }
    $Lines = ($Text -replace "`r`n", "`n") -split "`n"
    $InFrontmatter = ($Lines.Count -gt 0 -and $Lines[0] -eq '---')
    $Output = [System.Collections.Generic.List[string]]::new()
    $Index = 0
    if ($InFrontmatter) { $Output.Add($Lines[0]); $Index = 1 }
    for (; $Index -lt $Lines.Count; $Index++) {
        $Line = $Lines[$Index]
        if ($InFrontmatter -and $Line -eq '---') {
            $InFrontmatter = $false
        } elseif ($InFrontmatter -and $Line -like 'model:*') {
            continue
        }
        $Output.Add($Line)
    }
    return ($Output -join "`n")
}

function Test-ModelOnlyChange {
    param([string] $SourcePath, [string] $RepoPath)

    $Source = Get-NormalizedAgentText (Get-Content -LiteralPath $SourcePath -Raw)
    $Repo   = Get-NormalizedAgentText (Get-Content -LiteralPath $RepoPath -Raw)
    return ($Source -ceq $Repo)
}

function Get-ChangeStatus {
    param([string] $SourcePath, [string] $RepoPath)

    if (-not (Test-Path -LiteralPath $RepoPath)) { return 'New' }
    $SourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
    $RepoHash   = (Get-FileHash -LiteralPath $RepoPath   -Algorithm SHA256).Hash
    if ($SourceHash -eq $RepoHash) { return 'Same' }
    if ($SourcePath -like '*.agent.md' -and (Test-ModelOnlyChange -SourcePath $SourcePath -RepoPath $RepoPath)) {
        return 'ModelOnly'
    }
    return 'Changed'
}

function Copy-Artifact {
    param([string] $SourcePath, [string] $RepoPath, [string] $Label)

    $Status = Get-ChangeStatus -SourcePath $SourcePath -RepoPath $RepoPath
    $Stats.Considered++
    if ($Status -eq 'Same') {
        $Stats.Unchanged++
        return
    }
    if ($Status -eq 'ModelOnly' -and -not $IncludeModels) {
        $Stats.ModelOnly++
        Write-Host ("    model-only  {0}  (skipped; -IncludeModels to pull)" -f $Label) -ForegroundColor DarkGray
        return
    }
    if (-not $Cmdlet.ShouldProcess($RepoPath, "Pull $Label")) { return }

    $Dir = Split-Path -Parent $RepoPath
    if (-not (Test-Path -LiteralPath $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    }
    Copy-Item -LiteralPath $SourcePath -Destination $RepoPath -Force

    if ($Status -eq 'New') {
        $Stats.Added++
        Write-Host "    add         $Label" -ForegroundColor Green
    } else {
        $Stats.Updated++
        Write-Host "    update      $Label" -ForegroundColor Yellow
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# PULL
# ══════════════════════════════════════════════════════════════════════════════
Write-Host "`nSource: $SourceBase" -ForegroundColor Cyan
Write-Host "Repo:   $RepoRoot" -ForegroundColor Cyan

foreach ($Map in $ArtifactMaps) {
    $InstalledDir = Join-Path $SourceBase $Map.InstalledDir
    if (-not (Test-Path -LiteralPath $InstalledDir)) { continue }
    $Files = @(Get-ChildItem -LiteralPath $InstalledDir -Filter $Map.Filter -File -ErrorAction SilentlyContinue)
    if ($Files.Count -eq 0) { continue }

    Write-Host "`n=== Pulling $($Map.Name) ===" -ForegroundColor Cyan
    foreach ($File in $Files) {
        [void]$Mapped.Add($File.FullName)
        Copy-Artifact -SourcePath $File.FullName `
                      -RepoPath (Join-Path $RepoRoot (Join-Path $Map.RepoDir $File.Name)) `
                      -Label "$($Map.InstalledDir)\$($File.Name)"
    }
}

foreach ($Map in $SkillMaps) {
    $InstalledSkill = Join-Path $SourceBase "skills\$($Map.Name)"
    if (-not (Test-Path -LiteralPath $InstalledSkill)) {
        $Stats.NotInstalled.Add("skills\$($Map.Name)\")
        continue
    }

    Write-Host "`n=== Pulling skill: $($Map.Name) ===" -ForegroundColor Cyan
    $RepoSkill = Join-Path $RepoRoot $Map.RepoDir

    $InstalledFiles = @(Get-ChildItem -LiteralPath $InstalledSkill -Recurse -File | Where-Object { -not (Test-DevOnly $_) })
    foreach ($File in $InstalledFiles) {
        $Rel = $File.FullName.Substring($InstalledSkill.Length + 1)
        Copy-Artifact -SourcePath $File.FullName `
                      -RepoPath (Join-Path $RepoSkill $Rel) `
                      -Label "skills\$($Map.Name)\$Rel"
    }

    if (-not (Test-Path -LiteralPath $RepoSkill)) { continue }
    $RepoSkillFull = (Resolve-Path -LiteralPath $RepoSkill).Path
    $RepoFiles = @(Get-ChildItem -LiteralPath $RepoSkillFull -Recurse -File | Where-Object { -not (Test-DevOnly $_) })
    foreach ($File in $RepoFiles) {
        $Rel = $File.FullName.Substring($RepoSkillFull.Length + 1)
        if (Test-Path -LiteralPath (Join-Path $InstalledSkill $Rel)) { continue }
        if (-not $Prune) {
            $Stats.RepoOnly.Add("skills\$($Map.Name)\$Rel")
            continue
        }
        if (-not $Cmdlet.ShouldProcess($File.FullName, 'Prune')) { continue }
        Remove-Item -LiteralPath $File.FullName -Force
        $Stats.Pruned++
        Write-Host "    prune       skills\$($Map.Name)\$Rel" -ForegroundColor Red
    }
}

# ── Source-base files outside the dev suite ──────────────────────────────────
foreach ($Sub in @('agents', 'prompts')) {
    $Dir = Join-Path $SourceBase $Sub
    if (-not (Test-Path -LiteralPath $Dir)) { continue }
    Get-ChildItem -LiteralPath $Dir -File | Where-Object { -not $Mapped.Contains($_.FullName) } |
        ForEach-Object { $Stats.Skipped.Add("$Sub\$($_.Name) (not a dev-suite artifact)") }
}
$SkillsDir = Join-Path $SourceBase 'skills'
if (Test-Path -LiteralPath $SkillsDir) {
    $KnownSkills = $SkillMaps | ForEach-Object { $_.Name }
    Get-ChildItem -LiteralPath $SkillsDir -Directory |
        Where-Object { $_.Name -notin $KnownSkills } |
        ForEach-Object { $Stats.Skipped.Add("skills\$($_.Name)\ (not a dev-suite artifact)") }
}

# ── Summary ──────────────────────────────────────────────────────────────────
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host ("  {0} added, {1} updated, {2} unchanged, {3} model-only skipped, {4} pruned" -f `
    $Stats.Added, $Stats.Updated, $Stats.Unchanged, $Stats.ModelOnly, $Stats.Pruned)

if ($Stats.NotInstalled.Count -gt 0) {
    Write-Host "`nNot installed (skipped):" -ForegroundColor DarkGray
    foreach ($Item in $Stats.NotInstalled) { Write-Host "  $Item" -ForegroundColor DarkGray }
}
if ($Stats.RepoOnly.Count -gt 0) {
    Write-Host "`nRepo-only files (kept; -Prune to delete):" -ForegroundColor DarkGray
    foreach ($Item in $Stats.RepoOnly) { Write-Host "  $Item" -ForegroundColor DarkGray }
}
if ($Stats.Skipped.Count -gt 0) {
    Write-Host "`nSkipped (not dev-suite artifacts):" -ForegroundColor DarkGray
    foreach ($Item in $Stats.Skipped) { Write-Host "  $Item" -ForegroundColor DarkGray }
}

if ($Stats.Considered -eq 0) {
    Write-Host "`nNo dev-suite artifacts found under $SourceBase. Check -SourceBase.`n" -ForegroundColor Yellow
    return
}

if ($Stats.Added -eq 0 -and $Stats.Updated -eq 0 -and $Stats.Pruned -eq 0) {
    Write-Host "`nRepo is up to date with $SourceBase.`n" -ForegroundColor Green
} else {
    Write-Host "`nReview with 'git diff', then commit.`n" -ForegroundColor Green
}
