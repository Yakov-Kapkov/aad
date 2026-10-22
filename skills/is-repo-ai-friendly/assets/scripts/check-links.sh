#!/usr/bin/env bash
# check-links.sh - markdown link and text hygiene. Model-free: no docs layout is
# assumed.
#
# Output contract - one line per finding, then a summary line:
#   <path> | <check> | <status>
# A clean run reports "| links | clean". Exit code is 1 on any finding.
#
# --path <p>       One or more files or folders (folders walked for *.md).
#                  Required.
# --no-fence       Flag a code fence (```).
# --no-path-token  Flag a path-shaped token that is not a .md link.
# --forbid <lit>   Flag a file containing the literal <lit>.
#
# Every markdown link on a line is resolved. Text inside a fenced code block
# or a single-line inline code span is literal and is skipped.

set -uo pipefail

NO_FENCE=0
NO_PATH_TOKEN=0
FORBID=""
PATHS=()

# Held in variables: an inline pattern in [[ =~ ]] gets its escapes re-parsed by
# bash, which rejects the escaped parens.
LINK_RE='\[[^]]+\]\(([^)]+)\)'
PATH_TOKEN='[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+\.[A-Za-z0-9]+'

fail() {
  printf 'error=%s\n' "$1"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      printf 'Usage: check-links.sh --path <file-or-dir> [--no-fence] [--no-path-token] [--forbid <lit>]\n'
      exit 0 ;;
    --path|-Path)                 PATHS+=("${2:-}"); shift 2 ;;
    --no-fence|-NoFence)          NO_FENCE=1; shift ;;
    --no-path-token|-NoPathToken) NO_PATH_TOKEN=1; shift ;;
    --forbid|-Forbid)             FORBID="${2:-}"; shift 2 ;;
    -*)                           fail "unknown option '$1'" ;;
    *)                            PATHS+=("$1"); shift ;;
  esac
done

[ "${#PATHS[@]}" -gt 0 ] || fail "pass --path <file-or-dir>"

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

FILES=()
for p in "${PATHS[@]}"; do
  if [ -f "$p" ]; then
    case "$p" in *.md) FILES+=("$p") ;; esac
  elif [ -d "$p" ]; then
    while IFS= read -r f; do FILES+=("$f"); done < <(find "$p" -type f -name '*.md' | sort)
  else
    fail "path not found: $p"
  fi
done

for f in "${FILES[@]}"; do
  dir="$(cd "$(dirname "$f")" && pwd)"
  number=0

  in_fence=0
  while IFS= read -r line || [ -n "$line" ]; do
    number=$((number + 1))

    trimmed="${line#"${line%%[![:space:]]*}"}"
    is_fence=0
    case "$trimmed" in '```'*) is_fence=1 ;; esac

    if [ "$NO_FENCE" -eq 1 ] && [ "$is_fence" -eq 1 ]; then
      report "$f" "code-fence at line $number" 'violation'
    fi

    # Fenced and inline code are literal text - not markdown, not links.
    if [ "$is_fence" -eq 1 ]; then
      in_fence=$((1 - in_fence))
      continue
    fi
    [ "$in_fence" -eq 1 ] && continue

    probe="$(printf '%s' "$line" | sed -E 's#`[^`]*`##g')"

    rest="$probe"
    while [[ "$rest" =~ $LINK_RE ]]; do
      target="${BASH_REMATCH[1]}"
      rest="${rest#*"${BASH_REMATCH[0]}"}"
      resolved="$(resolve_link "$dir" "$target")"
      if [ -n "$resolved" ] && [ ! -e "$resolved" ]; then
        report "$f" "broken-link: $target" 'broken'
      fi
    done

    if [ "$NO_PATH_TOKEN" -eq 1 ]; then
      # URLs and link syntax are navigation, not path tokens.
      scan="$(printf '%s' "$probe" | sed -E 's#(https?|mailto):[^ ]+# #g; s#\[[^]]+\]\([^)]+\)##g')"
      r="$scan"
      while [[ "$r" =~ $PATH_TOKEN ]]; do
        token="${BASH_REMATCH[0]}"
        r="${r#*"$token"}"
        case "$token" in
          *.md) continue ;;
        esac
        report "$f" "non-doc path at line $number: $token" 'violation'
        break
      done
    fi
  done < "$f"

  if [ -n "$FORBID" ] && grep -qF -- "$FORBID" "$f"; then
    report "$f" "forbidden-literal: $FORBID" 'violation'
  fi
done

[ "$issues" -eq 0 ] && printf '%s | links | clean\n' "${PATHS[*]}"
exit $((issues > 0))
