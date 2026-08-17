#!/usr/bin/env bash
set -euo pipefail

DecisionsRoot="${1:?}"

if [ ! -d "$DecisionsRoot" ]; then
    echo "$DecisionsRoot | decisions-root | MISSING"
    exit 1
fi

issues=0

report() {
    local file="$1" check="$2" status="$3"
    echo "$file | $check | $status"
    if [ "$status" != "ok" ]; then
        issues=$((issues + 1))
    fi
}

declare -A referenced

while IFS= read -r idx; do
    dir="$(cd "$(dirname "$idx")" && pwd)"
    declare -A seen=()
    while IFS= read -r line; do
        if [[ "$line" =~ \[[^]]+\]\(([^)]+)\) ]]; then
            target="${BASH_REMATCH[1]%%#*}"
            [ -z "$target" ] && continue
            case "$target" in
                *://*) continue ;;
            esac
            if [[ "$target" = /* ]]; then
                resolved="$target"
            else
                resolved="$(cd "$dir" && printf '%s/%s' "$PWD" "$target")"
            fi
            if [ ! -e "$resolved" ]; then
                report "$idx" "broken-link: $target" "broken"
            fi
            if [[ -n "${seen[$resolved]:-}" ]]; then
                report "$idx" "duplicate-row: $target" "duplicate"
            fi
            seen["$resolved"]=1
            referenced["$resolved"]=1
        fi
    done < "$idx"
done < <(find "$DecisionsRoot" -type f -name 'index.md' | sort)

while IFS= read -r topic; do
    [ "$(basename "$topic")" = "index.md" ] && continue
    resolved="$(cd "$(dirname "$topic")" && printf '%s/%s' "$PWD" "$(basename "$topic")")"
    if [[ -z "${referenced[$resolved]:-}" ]]; then
        report "$topic" "orphan" "orphan"
    fi
done < <(find "$DecisionsRoot" -type f -name '*.md')

if [ "$issues" -eq 0 ]; then
    echo "$DecisionsRoot | integrity | clean"
fi

exit $((issues > 0))
