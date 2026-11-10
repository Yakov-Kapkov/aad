#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
TARGET_DIR=".sda"

# Create folder structure
mkdir -p "$TARGET_DIR/issues"
mkdir -p "$TARGET_DIR/secrets"

# .gitignore — keeps .sda/ out of version control
printf '*' > "$TARGET_DIR/.gitignore"

# secrets/.gitignore — defense in depth: secrets stay ignored even if the
# parent .sda/.gitignore is loosened (e.g. to commit tasks). Keeps the ignore
# rule and the placeholder example tracked; real qa.secrets.env is never committable.
printf '*\n!.gitignore\n!qa.example.secrets.env\n' > "$TARGET_DIR/secrets/.gitignore"

# Copy resource files (byte-for-byte)
mkdir -p "$TARGET_DIR/resources/dev"
cp "$ASSETS_DIR/project-config.example.json"       "$TARGET_DIR/resources/project-config.example.json"
cp "$ASSETS_DIR/project-config.reference.yml"      "$TARGET_DIR/project-config.reference.yml"
cp "$ASSETS_DIR/dev/dev-report-schema.md"            "$TARGET_DIR/resources/dev/dev-report-schema.md"
mkdir -p "$TARGET_DIR/resources/qa"
cp "$ASSETS_DIR/qa/qa-task-schema.md"                "$TARGET_DIR/resources/qa/qa-task-schema.md"
mkdir -p "$TARGET_DIR/resources/design"
cp "$ASSETS_DIR/design/design-record-schema.md"  "$TARGET_DIR/resources/design/design-record-schema.md"
mkdir -p "$TARGET_DIR/resources/ba"
cp "$ASSETS_DIR/ba/user-story-schema.md"            "$TARGET_DIR/resources/ba/user-story-schema.md"

cp "$ASSETS_DIR/qa/qa.example.secrets.env"           "$TARGET_DIR/secrets/qa.example.secrets.env"

# Copy read-config hook script
mkdir -p "$TARGET_DIR/scripts"
cp "$SCRIPT_DIR/read-config.sh"                      "$TARGET_DIR/scripts/read-config.sh"

# Copy QA credential scripts
QA_SRC="$ASSETS_DIR/qa/bash"
mkdir -p "$TARGET_DIR/scripts/qa"
cp "$QA_SRC/load-qa-secrets.sh"               "$TARGET_DIR/scripts/qa/load-qa-secrets.sh"
cp "$QA_SRC/list-qa-secrets.sh"               "$TARGET_DIR/scripts/qa/list-qa-secrets.sh"
cp "$QA_SRC/qa-session-init.sh"               "$TARGET_DIR/scripts/qa/qa-session-init.sh"
cp "$QA_SRC/invoke-http.sh"                   "$TARGET_DIR/scripts/qa/invoke-http.sh"

# The workflow CLI and other .sda scripts run by path, so every copied script
# needs the executable bit — the source mode does not survive every transfer.
find "$TARGET_DIR/scripts" -type f -name '*.sh' -exec chmod +x {} +

# --- Remove artifacts retired by earlier versions ---
# Setup only creates and copies, so a path that moved or was replaced leaves a
# stale copy behind in an existing install. Each entry is a shipped location.
LEGACY_PATHS=(
  "$TARGET_DIR/scripts/decisions"                        # docs-integrity's first location
  "$TARGET_DIR/scripts/docs"                             # docs-integrity's second location — the checkers now ship in the docs skills
  "$TARGET_DIR/scripts/dev"                              # task-state + unit-file-size retired with the task layer
  "$TARGET_DIR/resources/dev/task-schema.md"             # task layer retired
  "$TARGET_DIR/resources/design/design-report-schema.md"  # replaced by design-record-schema.md
  "$TARGET_DIR/project-tools.md"                         # toolchain scan output
  "$TARGET_DIR/project-tools_backup.md"                  # toolchain scan backup
  "$TARGET_DIR/scripts/toolscan"                         # toolscan scripts retired
  "$TARGET_DIR/resources/toolscan"                       # project-tools schema retired
  "$TARGET_DIR/scripts/read-project-tools.ps1"           # command lookup retired
  "$TARGET_DIR/scripts/read-project-tools.sh"            # command lookup retired
  "$TARGET_DIR/scripts/workflow"                         # the workflow script now ships in sda-workflow-guide
  "$TARGET_DIR/resources/workflow"                       # the workflow schemas now ship in sda-workflow-guide
)
for legacy in "${LEGACY_PATHS[@]}"; do
  if [ -e "$legacy" ]; then
    rm -rf "$legacy"
    echo "Removed retired path: $legacy"
  fi
done

# Retired tool assets live in per-language resource folders
for retired in "$TARGET_DIR"/resources/*/tool-catalog.md "$TARGET_DIR"/resources/*/tool-discovery.md; do
  if [ -e "$retired" ]; then
    rm -f "$retired"
    echo "Removed retired path: $retired"
    rmdir "$(dirname "$retired")" 2>/dev/null || true
  fi
done

echo "SDA scaffolding complete: $TARGET_DIR/"
