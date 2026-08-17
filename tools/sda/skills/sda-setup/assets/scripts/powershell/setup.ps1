param(
    [Parameter(Mandatory)][string]$Language
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)  # assets folder
$targetDir = '.sda'

# Create folder structure
New-Item -ItemType Directory -Force -Path "$targetDir/resources/$Language" | Out-Null
New-Item -ItemType Directory -Force -Path "$targetDir/issues" | Out-Null
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
New-Item -ItemType Directory -Force -Path "$targetDir/resources/decisions" | Out-Null
Copy-Item "$scriptDir/decisions/decision-topic-schema.md"  "$targetDir/resources/decisions/decision-topic-schema.md"
Copy-Item "$scriptDir/decisions/decision-index-schema.md"  "$targetDir/resources/decisions/decision-index-schema.md"

$tcSource = "$scriptDir/tool-catalog/$Language/tool-catalog.md"
if (Test-Path $tcSource) {
    Copy-Item $tcSource "$targetDir/resources/$Language/tool-catalog.md"
} else {
    Write-Warning "No tool-catalog found for '$Language'. Add one to assets/tool-catalog/$Language/tool-catalog.md and re-run the install script."
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

$decisionsSrc = Join-Path (Join-Path $scriptDir 'decisions') 'powershell'
New-Item -ItemType Directory -Force -Path "$targetDir/scripts/decisions" | Out-Null
Copy-Item "$decisionsSrc/docs-integrity.ps1"            "$targetDir/scripts/decisions/docs-integrity.ps1"

$tdSource = "$scriptDir/tool-discovery/$Language/tool-discovery.md"
if (Test-Path $tdSource) {
    Copy-Item $tdSource "$targetDir/resources/$Language/tool-discovery.md"
} else {
    Write-Warning "No tool-discovery spec found for '$Language'. Add one to .sda/resources/$Language/ later."
}

Write-Host "SDA scaffolding complete: $targetDir/"
