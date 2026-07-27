#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: setup.sh <language>" >&2
  exit 1
fi

LANGUAGE="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
TARGET_DIR=".sda"

# Create folder structure
mkdir -p "$TARGET_DIR/resources/$LANGUAGE"
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
cp "$ASSETS_DIR/dev/task-schema.md"                  "$TARGET_DIR/resources/dev/task-schema.md"
cp "$ASSETS_DIR/dev/dev-report-schema.md"            "$TARGET_DIR/resources/dev/dev-report-schema.md"
mkdir -p "$TARGET_DIR/resources/qa"
cp "$ASSETS_DIR/qa/qa-task-schema.md"                "$TARGET_DIR/resources/qa/qa-task-schema.md"
mkdir -p "$TARGET_DIR/resources/toolscan"
cp "$ASSETS_DIR/toolscan/project-tools-schema.md"    "$TARGET_DIR/resources/toolscan/project-tools-schema.md"

TC_SOURCE="$ASSETS_DIR/tool-catalog/$LANGUAGE/tool-catalog.md"
if [ -f "$TC_SOURCE" ]; then
  cp "$TC_SOURCE" "$TARGET_DIR/resources/$LANGUAGE/tool-catalog.md"
else
  echo "WARNING: No tool-catalog found for '$LANGUAGE'. Add one to resources/$LANGUAGE/tool-catalog.md and re-run the install script."
fi
cp "$ASSETS_DIR/qa/qa.example.secrets.env"           "$TARGET_DIR/secrets/qa.example.secrets.env"

# Copy read-config hook script
cp "$SCRIPT_DIR/read-config.sh"                      "$TARGET_DIR/scripts/read-config.sh"
chmod +x "$TARGET_DIR/scripts/read-config.sh"
cp "$SCRIPT_DIR/read-project-tools.sh"               "$TARGET_DIR/scripts/read-project-tools.sh"
chmod +x "$TARGET_DIR/scripts/read-project-tools.sh"

# Copy task-state script (bash)
mkdir -p "$TARGET_DIR/scripts/dev"
cp "$ASSETS_DIR/dev/bash/task-state.sh"              "$TARGET_DIR/scripts/dev/task-state.sh"
chmod +x "$TARGET_DIR/scripts/dev/task-state.sh"
cp "$ASSETS_DIR/dev/bash/unit-file-size.sh"          "$TARGET_DIR/scripts/dev/unit-file-size.sh"
chmod +x "$TARGET_DIR/scripts/dev/unit-file-size.sh"

# Copy QA credential scripts
QA_SRC="$ASSETS_DIR/qa/bash"
mkdir -p "$TARGET_DIR/scripts/qa"
cp "$QA_SRC/load-qa-secrets.sh"               "$TARGET_DIR/scripts/qa/load-qa-secrets.sh"
chmod +x "$TARGET_DIR/scripts/qa/load-qa-secrets.sh"
cp "$QA_SRC/list-qa-secrets.sh"               "$TARGET_DIR/scripts/qa/list-qa-secrets.sh"
chmod +x "$TARGET_DIR/scripts/qa/list-qa-secrets.sh"
cp "$QA_SRC/qa-session-init.sh"               "$TARGET_DIR/scripts/qa/qa-session-init.sh"
chmod +x "$TARGET_DIR/scripts/qa/qa-session-init.sh"
cp "$QA_SRC/invoke-http.sh"                   "$TARGET_DIR/scripts/qa/invoke-http.sh"
chmod +x "$TARGET_DIR/scripts/qa/invoke-http.sh"

# Copy toolscan scripts
TOOLSCAN_SRC="$ASSETS_DIR/toolscan/bash"
mkdir -p "$TARGET_DIR/scripts/toolscan"
cp "$TOOLSCAN_SRC/cleanup-project-tools.sh"        "$TARGET_DIR/scripts/toolscan/cleanup-project-tools.sh"
cp "$TOOLSCAN_SRC/get-timestamp.sh"                "$TARGET_DIR/scripts/toolscan/get-timestamp.sh"
cp "$TOOLSCAN_SRC/probe-validators.sh"             "$TARGET_DIR/scripts/toolscan/probe-validators.sh"
chmod +x "$TARGET_DIR/scripts/toolscan/cleanup-project-tools.sh"
chmod +x "$TARGET_DIR/scripts/toolscan/get-timestamp.sh"
chmod +x "$TARGET_DIR/scripts/toolscan/probe-validators.sh"

TD_SOURCE="$ASSETS_DIR/tool-discovery/$LANGUAGE/tool-discovery.md"
if [ -f "$TD_SOURCE" ]; then
  cp "$TD_SOURCE" "$TARGET_DIR/resources/$LANGUAGE/tool-discovery.md"
else
  echo "WARNING: No tool-discovery spec found for '$LANGUAGE'. Add one to .sda/resources/$LANGUAGE/ later."
fi

echo "SDA scaffolding complete: $TARGET_DIR/"
