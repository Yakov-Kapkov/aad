#!/usr/bin/env bash
# Manage behaviours in a domain file or cross-domain.yaml (system context).
#   Domain:       add    --domain <d> --id --claim --via <componentId> --status <s> [--verified-by id] [--note text]
#                 update --domain <d> --id [--claim] [--via] [--status] [--verified-by] [--note]
#                 delete --domain <d> --id
#   Cross-domain: add    --domain cross-domain --id --claim --via "a,b" --domains "d1,d2" --status <s> [--verified-by id]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/_sc-common.sh"

ACTION="${1:-}"; shift 2>/dev/null || true
DOMAIN=""; ID=""; CLAIM=""; VIA=""; DOMAINS=""; STATUS=""; VERBY=""; NOTE=""; ROOT="docs/system-context"
while [ $# -gt 0 ]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2 ;;
    --id) ID="$2"; shift 2 ;;
    --claim) CLAIM="$2"; shift 2 ;;
    --via) VIA="$2"; shift 2 ;;
    --domains) DOMAINS="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --verified-by) VERBY="$2"; shift 2 ;;
    --note) NOTE="$2"; shift 2 ;;
    --root) ROOT="$2"; shift 2 ;;
    *) sc_error "behaviors: unknown arg $1" ;;
  esac
done
[ -n "$DOMAIN" ] || sc_error "behaviors: --domain is required"
[ -n "$ID" ] || sc_error "behaviors: --id is required"

CROSS=0; [ "$DOMAIN" = "cross-domain" ] && CROSS=1
FILE="$ROOT/$DOMAIN.yaml"
if [ "$CROSS" = "1" ]; then sc_init_list_file "$FILE" behaviors
elif [ ! -f "$FILE" ]; then sc_error "behaviors: domain '$DOMAIN' not found (create it with domains add)"; fi

case "$ACTION" in
  add)
    sc_item_exists "$FILE" behaviors id "$ID" && sc_error "behaviors: '$ID' already exists in $DOMAIN"
    [ -n "$CLAIM" ] || sc_error "behaviors add: --claim is required"
    [ -n "$VIA" ] || sc_error "behaviors add: --via is required"
    [ -n "$STATUS" ] || sc_error "behaviors add: --status is required"
    case "$STATUS" in verified|pending-reverification) ;; *) sc_error "behaviors: invalid status '$STATUS'" ;; esac
    bf="$(mktemp)"
    if [ "$CROSS" = "1" ]; then
      [ -n "$DOMAINS" ] || sc_error "behaviors add (cross-domain): --domains is required"
      {
        printf '  - id: %s\n' "$(sc_format_value id "$ID")"
        printf '    claim: %s\n' "$(sc_format_value claim "$CLAIM")"
        printf '    via: %s\n' "$(sc_format_list "$VIA")"
        printf '    domains: %s\n' "$(sc_format_list "$DOMAINS")"
        printf '    status: %s\n' "$(sc_format_value status "$STATUS")"
        printf '    verified_by: %s\n' "$(sc_format_value verified_by "$VERBY")"
      } > "$bf"
    else
      {
        printf '  - id: %s\n' "$(sc_format_value id "$ID")"
        printf '    claim: %s\n' "$(sc_format_value claim "$CLAIM")"
        printf '    via: %s\n' "$(sc_format_value via "$VIA")"
        printf '    status: %s\n' "$(sc_format_value status "$STATUS")"
        printf '    verified_by: %s\n' "$(sc_format_value verified_by "$VERBY")"
        printf '    note: %s\n' "$(sc_format_value note "$NOTE")"
      } > "$bf"
    fi
    sc_add_item "$FILE" behaviors "$bf"; rm -f "$bf"
    printf 'ok: added behaviour %s (%s, %s)\n' "$ID" "$DOMAIN" "$STATUS"
    ;;
  update)
    sc_item_exists "$FILE" behaviors id "$ID" || sc_error "behaviors: '$ID' not found in $DOMAIN"
    [ -n "$CLAIM" ] && sc_set_field "$FILE" behaviors id "$ID" claim "$(sc_format_value claim "$CLAIM")"
    [ -n "$STATUS" ] && sc_set_field "$FILE" behaviors id "$ID" status "$(sc_format_value status "$STATUS")"
    [ -n "$VERBY" ] && sc_set_field "$FILE" behaviors id "$ID" verified_by "$(sc_format_value verified_by "$VERBY")"
    [ -n "$NOTE" ] && sc_set_field "$FILE" behaviors id "$ID" note "$(sc_format_value note "$NOTE")"
    if [ -n "$VIA" ]; then
      if [ "$CROSS" = "1" ]; then sc_set_field "$FILE" behaviors id "$ID" via "$(sc_format_list "$VIA")"
      else sc_set_field "$FILE" behaviors id "$ID" via "$(sc_format_value via "$VIA")"; fi
    fi
    printf 'ok: updated behaviour %s (%s)\n' "$ID" "$DOMAIN"
    ;;
  delete)
    sc_item_exists "$FILE" behaviors id "$ID" || sc_error "behaviors: '$ID' not found in $DOMAIN"
    sc_remove_item "$FILE" behaviors id "$ID"
    printf 'ok: deleted behaviour %s (%s)\n' "$ID" "$DOMAIN"
    ;;
  *) sc_error "behaviors: action must be add|update|delete" ;;
esac
