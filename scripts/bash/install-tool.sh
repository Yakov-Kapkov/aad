#!/usr/bin/env bash
# Installs a tool's agent and prompt files in the target .copilot folder.
#
# If the source tool contains _installation/bash/install.sh, that script is invoked
# with the target base and any extra arguments. Otherwise agents and prompts
# are copied using the default logic.
#
# Usage: install-tool.sh -n <name> [-t <target-base>] [-a <agent1,agent2,...>] [-e <agent1,agent2,...>] [-- extra-args...]
#   -n  Tool name (e.g. sda)
#   -t  Path to .copilot folder (default: $HOME/.copilot)
#   -a  Comma-separated list of agent basenames to install (without .agent.md)
#   -e  Comma-separated list of agent basenames to exclude (without .agent.md)
#   --  Everything after -- is passed to custom scripts/install.sh

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TARGET_BASE="$HOME/.copilot"
NAME=""
AGENT_FILTER=""
AGENT_EXCLUDE=""

# ── Parse arguments ──────────────────────────────────────────────────────────────
while getopts "n:t:a:e:" opt; do
    case $opt in
        n) NAME="$OPTARG" ;;
        t) TARGET_BASE="$OPTARG" ;;
        a) AGENT_FILTER="$OPTARG" ;;
        e) AGENT_EXCLUDE="$OPTARG" ;;
        *) echo "Usage: $0 -n <name> [-t <target-base>] [-a <agent1,agent2,...>] [-e <agent1,agent2,...>] [-- extra-args...]" >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

# Remaining args (after --) are passed to custom install scripts
SCRIPT_ARGS=("$@")

if [ -z "$NAME" ]; then
    echo "Error: -n <name> is required." >&2
    exit 1
fi

# ── Paths ────────────────────────────────────────────────────────────────────
TOOL_SRC="$REPO_ROOT/tools/$NAME"
AGENTS_SRC="$TOOL_SRC/agents"
PROMPTS_SRC="$TOOL_SRC/prompts"
AGENTS_DST="$TARGET_BASE/agents"
PROMPTS_DST="$TARGET_BASE/prompts"

# ── Custom install script? ───────────────────────────────────────────────────
CUSTOM_SCRIPT="$TOOL_SRC/_installation/bash/install.sh"
if [ -f "$CUSTOM_SCRIPT" ]; then
    echo "=== Installing tool: $NAME (custom) ==="
    PASS_ARGS=("$TARGET_BASE")
    if [ -n "$AGENT_FILTER" ]; then
        PASS_ARGS+=("-a" "$AGENT_FILTER")
    fi
    if [ -n "$AGENT_EXCLUDE" ]; then
        PASS_ARGS+=("-e" "$AGENT_EXCLUDE")
    fi
    bash "$CUSTOM_SCRIPT" "${PASS_ARGS[@]}" "${SCRIPT_ARGS[@]+"${SCRIPT_ARGS[@]}"}"
    echo "  Done."
    echo
    exit 0
fi

# ── Default: copy agents + prompts ───────────────────────────────────────────

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
    echo "Warning: No agent or prompt files found in tools/$NAME. Nothing to do." >&2
    exit 0
fi

echo "=== Installing tool: $NAME ==="

# DELETE
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

# COPY
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

echo "  Done."
echo
