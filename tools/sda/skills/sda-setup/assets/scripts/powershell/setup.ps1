$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)  # assets folder
$targetDir = '.sda'

# Create folder structure
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
Copy-Item "$scriptDir/dev/dev-report-schema.md"            "$targetDir/resources/dev/dev-report-schema.md"
New-Item -ItemType Directory -Force -Path "$targetDir/resources/qa" | Out-Null
Copy-Item "$scriptDir/qa/qa-task-schema.md"                "$targetDir/resources/qa/qa-task-schema.md"
New-Item -ItemType Directory -Force -Path "$targetDir/resources/design" | Out-Null
Copy-Item "$scriptDir/design/design-record-schema.md"  "$targetDir/resources/design/design-record-schema.md"
Copy-Item "$scriptDir/design/design-tests-schema.md"   "$targetDir/resources/design/design-tests-schema.md"
New-Item -ItemType Directory -Force -Path "$targetDir/resources/ba" | Out-Null
Copy-Item "$scriptDir/ba/user-story-schema.md"            "$targetDir/resources/ba/user-story-schema.md"

Copy-Item "$scriptDir/qa/qa.example.secrets.env"           "$targetDir/secrets/qa.example.secrets.env"

# Copy read-config hook script
New-Item -ItemType Directory -Force -Path "$targetDir/scripts" | Out-Null
Copy-Item "$PSScriptRoot/read-config.ps1"              "$targetDir/scripts/read-config.ps1"

# Copy QA credential scripts
$qaSrc = Join-Path (Join-Path $scriptDir 'qa') 'powershell'
New-Item -ItemType Directory -Force -Path "$targetDir/scripts/qa" | Out-Null
Copy-Item "$qaSrc/load-qa-secrets.ps1"              "$targetDir/scripts/qa/load-qa-secrets.ps1"
Copy-Item "$qaSrc/list-qa-secrets.ps1"              "$targetDir/scripts/qa/list-qa-secrets.ps1"
Copy-Item "$qaSrc/qa-session-init.ps1"              "$targetDir/scripts/qa/qa-session-init.ps1"
Copy-Item "$qaSrc/invoke-http.ps1"                  "$targetDir/scripts/qa/invoke-http.ps1"

# --- Remove artifacts retired by earlier versions ---
# Setup only creates and copies, so a path that moved or was replaced leaves a
# stale copy behind in an existing install. Each entry is a shipped location.
$legacyPaths = @(
    "$targetDir/scripts/decisions"                     # docs-integrity's first location
    "$targetDir/scripts/docs"                          # docs-integrity's second location — the checkers now ship in the docs skills
    "$targetDir/scripts/dev"                           # task-state + unit-file-size retired with the task layer
    "$targetDir/resources/dev/task-schema.md"          # task layer retired
    "$targetDir/resources/design/design-report-schema.md"  # replaced by design-record-schema.md
    "$targetDir/project-tools.md"                      # toolchain scan output
    "$targetDir/project-tools_backup.md"               # toolchain scan backup
    "$targetDir/scripts/toolscan"                      # toolscan scripts retired
    "$targetDir/resources/toolscan"                    # project-tools schema retired
    "$targetDir/scripts/read-project-tools.ps1"        # command lookup retired
    "$targetDir/scripts/read-project-tools.sh"         # command lookup retired
    "$targetDir/scripts/workflow"                      # the workflow script now ships in sda-workflow-guide
    "$targetDir/resources/workflow"                    # the workflow schemas now ship in sda-workflow-guide
)
foreach ($legacy in $legacyPaths) {
    if (Test-Path $legacy) {
        Remove-Item -Recurse -Force $legacy
        Write-Output "Removed retired path: $legacy"
    }
}

# Retired tool assets live in per-language resource folders
Get-ChildItem -Path "$targetDir/resources" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @('tool-catalog.md', 'tool-discovery.md') } |
    ForEach-Object { Remove-Item $_.FullName -Force; Write-Output "Removed retired path: $($_.FullName)" }

Write-Output "SDA scaffolding complete: $targetDir/"
