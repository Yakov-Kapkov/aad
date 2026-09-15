#!/usr/bin/env bash
# docs-integrity.sh - verifies the integrity of a docs tree, or of one document.
#
# Output contract - one line per finding, then a summary line:
#   <path> | <check> | <status>
# A finding carries a keyword status; a clean run reports "| integrity | clean".
# Exit code is 1 when anything is not ok.
#
# --root <dir>   Docs tree. Every index link resolves, no duplicate row within
#                one index, no orphaned document, and no durable doc naming a
#                `.sda/` path (the one-way link rule).
#
# --file <path>  One document. Every relative link resolves, no code fence, and
#                no path token that is not a `.md` link - the design.md
#                altitude check.
#
# Only the first link on a line is resolved. Every document shape this checks
# keeps one link per line.

set -uo pipefail

ROOT=""
FILE=""
# Held in variables: an inline pattern in [[ =~ ]] gets its escapes re-parsed by
# bash, which rejects the escaped parens.
LINK_RE='\[[^]]+\]\(([^)]+)\)'
PATH_TOKEN='[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+\.[A-Za-z0-9]+'

fail() {
  printf 'error=%s\n' "$1"
  exit 1
}

usage() {
  printf 'Usage:\n'
  printf '  docs-integrity.sh --root <dir>\n'
  printf '  docs-integrity.sh --file <path>\n'
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)          usage; exit 0 ;;
    -r|--root|-Root)    ROOT="${2:-}"; shift 2 ;;
    -f|--file|-File)    FILE="${2:-}"; shift 2 ;;
    -*)                 fail "unknown option '$1'" ;;
    *)                  ROOT="$1"; shift ;;   # legacy positional root
  esac
done

[ -n "$ROOT" ] || [ -n "$FILE" ] || fail "pass --root <dir> or --file <path>"
[ -z "$ROOT" ] || [ -z "$FILE" ] || fail "pass --root or --file, not both"

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

# --- one document -----------------------------------------------------------
if [ -n "$FILE" ]; then
  [ -f "$FILE" ] || { printf '%s | file | MISSING\n' "$FILE"; exit 1; }

  dir="$(cd "$(dirname "$FILE")" && pwd)"
  declare -A seen=()
  number=0

  while IFS= read -r line || [ -n "$line" ]; do
    number=$((number + 1))

    trimmed="${line#"${line%%[![:space:]]*}"}"
    case "$trimmed" in
      '```'*) report "$FILE" "code-fence at line $number" 'violation' ;;
    esac

    # URLs and link syntax are navigation, not altitude violations.
    scan="$(printf '%s' "$line" | sed -E 's#(https?|mailto):[^ ]+# #g; s#\[[^]]+\]\([^)]+\)##g')"

    if [[ "$line" =~ $LINK_RE ]]; then
      target="${BASH_REMATCH[1]}"
      resolved="$(resolve_link "$dir" "$target")"
      if [ -n "$resolved" ]; then
        [ -e "$resolved" ] || report "$FILE" "broken-link: $target" 'broken'
        [ -z "${seen[$resolved]:-}" ] || report "$FILE" "duplicate-link: $target" 'duplicate'
        seen["$resolved"]=1
      fi
    fi

    rest="$scan"
    while [[ "$rest" =~ $PATH_TOKEN ]]; do
      token="${BASH_REMATCH[0]}"
      rest="${rest#*"$token"}"
      case "$token" in
        *.md) continue ;;
      esac
      report "$FILE" "non-doc path at line $number: $token" 'violation'
      break
    done
  done < "$FILE"

  [ "$issues" -eq 0 ] && printf '%s | integrity | clean\n' "$FILE"
  exit $((issues > 0))
fi

# --- docs tree -------------------------------------------------------------
[ -d "$ROOT" ] || { printf '%s | root | MISSING\n' "$ROOT"; exit 1; }

declare -A referenced

while IFS= read -r idx; do
    dir="$(cd "$(dirname "$idx")" && pwd)"
    declare -A seen=()
    while IFS= read -r line; do
        if [[ "$line" =~ $LINK_RE ]]; then
            target="${BASH_REMATCH[1]%%#*}"
            [ -z "$target" ] && continue
            resolved="$(resolve_link "$dir" "$target")"
            [ -n "$resolved" ] || continue
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
done < <(find "$ROOT" -type f -name 'index.md' | sort)

while IFS= read -r topic; do
    [ "$(basename "$topic")" = "index.md" ] && continue
    resolved="$(cd "$(dirname "$topic")" && printf '%s/%s' "$PWD" "$(basename "$topic")")"
    if [[ -z "${referenced[$resolved]:-}" ]]; then
        report "$topic" "orphan" "orphan"
    fi
done < <(find "$ROOT" -type f -name '*.md')

# One-way link rule: a durable doc never names a transient .sda path.
while IFS= read -r doc; do
    if grep -qF -- '.sda/' "$doc"; then
        report "$doc" "sda-reference" "violation"
    fi
done < <(find "$ROOT" -type f -name '*.md')

if [ "$issues" -eq 0 ]; then
    printf '%s | integrity | clean\n' "$ROOT"
fi

exit $((issues > 0))
