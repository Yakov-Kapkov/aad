#!/usr/bin/env bash
# write-config.sh
# Normalizes .sda/project-config.json against the template, then applies
# user answers for the fields that were configured in this session.
#
# Usage:
#   bash write-config.sh \
#       <template-file> \
#       <config-file> \
#       <coverage-enabled: true|false|keep>
#
# Pass "keep" for any field the user declined to reconfigure.
# Requires: python3 (used for JSON manipulation)

set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "Usage: write-config.sh <template> <config> <coverage-enabled>" >&2
  exit 1
fi

TEMPLATE_FILE="$1"
CONFIG_FILE="$2"
COVERAGE_ENABLED="$3"

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

# Step 2: Remove stale fields not in template
def remove_stale(target, source):
    stale = [k for k in target if k not in source]
    for k in stale:
        del target[k]
    for key, val in source.items():
        if isinstance(val, dict) and isinstance(target.get(key), dict):
            remove_stale(target[key], val)

remove_stale(config, template)

# Step 3: Apply user answers
def to_bool(v):
    return v.lower() == 'true'

if "$COVERAGE_ENABLED" != "keep":
    config["tests"]["coverage"]["enabled"] = to_bool("$COVERAGE_ENABLED")

# Set task-state script path for this platform
config["scripts"]["taskState"] = ".sda/scripts/dev/task-state.sh"
config["scripts"]["loadQaSecrets"] = ".sda/scripts/qa/load-qa-secrets.sh"
config["scripts"]["listQaSecrets"] = ".sda/scripts/qa/list-qa-secrets.sh"
config["scripts"]["qaSessionInit"] = ".sda/scripts/qa/qa-session-init.sh"
config["scripts"]["invokeHttp"]    = ".sda/scripts/qa/invoke-http.sh"

with open("$CONFIG_FILE", "w") as f:
    json.dump(config, f, indent=2)

print("project-config.json written: $CONFIG_FILE")
PYEOF
