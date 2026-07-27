#!/usr/bin/env bash
# Installs or uninstalls the dev suite in the user's .copilot folder.
#
# Usage: install-dev-suite.sh [-t <target-base>] [-m "agent=model" ...] [install|uninstall] [full|short]
#   -t         Path to .copilot folder (default: $HOME/.copilot)
#   -m         Model assignment for SDA agents (repeatable). E.g. -m "sda-dev=Claude Opus 4"
#   install    Install the dev suite (default)
#   uninstall  Remove all dev suite files
#   full       All SDA agents
#   short      Core agents only (default)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TARGET_BASE="$HOME/.copilot"
MODELS=()

# ── Parse options ────────────────────────────────────────────────────────────
while getopts "t:m:" opt; do
    case $opt in
        t) TARGET_BASE="$OPTARG" ;;
        m) MODELS+=("$OPTARG") ;;
        *) echo "Usage: $0 [-t <target-base>] [-m agent=model ...] [install|uninstall] [full|short]" >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

# ── Parse positional: action and mode ────────────────────────────────────────
ACTION="install"
MODE="short"
for arg in "$@"; do
    case "$arg" in
        install|uninstall) ACTION="$arg" ;;
        full|short) MODE="$arg" ;;
        *)
            echo "Usage: $0 [-t <target-base>] [-m agent=model ...] [install|uninstall] [full|short]" >&2
            exit 1
            ;;
    esac
done

# ── Colors ───────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
GRAY='\033[0;90m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo
echo -e "${CYAN}Target: $TARGET_BASE${NC}"
echo -e "${CYAN}Action: $ACTION${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# UNINSTALL
# ══════════════════════════════════════════════════════════════════════════════
if [ "$ACTION" = "uninstall" ]; then
    echo
    echo -e "${RED}=== Uninstalling dev suite ===${NC}"

    # SDA agents
    for f in "$TARGET_BASE/agents"/sda-*.agent.md; do
        [ -f "$f" ] && rm -f "$f" && echo "  Removed agents/$(basename "$f")"
    done
    # commit agent
    if [ -f "$TARGET_BASE/agents/commit.agent.md" ]; then
        rm -f "$TARGET_BASE/agents/commit.agent.md"
        echo "  Removed agents/commit.agent.md"
    fi

    # SDA prompts
    for f in "$TARGET_BASE/prompts"/sda_*.prompt.md; do
        [ -f "$f" ] && rm -f "$f" && echo "  Removed prompts/$(basename "$f")"
    done
    # commit prompts
    for f in "$TARGET_BASE/prompts"/commit*.prompt.md; do
        [ -f "$f" ] && rm -f "$f" && echo "  Removed prompts/$(basename "$f")"
    done

    # Skills
    for skill in sda-setup standards-compliance troubleshooting; do
        dir="$TARGET_BASE/skills/$skill"
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            echo "  Removed skills/$skill/"
        fi
    done

    echo
    echo -e "${GREEN}Dev suite uninstalled.${NC}"
    echo
    exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# INSTALL
# ══════════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}Mode:   $MODE${NC}"

echo
echo -e "${CYAN}=== Installing SDA tool ===${NC}"
SDA_ARGS=()
if [ "$MODE" = "short" ]; then
    SDA_ARGS+=("-e" "sda-system,sda-feature")
fi
"$SCRIPT_DIR/install-tool.sh" -t "$TARGET_BASE" -n "sda" ${SDA_ARGS[@]+"${SDA_ARGS[@]}"}

echo
echo -e "${YELLOW}== Installing sda-setup skill ==${NC}"
"$SCRIPT_DIR/install-skill.sh" -t "$TARGET_BASE" -n "sda-setup" -s "tools/sda/skills/sda-setup"
echo -e "${GRAY}  Copying tool-discovery assets...${NC}"
DST="$TARGET_BASE/skills/sda-setup/assets/tool-discovery"
for lang_dir in "$REPO_ROOT/resources"/*/; do
    lang="$(basename "$lang_dir")"
    src="$lang_dir/tool-discovery.md"
    if [ -f "$src" ]; then
        lang_dst="$DST/$lang"
        mkdir -p "$lang_dst"
        cp "$src" "$lang_dst/"
        echo "    $lang/tool-discovery.md"
    fi
done
echo -e "${GRAY}  Copying tool-catalog assets...${NC}"
DST="$TARGET_BASE/skills/sda-setup/assets/tool-catalog"
for lang_dir in "$REPO_ROOT/resources"/*/; do
    lang="$(basename "$lang_dir")"
    src="$lang_dir/tool-catalog.md"
    if [ -f "$src" ]; then
        lang_dst="$DST/$lang"
        mkdir -p "$lang_dst"
        cp "$src" "$lang_dst/"
        echo "    $lang/tool-catalog.md"
    fi
done

echo
echo -e "${YELLOW}== Installing commit agent ==${NC}"
COMMIT_SRC="$REPO_ROOT/agents/commit/commit.agent.md"
COMMIT_DST="$TARGET_BASE/agents"
mkdir -p "$COMMIT_DST"
cp "$COMMIT_SRC" "$COMMIT_DST/commit.agent.md"
echo "  commit.agent.md"

# ── Patch agent models ───────────────────────────────────────────────────────
if [ ${#MODELS[@]} -gt 0 ]; then
    echo
    echo -e "${YELLOW}== Patching agent models ==${NC}"
    "$SCRIPT_DIR/set-agent-models.sh" "$TARGET_BASE" "${MODELS[@]}"
fi

echo
echo -e "${YELLOW}== Installing commit prompts ==${NC}"
PROMPTS_SRC="$REPO_ROOT/prompts/commit"
PROMPTS_DST="$TARGET_BASE/prompts"
mkdir -p "$PROMPTS_DST"
for f in "$PROMPTS_SRC"/*.prompt.md; do
    cp "$f" "$PROMPTS_DST/"
    echo "  $(basename "$f")"
done

echo
echo -e "${YELLOW}== Installing standards-compliance skill ==${NC}"
"$SCRIPT_DIR/install-skill.sh" -t "$TARGET_BASE" -n "standards-compliance"

echo
echo -e "${YELLOW}== Installing troubleshooting skill ==${NC}"
"$SCRIPT_DIR/install-skill.sh" -t "$TARGET_BASE" -n "troubleshooting"

echo
