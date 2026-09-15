#!/usr/bin/env bash
# Installs a skill folder in the target .copilot folder.
#
# If the source skill contains _installation/bash/install.sh, that script is invoked
# with the destination folder and any extra arguments. Otherwise the skill
# folder is copied as-is.
#
# Either way, development-only test files ('_*.Tests.*') are pruned from the
# installed copy - tests never ship.
#
# Usage: install-skill.sh -n <name> [-t <target-base>] [-s <source-path>] [-- extra-args...]
#   -n  Skill name (e.g. commit, standards-compliance)
#   -t  Path to .copilot folder (default: $HOME/.copilot)
#   -s  Optional override for the source skill folder
#   --  Everything after -- is passed to custom scripts/install.sh

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TARGET_BASE="$HOME/.copilot"
NAME=""
SOURCE_PATH=""

# ── Parse arguments ──────────────────────────────────────────────────────────
while getopts "n:t:s:" opt; do
    case $opt in
        n) NAME="$OPTARG" ;;
        t) TARGET_BASE="$OPTARG" ;;
        s) SOURCE_PATH="$OPTARG" ;;
        *) echo "Usage: $0 -n <name> [-t <target-base>] [-s <source-path>] [-- extra-args...]" >&2; exit 1 ;;
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
if [ -n "$SOURCE_PATH" ]; then
    SKILL_SRC="$REPO_ROOT/$SOURCE_PATH"
else
    SKILL_SRC="$REPO_ROOT/skills/$NAME"
fi
SKILL_DST="$TARGET_BASE/skills/$NAME"

if [ ! -d "$SKILL_SRC" ]; then
    echo "Warning: Source skill folder not found: $SKILL_SRC. Nothing to do." >&2
    exit 0
fi

# ── Custom install script? ───────────────────────────────────────────────────
# Tests never ship: '_<subject>.Tests.<ext>' is development-only. They sit beside
# the code they test, at any depth, so the installed copy is pruned rather than
# filtered at the top level only. A skill's own _installation script does its own
# copying, so the prune runs on both paths.
TEST_PATTERN='_*.Tests.*'
prune_tests() {
    [ -d "$1" ] || return 0
    find "$1" -type f -name "$TEST_PATTERN" -delete
}

CUSTOM_SCRIPT="$SKILL_SRC/_installation/bash/install.sh"
if [ -f "$CUSTOM_SCRIPT" ]; then
    echo "=== Installing skill: $NAME (custom) ==="
    bash "$CUSTOM_SCRIPT" "$SKILL_DST" "${SCRIPT_ARGS[@]+"${SCRIPT_ARGS[@]}"}"
    prune_tests "$SKILL_DST"
    echo "  Done."
    echo
    exit 0
fi

# ── Default: delete + copy ───────────────────────────────────────────────────
echo "=== Installing skill: $NAME ==="

echo "  Delete:"
if [ -d "$SKILL_DST" ]; then
    rm -rf "$SKILL_DST"
    echo "    $SKILL_DST"
else
    echo "    (nothing to delete)"
fi

echo "  Copy:"
mkdir -p "$SKILL_DST"
for item in "$SKILL_SRC"/*; do
    [ -e "$item" ] || continue
    [ "$(basename "$item")" = "_installation" ] && continue
    cp -r "$item" "$SKILL_DST/"
done

prune_tests "$SKILL_DST"

find "$SKILL_SRC" -type f -not -path "$SKILL_SRC/_installation/*" \
     -not -name "$TEST_PATTERN" | while read -r file; do
    rel="${file#"$SKILL_SRC"/}"
    echo "    $rel"
done

echo "  Done."
echo
