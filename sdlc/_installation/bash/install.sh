#!/usr/bin/env bash
# Custom install script for the SDA tool.
#
# Copies agent and prompt files, then optionally patches model: in agent
# frontmatter when --models is provided.
#
# Usage: install.sh <target-base> [-a <agent1,agent2,...>] [-e <agent1,agent2,...>] [pipe-delimited-models]
#   $1           Path to .copilot folder
#   -a           Comma-separated agent basenames (optional filter)
#   -e           Comma-separated agent basenames to exclude
#   models       Pipe-delimited "agentname=model" assignments (e.g. "sda-dev=Claude Opus 4|sda-coder=Claude Haiku 4.5")

set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <target-base> [-a <filter>] [--models agent=model ...]" >&2
    exit 1
fi

TARGET_BASE="$1"
shift

AGENT_FILTER=""
AGENT_EXCLUDE=""
SCRIPT_ARGS=""

# ── Parse arguments ────────────────────────────────────────────────────────────────────────
while [ "$#" -gt 0 ]; do
    case "$1" in
        -a) AGENT_FILTER="$2"; shift 2 ;;
        -e) AGENT_EXCLUDE="$2"; shift 2 ;;
        *) SCRIPT_ARGS="$1"; shift ;;
    esac
done

# Parse models from pipe-delimited string
MODELS=()
if [ -n "$SCRIPT_ARGS" ]; then
    IFS='|' read -ra MODELS <<< "$SCRIPT_ARGS"
fi

# ── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_SRC="$(dirname "$(dirname "$SCRIPT_DIR")")"  # up from _installation/bash/
AGENTS_SRC="$TOOL_SRC/agents"
PROMPTS_SRC="$TOOL_SRC/prompts"
AGENTS_DST="$TARGET_BASE/agents"
PROMPTS_DST="$TARGET_BASE/prompts"

# ── Discover source files ────────────────────────────────────────────────────
AGENT_FILES=()
if [ -d "$AGENTS_SRC" ]; then
    while IFS= read -r -d '' f; do
        AGENT_FILES+=("$(basename "$f")")
    done < <(find "$AGENTS_SRC" -maxdepth 1 -name '*.agent.md' -print0 2>/dev/null)
fi

PROMPT_FILES=()
if [ -d "$PROMPTS_SRC" ]; then
    while IFS= read -r -d '' f; do
        PROMPT_FILES+=("$(basename "$f")")
    done < <(find "$PROMPTS_SRC" -maxdepth 1 -name '*.prompt.md' -print0 2>/dev/null)
fi

# ── Apply agent filter ───────────────────────────────────────────────────────
if [ -n "$AGENT_FILTER" ]; then
    IFS=',' read -ra ALLOWED <<< "$AGENT_FILTER"
    FILTERED=()
    for af in "${AGENT_FILES[@]}"; do
        base="${af%.agent.md}"
        for allow in "${ALLOWED[@]}"; do
            if [ "$base" = "$allow" ]; then
                FILTERED+=("$af")
                break
            fi
        done
    done
    AGENT_FILES=("${FILTERED[@]+"${FILTERED[@]}"}")
fi

# ── Apply agent exclude ──────────────────────────────────────────────────────
if [ -n "$AGENT_EXCLUDE" ]; then
    IFS=',' read -ra EXCLUDED <<< "$AGENT_EXCLUDE"
    FILTERED=()
    for af in "${AGENT_FILES[@]}"; do
        base="${af%.agent.md}"
        skip=false
        for excl in "${EXCLUDED[@]}"; do
            if [ "$base" = "$excl" ]; then
                skip=true
                break
            fi
        done
        if [ "$skip" = false ]; then
            FILTERED+=("$af")
        fi
    done
    AGENT_FILES=("${FILTERED[@]+"${FILTERED[@]}"}")
fi

if [ ${#AGENT_FILES[@]} -eq 0 ] && [ ${#PROMPT_FILES[@]} -eq 0 ]; then
    echo "Warning: No agent or prompt files found. Nothing to do." >&2
    exit 0
fi

# ── Delete existing ──────────────────────────────────────────────────────────
echo "  Delete:"
for f in "${AGENT_FILES[@]}"; do
    target="$AGENTS_DST/$f"
    if [ -f "$target" ]; then
        rm -f "$target"
        echo "    agents/$f"
    fi
done
for f in "${PROMPT_FILES[@]}"; do
    target="$PROMPTS_DST/$f"
    if [ -f "$target" ]; then
        rm -f "$target"
        echo "    prompts/$f"
    fi
done

# ── Copy ─────────────────────────────────────────────────────────────────────
echo "  Copy:"
mkdir -p "$AGENTS_DST" "$PROMPTS_DST"
for f in "${AGENT_FILES[@]}"; do
    cp "$AGENTS_SRC/$f" "$AGENTS_DST/$f"
    echo "    agents/$f"
done
for f in "${PROMPT_FILES[@]}"; do
    cp "$PROMPTS_SRC/$f" "$PROMPTS_DST/$f"
    echo "    prompts/$f"
done

# ── Patch models ─────────────────────────────────────────────────────────────
if [ ${#MODELS[@]} -gt 0 ]; then
    echo "  Patch models:"
    REPO_ROOT="$(dirname "$(dirname "$TOOL_SRC")")"  # up from tools/sda/ to repo root
    "$REPO_ROOT/scripts/bash/set-agent-models.sh" "$TARGET_BASE" "${MODELS[@]}"
fi
