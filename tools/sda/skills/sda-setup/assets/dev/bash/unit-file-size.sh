#!/usr/bin/env bash
# unit-file-size.sh - Reports file sizes for SDA unit pre-flight checks.
#
# task   mode: prints a table of Path, Exists, Lines for informed unit splitting.
# verify mode: prints PASS or FAIL based on whether the total line count of
#              existing files exceeds the configured limit.
#
# Usage:
#   unit-file-size.sh -Mode task   -Paths 'file1,file2,...'
#   unit-file-size.sh -Mode verify -Paths 'file1,file2,...' [-Limit <n>]

set -euo pipefail

MODE=''
LIMIT=1000
PATHS_STR=''

while [[ $# -gt 0 ]]; do
    case "$1" in
        -Mode)  MODE="$2";  shift 2 ;;
        -Limit) LIMIT="$2"; shift 2 ;;
        -Paths) PATHS_STR="$2"; shift 2 ;;
        *)
            printf "Unknown argument: %s\n" "$1" >&2
            exit 1 ;;
    esac
done

if [[ -z "$MODE" || -z "$PATHS_STR" ]]; then
    printf "Usage: unit-file-size.sh -Mode <task|verify> -Paths 'file1;file2;...' [-Limit <n>]\n" >&2
    exit 1
fi

IFS=',' read -ra PATHS <<< "$PATHS_STR"

total_lines=0
missing_count=0
missing_list=()
row_paths=()
row_exists=()
row_lines=()

for p in "${PATHS[@]}"; do
    if [[ -f "$p" ]]; then
        lines=$(wc -l < "$p")
        row_paths+=("$p")
        row_exists+=("true")
        row_lines+=("$lines")
        total_lines=$((total_lines + lines))
    else
        row_paths+=("$p")
        row_exists+=("false")
        row_lines+=("0")
        missing_count=$((missing_count + 1))
        missing_list+=("$p")
    fi
done

case "$MODE" in
    task)
        printf "%-70s  %-8s  %s\n" "Path" "Exists" "Lines"
        printf "%-70s  %-8s  %s\n" "----------------------------------------------------------------------" "--------" "-----"
        for i in "${!row_paths[@]}"; do
            printf "%-70s  %-8s  %s\n" "${row_paths[$i]}" "${row_exists[$i]}" "${row_lines[$i]}"
        done
        ;;
    verify)
        if [[ $missing_count -gt 0 ]]; then
            joined=$(printf ', %s' "${missing_list[@]}"); joined="${joined:2}"
            note=" ($missing_count new/missing: $joined)"
        else
            note=''
        fi

        if [[ $total_lines -gt $LIMIT ]]; then
            printf "FAIL: %d lines exceeds limit %d%s\n" "$total_lines" "$LIMIT" "$note"
        else
            printf "PASS%s\n" "$note"
        fi
        ;;
    *)
        printf "Unknown mode: %s\n" "$MODE" >&2
        exit 1 ;;
esac
