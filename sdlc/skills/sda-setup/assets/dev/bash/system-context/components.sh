#!/usr/bin/env bash
# Manage dependency-map.yaml component nodes (system context).
#   add    --id --type --path --domain
#   update --id [--type] [--path] [--domain]
#   delete --id     (removes node + edges + cascades linked behaviours)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/_sc-common.sh"

ACTION="${1:-}"; shift 2>/dev/null || true
ID=""; TYPE=""; PATHV=""; DOMAIN=""; ROOT="docs/system-context"
while [ $# -gt 0 ]; do
  case "$1" in
    --id) ID="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --path) PATHV="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --root) ROOT="$2"; shift 2 ;;
    *) sc_error "components: unknown arg $1" ;;
  esac
done
[ -n "$ID" ] || sc_error "components: --id is required"

MAP="$ROOT/dependency-map.yaml"
sc_init_list_file "$MAP" components dependencies

case "$ACTION" in
  add)
    sc_item_exists "$MAP" components id "$ID" && sc_error "components: '$ID' already exists"
    [ -n "$TYPE" ] || sc_error "components add: --type is required"
    [ -n "$PATHV" ] || sc_error "components add: --path is required"
    [ -n "$DOMAIN" ] || sc_error "components add: --domain is required"
    case "$TYPE" in api|service|repository|external|ui|worker|job) ;; *) sc_error "components: invalid type '$TYPE'" ;; esac
    bf="$(mktemp)"
    {
      printf '  - id: %s\n' "$(sc_format_value id "$ID")"
      printf '    type: %s\n' "$(sc_format_value type "$TYPE")"
      printf '    path: %s\n' "$(sc_format_value path "$PATHV")"
      printf '    domain: %s\n' "$(sc_format_value domain "$DOMAIN")"
    } > "$bf"
    sc_add_item "$MAP" components "$bf"; rm -f "$bf"
    printf 'ok: added component %s (%s, domain=%s)\n' "$ID" "$TYPE" "$DOMAIN"
    ;;
  update)
    sc_item_exists "$MAP" components id "$ID" || sc_error "components: '$ID' not found"
    [ -n "$TYPE" ] && sc_set_field "$MAP" components id "$ID" type "$(sc_format_value type "$TYPE")"
    [ -n "$PATHV" ] && sc_set_field "$MAP" components id "$ID" path "$(sc_format_value path "$PATHV")"
    [ -n "$DOMAIN" ] && sc_set_field "$MAP" components id "$ID" domain "$(sc_format_value domain "$DOMAIN")"
    printf 'ok: updated component %s\n' "$ID"
    ;;
  delete)
    sc_item_exists "$MAP" components id "$ID" || sc_error "components: '$ID' not found"
    declare -a REMOVED=()
    sc_remove_item "$MAP" components id "$ID"; REMOVED+=("component $ID")
    # remove edges from=ID
    if sc_item_exists "$MAP" dependencies from "$ID"; then
      sc_remove_item "$MAP" dependencies from "$ID"; REMOVED+=("edges from $ID")
    fi
    # strip ID from remaining `to` lists
    tmp="$(mktemp)"
    awk -v id="$ID" '
      function rebuild(list,   n,i,arr,out,t){
        gsub(/^\[|\]$/,"",list); n=split(list,arr,/,[ ]*/); out=""
        for(i=1;i<=n;i++){t=arr[i]; gsub(/^[ ]+|[ ]+$/,"",t); if(t!=""&&t!=id){out=(out==""?t:out", "t)}}
        return "["out"]"
      }
      /^    to:[ \t]*\[/ { pre=$0; sub(/\[.*\]/,"",pre); orig=$0; sub(/^[^[]*/,"",orig); nl=rebuild(orig); print "    to: " nl; next }
      { print }
    ' "$MAP" > "$tmp" && mv "$tmp" "$MAP"
    # cascade behaviours whose via references ID
    for f in "$ROOT"/*.yaml; do
      [ -e "$f" ] || continue
      base="$(basename "$f")"
      case "$base" in index.yaml|dependency-map.yaml) continue ;; esac
      cross=0; [ "$base" = "cross-domain.yaml" ] && cross=1
      while IFS= read -r bid; do
        [ -n "$bid" ] || continue
        raw="$(sc_get_field_raw "$f" behaviors id "$bid" via)"
        hit=0
        if [ "$cross" = "1" ]; then
          case ",${raw//[][ ]/}," in *",$ID,"*) hit=1 ;; esac
        else
          dec="$(sc_get_field "$f" behaviors id "$bid" via)"
          [ "$dec" = "$ID" ] && hit=1
        fi
        if [ "$hit" = "1" ]; then
          sc_remove_item "$f" behaviors id "$bid"; REMOVED+=("behaviour $bid ($base)")
        fi
      done < <(sc_list_ids "$f" behaviors)
    done
    printf 'ok: deleted component %s\n' "$ID"
    for r in "${REMOVED[@]}"; do printf '  removed: %s\n' "$r"; done
    ;;
  *) sc_error "components: action must be add|update|delete" ;;
esac
