#!/usr/bin/env bash
# check-tree.sh - checks a docs tree for default-profile conformance.
#
# Model-bound: assumes the default profile's routing model - an `index.md`
# router per folder, every child routed by its parent's index.
#
# Output contract - one line per finding, then a summary line:
#   <path> | <check> | <status>
# A clean run reports "| tree | clean". Exit code is 1 on any finding.
#
# --root <dir>   The docs tree to check. Required.
#
# duplicate-row is reported per index; orphan is reported for any .md that no
# index references.

set -uo pipefail

ROOT=""

# Held in variables: an inline pattern in [[ =~ ]] gets its escapes re-parsed by
# bash, which rejects the escaped parens.
LINK_RE='\[[^]]+\]\(([^)]+)\)'

fail() {
  printf 'error=%s\n' "$1"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)        printf 'Usage: check-tree.sh --root <dir>\n'; exit 0 ;;
    -r|--root|-Root)  ROOT="${2:-}"; shift 2 ;;
    -*)               fail "unknown option '$1'" ;;
    *)                ROOT="$1"; shift ;;
  esac
done

[ -n "$ROOT" ] || fail "pass --root <dir>"
[ -d "$ROOT" ] || { printf '%s | root | MISSING\n' "$ROOT"; exit 1; }

issues=0

report() {
  printf '%s | %s | %s\n' "$1" "$2" "$3"
  [ "$3" = "ok" ] || issues=$((issues + 1))
}

# Prints the resolved path, or nothing when the target is a URL or an anchor.
resolve_link() {
  local dir="$1" target="${2%%#*}"
  [ -n "$target" ] || return 0
  case "$target" in
    *://*) return 0 ;;
    /*)    printf '%s' "$target" ;;
    *)     printf '%s/%s' "$dir" "$target" ;;
  esac
}

declare -A referenced

while IFS= read -r index; do
  dir="$(cd "$(dirname "$index")" && pwd)"
  declare -A seen=()
  while IFS= read -r line || [ -n "$line" ]; do
    rest="$line"
    while [[ "$rest" =~ $LINK_RE ]]; do
      target="${BASH_REMATCH[1]}"
      rest="${rest#*"${BASH_REMATCH[0]}"}"
      resolved="$(resolve_link "$dir" "$target")"
      [ -n "$resolved" ] || continue
      [ -e "$resolved" ] || report "$index" "broken-link: $target" 'broken'
      [ -z "${seen[$resolved]:-}" ] || report "$index" "duplicate-row: $target" 'duplicate'
      seen["$resolved"]=1
      referenced["$resolved"]=1
    done
  done < "$index"
done < <(find "$ROOT" -type f -name 'index.md' | sort)

while IFS= read -r doc; do
  base="$(basename "$doc")"
  [ "$base" = "index.md" ] && continue
  full="$(cd "$(dirname "$doc")" && pwd)/$base"
  [ -z "${referenced[$full]:-}" ] || continue
  report "$doc" 'orphan' 'orphan'
done < <(find "$ROOT" -type f -name '*.md' | sort)

[ "$issues" -eq 0 ] && printf '%s | tree | clean\n' "$ROOT"
exit $((issues > 0))
