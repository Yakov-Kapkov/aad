#!/usr/bin/env bash
# Manage dependency-map.yaml edges between existing component nodes.
#   add    --from --to      (both must exist; deduped)
#   delete --from --to      (empties collapse the `from` item)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/_sc-common.sh"

ACTION="${1:-}"; shift 2>/dev/null || true
FROM=""; TO=""; ROOT="docs/system-context"
while [ $# -gt 0 ]; do
  case "$1" in
    --from) FROM="$2"; shift 2 ;;
    --to) TO="$2"; shift 2 ;;
    --root) ROOT="$2"; shift 2 ;;
    *) sc_error "edges: unknown arg $1" ;;
  esac
done
[ -n "$FROM" ] || sc_error "edges: --from is required"
[ -n "$TO" ] || sc_error "edges: --to is required"

MAP="$ROOT/dependency-map.yaml"
sc_init_list_file "$MAP" components dependencies

for n in "$FROM" "$TO"; do
  sc_item_exists "$MAP" components id "$n" || sc_error "edges: component '$n' not found"
done

raw="$(sc_get_field_raw "$MAP" dependencies from "$FROM" to)"
has_from=0; sc_item_exists "$MAP" dependencies from "$FROM" && has_from=1

case "$ACTION" in
  add)
    if [ "$has_from" = "1" ]; then
      case ",${raw//[][ ]/}," in *",$TO,"*) printf 'ok: edge %s -> %s already present\n' "$FROM" "$TO"; exit 0 ;; esac
      inner="${raw#[}"; inner="${inner%]}"
      if [ -z "${inner// /}" ]; then newlist="[$TO]"; else newlist="[${inner}, $TO]"; fi
      sc_set_field "$MAP" dependencies from "$FROM" to "$newlist"
    else
      bf="$(mktemp)"
      { printf '  - from: %s\n' "$FROM"; printf '    to: %s\n' "$(sc_format_list "$TO")"; } > "$bf"
      sc_add_item "$MAP" dependencies "$bf"; rm -f "$bf"
    fi
    printf 'ok: added edge %s -> %s\n' "$FROM" "$TO"
    ;;
  delete)
    [ "$has_from" = "1" ] || sc_error "edges: no dependencies from '$FROM'"
    case ",${raw//[][ ]/}," in *",$TO,"*) ;; *) sc_error "edges: edge $FROM -> $TO not found" ;; esac
    newlist="$(awk -v id="$TO" 'BEGIN{
      list=ARGV[1]; gsub(/^\[|\]$/,"",list); n=split(list,a,/,[ ]*/); out="";
      for(i=1;i<=n;i++){t=a[i]; gsub(/^[ ]+|[ ]+$/,"",t); if(t!=""&&t!=id){out=(out==""?t:out", "t)}}
      print "["out"]"
    }' "$raw")"
    if [ "$newlist" = "[]" ]; then
      sc_remove_item "$MAP" dependencies from "$FROM"
    else
      sc_set_field "$MAP" dependencies from "$FROM" to "$newlist"
    fi
    printf 'ok: deleted edge %s -> %s\n' "$FROM" "$TO"
    ;;
  *) sc_error "edges: action must be add|delete" ;;
esac
