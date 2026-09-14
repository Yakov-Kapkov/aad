param(
    [Parameter(Mandatory)][string]$Language
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)  # assets folder
$targetDir = '.sda'

# Create folder structure
New-Item -ItemType Directory -Force -Path "$targetDir/resources/$Language" | Out-Null
New-Item -ItemType Directory -Force -Path "$targetDir/secrets" | Out-Null

# .gitignore — keeps .sda/ out of version control
Set-Content -Path "$targetDir/.gitignore" -Value '*' -NoNewline

# secrets/.gitignore — defense in depth: secrets stay ignored even if the
# parent .sda/.gitignore is loosened (e.g. to commit tasks). Keeps the ignore
# rule and the placeholder example tracked; real qa.secrets.env is never committable.
Set-Content -Path "$targetDir/secrets/.gitignore" -Value "*`n!.gitignore`n!qa.example.secrets.env"

# Copy resource files (byte-for-byte)
New-Item -ItemType Directory -Force -Path "$targetDir/resources/dev" | Out-Null
Copy-Item "$scriptDir/project-config.example.json"       "$targetDir/resources/project-config.example.json"
Copy-Item "$scriptDir/project-config.reference.yml"      "$targetDir/project-config.reference.yml"
Copy-Item "$scriptDir/dev/task-schema.md"                  "$targetDir/resources/dev/task-schema.md"
Copy-Item "$scriptDir/dev/dev-report-schema.md"            "$targetDir/resources/dev/dev-report-schema.md"
New-Item -ItemType Directory -Force -Path "$targetDir/resources/qa" | Out-Null
Copy-Item "$scriptDir/qa/qa-task-schema.md"                "$targetDir/resources/qa/qa-task-schema.md"
New-Item -ItemType Directory -Force -Path "$targetDir/resources/toolscan" | Out-Null
Copy-Item "$scriptDir/toolscan/project-tools-schema.md"    "$targetDir/resources/toolscan/project-tools-schema.md"

# Copy BC schemas (agent-read, static)
New-Item -ItemType Directory -Force -Path "$targetDir/resources/ba" | Out-Null
Copy-Item "$scriptDir/ba/user-story-schema.md"            "$targetDir/resources/ba/user-story-schema.md"
Copy-Item "$scriptDir/ba/implemented-feature-schema.md"   "$targetDir/resources/ba/implemented-feature-schema.md"
New-Item -ItemType Directory -Force -Path "$targetDir/resources/design" | Out-Null
Copy-Item "$scriptDir/design/design-doc-schema.md"        "$targetDir/resources/design/design-doc-schema.md"
Copy-Item "$scriptDir/qa/known-test-case-schema.md"       "$targetDir/resources/qa/known-test-case-schema.md"
New-Item -ItemType Directory -Force -Path "$targetDir/resources/dep" | Out-Null
Copy-Item "$scriptDir/dep/deployment-context-schema.md"   "$targetDir/resources/dep/deployment-context-schema.md"
Copy-Item "$scriptDir/dev/system-context-schema.md"       "$targetDir/resources/dev/system-context-schema.md"

$tcSource = "$scriptDir/tool-catalog/$Language/tool-catalog.md"
if (Test-Path $tcSource) {
    Copy-Item $tcSource "$targetDir/resources/$Language/tool-catalog.md"
} else {
    Write-Warning "No tool-catalog found for '$Language'. Add one to resources/$Language/tool-catalog.md and re-run the install script."
}
Copy-Item "$scriptDir/qa/qa.example.secrets.env"           "$targetDir/secrets/qa.example.secrets.env"

# Copy read-config hook script
New-Item -ItemType Directory -Force -Path "$targetDir/scripts" | Out-Null
Copy-Item "$PSScriptRoot/read-config.ps1"              "$targetDir/scripts/read-config.ps1"
Copy-Item "$PSScriptRoot/read-project-tools.ps1"      "$targetDir/scripts/read-project-tools.ps1"

