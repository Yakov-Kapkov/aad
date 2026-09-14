#!/usr/bin/env bash
# Manage decisions in a domain file (superseded, never deleted).
#   add    --domain --id --summary --rationale [--status active]
#   update --domain --id [--summary] [--rationale] [--status] [--superseded-by]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/_sc-common.sh"

ACTION="${1:-}"; shift 2>/dev/null || true
DOMAIN=""; ID=""; SUMMARY=""; RATIONALE=""; STATUS=""; SUPBY=""; ROOT="docs/system-context"
while [ $# -gt 0 ]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2 ;;
    --id) ID="$2"; shift 2 ;;
    --summary) SUMMARY="$2"; shift 2 ;;
    --rationale) RATIONALE="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --superseded-by) SUPBY="$2"; shift 2 ;;
    --root) ROOT="$2"; shift 2 ;;
    *) sc_error "decisions: unknown arg $1" ;;
  esac
done
[ -n "$DOMAIN" ] || sc_error "decisions: --domain is required"
[ -n "$ID" ] || sc_error "decisions: --id is required"

DF="$ROOT/$DOMAIN.yaml"
[ -f "$DF" ] || sc_error "decisions: domain '$DOMAIN' not found (create it with domains add)"

case "$ACTION" in
  add)
    sc_item_exists "$DF" decisions id "$ID" && sc_error "decisions: '$ID' already exists in $DOMAIN"
    [ -n "$SUMMARY" ] || sc_error "decisions add: --summary is required"
    [ -n "$RATIONALE" ] || sc_error "decisions add: --rationale is required"
    [ -n "$STATUS" ] || STATUS="active"
    bf="$(mktemp)"
    {
      printf '  - id: %s\n' "$(sc_format_value id "$ID")"
      printf '    summary: %s\n' "$(sc_format_value summary "$SUMMARY")"
      printf '    rationale: %s\n' "$(sc_format_value rationale "$RATIONALE")"
      printf '    status: %s\n' "$(sc_format_value status "$STATUS")"
      printf '    superseded_by: %s\n' "$(sc_format_value superseded_by "$SUPBY")"
    } > "$bf"
    sc_add_item "$DF" decisions "$bf"; rm -f "$bf"
    printf 'ok: added decision %s (%s)\n' "$ID" "$DOMAIN"
    ;;
  update)
    sc_item_exists "$DF" decisions id "$ID" || sc_error "decisions: '$ID' not found in $DOMAIN"
    [ -n "$SUMMARY" ] && sc_set_field "$DF" decisions id "$ID" summary "$(sc_format_value summary "$SUMMARY")"
    [ -n "$RATIONALE" ] && sc_set_field "$DF" decisions id "$ID" rationale "$(sc_format_value rationale "$RATIONALE")"
    [ -n "$STATUS" ] && sc_set_field "$DF" decisions id "$ID" status "$(sc_format_value status "$STATUS")"
    [ -n "$SUPBY" ] && sc_set_field "$DF" decisions id "$ID" superseded_by "$(sc_format_value superseded_by "$SUPBY")"
    printf 'ok: updated decision %s (%s)\n' "$ID" "$DOMAIN"
    ;;
  *) sc_error "decisions: action must be add|update" ;;
esac
