#!/usr/bin/env bash
# Custom install script for the standards-compliance skill.
#
# Copies the skill folder, then assembles per-language standards from
# resources/{lang}/standards/ and common-standards.md into the destination.
#
# Usage: install.sh <dest-folder>

set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <dest-folder>" >&2
    exit 1
fi

DEST_FOLDER="$1"

# ── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_SRC="$(dirname "$(dirname "$SCRIPT_DIR")")"        # up from _installation/bash/
REPO_ROOT="$(dirname "$(dirname "$SKILL_SRC")")"         # repo root
RESOURCE_SRC="$REPO_ROOT/resources"

# ── Step 1: Clean copy of skill folder ───────────────────────────────────────
echo "  Delete:"
if [ -d "$DEST_FOLDER" ]; then
    rm -rf "$DEST_FOLDER"
    echo "    $DEST_FOLDER"
else
    echo "    (nothing to delete)"
fi

echo "  Copy skill:"
mkdir -p "$DEST_FOLDER"
for item in "$SKILL_SRC"/*; do
    [ -e "$item" ] || continue
    [ "$(basename "$item")" = "_installation" ] && continue
    cp -r "$item" "$DEST_FOLDER/"
done
find "$SKILL_SRC" -type f -not -path "$SKILL_SRC/_installation/*" | while read -r file; do
    rel="${file#"$SKILL_SRC"/}"
    echo "    $rel"
done

# ── Step 2: Copy common-standards.md ─────────────────────────────────────────
COMMON_SRC="$RESOURCE_SRC/common-standards.md"
STANDARDS_DST="$DEST_FOLDER/standards"
if [ -f "$COMMON_SRC" ]; then
    mkdir -p "$STANDARDS_DST"
    cp "$COMMON_SRC" "$STANDARDS_DST/"
    echo "    standards/common-standards.md"
else
    echo "Warning: Common standards not found: $COMMON_SRC" >&2
fi

# ── Step 3: Copy per-language standards ──────────────────────────────────────
echo "  Copy standards:"
for dir in "$RESOURCE_SRC"/*/; do
    lang="$(basename "$dir")"
    src="$dir/standards"
    if [ -d "$src" ]; then
        dst="$DEST_FOLDER/standards/$lang"
        mkdir -p "$dst"
        for file in "$src"/*; do
            [ -f "$file" ] || continue
            cp "$file" "$dst/"
            echo "    standards/$lang/$(basename "$file")"
        done
    fi
done
