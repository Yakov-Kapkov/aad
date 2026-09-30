#!/usr/bin/env bash
# Renames .sda/project-tools.md to .sda/project-tools_backup.md before a
# fresh scan, preserving the previous result for reference.

TARGET='.sda/project-tools.md'
BACKUP='.sda/project-tools_backup.md'

if [ -f "$TARGET" ]; then
    mv -f "$TARGET" "$BACKUP"
    echo "Renamed: $TARGET -> $BACKUP"
else
    echo "Not found (nothing to back up): $TARGET"
fi
