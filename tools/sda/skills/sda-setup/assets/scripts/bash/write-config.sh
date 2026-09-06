#!/usr/bin/env bash
# write-config.sh
# Normalizes .sda/project-config.json against the template:
# adds missing fields, preserves existing values.
#
# Usage:
#   bash write-config.sh \
#       <template-file> \
#       <config-file>
#
# Adds fields missing from the config. Existing field values are preserved.
# Requires: python3 (used for JSON manipulation)

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: write-config.sh <template> <config>" >&2
  exit 1
fi

TEMPLATE_FILE="$1"
CONFIG_FILE="$2"

python3 - <<PYEOF
import json, sys, os

with open("$TEMPLATE_FILE") as f:
    template = json.load(f)

# Load existing config or start empty
if os.path.exists("$CONFIG_FILE"):
    with open("$CONFIG_FILE") as f:
        config = json.load(f)
else:
    config = {}

# Step 1: Add missing fields from template (deep merge)
def merge_defaults(target, source):
    for key, val in source.items():
        if key not in target:
            target[key] = val
        elif isinstance(val, dict) and isinstance(target.get(key), dict):
            merge_defaults(target[key], val)

merge_defaults(config, template)

# Step 2: Set platform script paths (never override user values)
# Set each path only when missing or still at a shipped default.
SHIPPED = {
    "taskState":     (".sda/scripts/dev/task-state.ps1",     ".sda/scripts/dev/task-state.sh"),
    "loadQaSecrets": (".sda/scripts/qa/load-qa-secrets.ps1", ".sda/scripts/qa/load-qa-secrets.sh"),
    "listQaSecrets": (".sda/scripts/qa/list-qa-secrets.ps1", ".sda/scripts/qa/list-qa-secrets.sh"),
    "qaSessionInit": (".sda/scripts/qa/qa-session-init.ps1", ".sda/scripts/qa/qa-session-init.sh"),
    "invokeHttp":    (".sda/scripts/qa/invoke-http.ps1",     ".sda/scripts/qa/invoke-http.sh"),
}
PLATFORM = {
    "taskState":     ".sda/scripts/dev/task-state.sh",
    "loadQaSecrets": ".sda/scripts/qa/load-qa-secrets.sh",
    "listQaSecrets": ".sda/scripts/qa/list-qa-secrets.sh",
    "qaSessionInit": ".sda/scripts/qa/qa-session-init.sh",
    "invokeHttp":    ".sda/scripts/qa/invoke-http.sh",
}
scripts = config.setdefault("scripts", {})
for key, platform_value in PLATFORM.items():
    current = scripts.get(key)
    if current is None or current in SHIPPED[key]:
        scripts[key] = platform_value

with open("$CONFIG_FILE", "w") as f:
    json.dump(config, f, indent=2)

print("project-config.json written: $CONFIG_FILE")
PYEOF
