#!/usr/bin/env bash
# Manage domain files and their index.yaml registration (system context).
#   add    --name [--project]   creates <name>.yaml + registers in index.yaml
#   delete --name               removes <name>.yaml + unregisters (cascade listed)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/_sc-common.sh"

ACTION="${1:-}"; shift 2>/dev/null || true
NAME=""; PROJECT=""; ROOT="docs/system-context"
while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --root) ROOT="$2"; shift 2 ;;
    *) sc_error "domains: unknown arg $1" ;;
  esac
done
[ -n "$NAME" ] || sc_error "domains: --name is required"
case "$NAME" in index|dependency-map|cross-domain) sc_error "domains: '$NAME' is a reserved file name" ;; esac

INDEX="$ROOT/index.yaml"
DF="$ROOT/$NAME.yaml"
DREL="$ROOT/$NAME.yaml"

if [ ! -f "$INDEX" ]; then
  [ -n "$PROJECT" ] || PROJECT="$(basename "$(pwd)")"
  mkdir -p "$ROOT"
  { printf 'project: %s\n' "$PROJECT"; printf 'last_updated: %s\n' "$(sc_today)"; printf 'domains: []\n'; } > "$INDEX"
fi

registered=0; sc_item_exists "$INDEX" domains name "$NAME" && registered=1

case "$ACTION" in
  add)
    { [ "$registered" = "1" ] || [ -f "$DF" ]; } && sc_error "domains: '$NAME' already exists"
    { printf 'decisions: []\n'; printf 'behaviors: []\n'; } > "$DF"
    bf="$(mktemp)"
    { printf '  - name: %s\n' "$NAME"; printf '    file: %s\n' "$DREL"; } > "$bf"
    sc_add_item "$INDEX" domains "$bf"; rm -f "$bf"
    sc_set_scalar "$INDEX" last_updated "$(sc_today)"
    printf 'ok: added domain %s\n' "$NAME"
    ;;
  delete)
    { [ "$registered" = "1" ] || [ -f "$DF" ]; } || sc_error "domains: '$NAME' not found"
    declare -a REMOVED=()
    if [ -f "$DF" ]; then
      while IFS= read -r did; do [ -n "$did" ] && REMOVED+=("decision $did"); done < <(sc_list_ids "$DF" decisions)
      while IFS= read -r bid; do [ -n "$bid" ] && REMOVED+=("behaviour $bid"); done < <(sc_list_ids "$DF" behaviors)
      rm -f "$DF"
    fi
    if [ "$registered" = "1" ]; then
      sc_remove_item "$INDEX" domains name "$NAME"
      sc_set_scalar "$INDEX" last_updated "$(sc_today)"
    fi
    printf 'ok: deleted domain %s\n' "$NAME"
    for r in "${REMOVED[@]:-}"; do [ -n "$r" ] && printf '  removed: %s\n' "$r"; done
    ;;
  *) sc_error "domains: action must be add|delete" ;;
esac
