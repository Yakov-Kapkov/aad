#!/usr/bin/env bash
# Patches model: lines in agent frontmatter YAML.
#
# Walks each "agentname=model" argument, finds the installed .agent.md
# file under <target-base>/agents/, and updates or inserts the model: line.
#
# Usage: set-agent-models.sh <target-base> [agent=model ...]
#   $1           Path to .copilot folder containing agents/
#   agent=model  One or more "agentname=model" assignments
#                Example: set-agent-models.sh ~/.copilot "commit=Claude Haiku 4.5" "sda-dev=Claude Opus 4"

set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <target-base> [agent=model ...]" >&2
    exit 1
fi

TARGET_BASE="$1"
shift

if [ "$#" -eq 0 ]; then
    exit 0
fi

AGENTS_DST="$TARGET_BASE/agents"

for assignment in "$@"; do
    agent="${assignment%%=*}"
    model="${assignment#*=}"
    file="$AGENTS_DST/$agent.agent.md"

    if [ ! -f "$file" ]; then
        printf "  %-20s: SKIP (not installed)\n" "$agent"
        continue
    fi

    if grep -q '^model:' "$file"; then
        sed -i.bak "s|^model:.*|model: $model|" "$file" && rm -f "$file.bak"
    elif grep -q '^tools:' "$file"; then
        sed -i.bak "/^tools:/a model: $model" "$file" && rm -f "$file.bak"
    else
        printf "  %-20s: FAIL (no model: or tools: line)\n" "$agent"
        continue
    fi

    printf "  %-20s: OK -> %s\n" "$agent" "$model"
done