# Copy task-state script (PowerShell)
New-Item -ItemType Directory -Force -Path "$targetDir/scripts/dev" | Out-Null
Copy-Item "$scriptDir/dev/powershell/task-state.ps1"       "$targetDir/scripts/dev/task-state.ps1"
Copy-Item "$scriptDir/dev/powershell/unit-file-size.ps1"   "$targetDir/scripts/dev/unit-file-size.ps1"

# Copy QA credential scripts
$qaSrc = Join-Path (Join-Path $scriptDir 'qa') 'powershell'
New-Item -ItemType Directory -Force -Path "$targetDir/scripts/qa" | Out-Null
Copy-Item "$qaSrc/load-qa-secrets.ps1"              "$targetDir/scripts/qa/load-qa-secrets.ps1"
Copy-Item "$qaSrc/list-qa-secrets.ps1"              "$targetDir/scripts/qa/list-qa-secrets.ps1"
Copy-Item "$qaSrc/qa-session-init.ps1"              "$targetDir/scripts/qa/qa-session-init.ps1"
Copy-Item "$qaSrc/invoke-http.ps1"                  "$targetDir/scripts/qa/invoke-http.ps1"

# Copy toolscan scripts
$toolscanSrc = Join-Path (Join-Path $scriptDir 'toolscan') 'powershell'
New-Item -ItemType Directory -Force -Path "$targetDir/scripts/toolscan" | Out-Null
Copy-Item "$toolscanSrc/cleanup-project-tools.ps1"      "$targetDir/scripts/toolscan/cleanup-project-tools.ps1"
Copy-Item "$toolscanSrc/get-timestamp.ps1"              "$targetDir/scripts/toolscan/get-timestamp.ps1"
Copy-Item "$toolscanSrc/probe-validators.ps1"           "$targetDir/scripts/toolscan/probe-validators.ps1"

# Copy system-context CLI scripts (PowerShell) - 6 scripts + shared helper (tests excluded)
$scSrc = Join-Path (Join-Path (Join-Path $scriptDir 'dev') 'powershell') 'system-context'
New-Item -ItemType Directory -Force -Path "$targetDir/scripts/system-context" | Out-Null
foreach ($s in @('_sc-common', 'components', 'edges', 'behaviors', 'decisions', 'domains', 'blast-radius')) {
    Copy-Item "$scSrc/$s.ps1"                           "$targetDir/scripts/system-context/$s.ps1"
}

# Copy workflow scripts (PowerShell) - outer SDLC workflow + inner DEV+QA cycle (tests excluded)
$wfSrc = Join-Path $PSScriptRoot 'workflow'
New-Item -ItemType Directory -Force -Path "$targetDir/scripts/workflow" | Out-Null
foreach ($s in @('workflow-state', 'workflow-next-step', 'dev-qa-cycle-state', 'dev-qa-next-step')) {
    Copy-Item "$wfSrc/$s.ps1"                           "$targetDir/scripts/workflow/$s.ps1"
}

$tdSource = "$scriptDir/tool-discovery/$Language/tool-discovery.md"
if (Test-Path $tdSource) {
    Copy-Item $tdSource "$targetDir/resources/$Language/tool-discovery.md"
} else {
    Write-Warning "No tool-discovery spec found for '$Language'. Add one to .sda/resources/$Language/ later."
}

# Seed BA gate templates (project-customizable governance) into the durable
# standards root. Uses the default paths.baStandards (docs/standards); seeded
# only when absent, so re-running setup never clobbers project customizations.
# If a project reconfigures baStandards, move these files to the new path.
$baStandards = 'docs/standards'
New-Item -ItemType Directory -Force -Path $baStandards | Out-Null
foreach ($g in @('definition-of-ready', 'definition-of-done', 'global-nfr')) {
    $dest = Join-Path $baStandards "$g.md"
    if (-not (Test-Path $dest)) { Copy-Item "$scriptDir/ba/$g.md" $dest }
}

Write-Host "SDA scaffolding complete: $targetDir/"
