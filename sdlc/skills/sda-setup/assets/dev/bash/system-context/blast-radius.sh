#!/usr/bin/env bash
# Read-only regression blast-radius query over the system-context graph.
#   blast-radius --components "a,b" [--root <dir>]
# Reverse-traverse dependency-map.yaml (a dependent depends on a changed node),
# then report behaviours routed through the at-risk set and their status.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/_sc-common.sh"

COMPONENTS=""; ROOT="docs/system-context"
while [ $# -gt 0 ]; do
  case "$1" in
    --components) COMPONENTS="$2"; shift 2 ;;
    --root) ROOT="$2"; shift 2 ;;
    *) sc_error "blast-radius: unknown arg $1" ;;
  esac
done
[ -n "$COMPONENTS" ] || sc_error "blast-radius: --components is required"
MAP="$ROOT/dependency-map.yaml"
[ -f "$MAP" ] || sc_error "blast-radius: dependency-map.yaml not found under $ROOT"

# Compute at-risk set (seeds + all transitive dependents) via awk BFS over
# reverse edges.  Output: one component id per line.
atrisk="$(awk -v seeds="$COMPONENTS" '
  function trim(s){gsub(/^[ \t]+|[ \t]+$/,"",s);return s}
  { lines[NR]=$0 }
  END{
    insec=0; cur=""
    for(i=1;i<=NR;i++){
      if(lines[i] ~ /^dependencies:[ \t]*$/){insec=1;continue}
      if(lines[i] ~ /^dependencies:[ \t]*\[\][ \t]*$/){insec=0;continue}
      if(lines[i] ~ /^[^ \t]/){insec=0}
      if(!insec)continue
      if(lines[i] ~ /^  - from:/){cur=lines[i]; sub(/^  - from:[ \t]*/,"",cur); cur=trim(cur)}
      else if(lines[i] ~ /^    to:[ \t]*\[/){
        t=lines[i]; sub(/^    to:[ \t]*\[/,"",t); sub(/\][ \t]*$/,"",t)
        n=split(t,arr,/,[ ]*/)
        for(k=1;k<=n;k++){ dep=trim(arr[k]); if(dep!=""){ rev[dep]=rev[dep] SUBSEP cur } }
      }
    }
    ns=split(seeds,s,/,[ ]*/); qn=0
    for(i=1;i<=ns;i++){ v=trim(s[i]); if(v!=""&&!(v in seen)){seen[v]=1;q[++qn]=v} }
    head=1
    while(head<=qn){
      node=q[head++]
      if(node in rev){
        m=split(rev[node],ds,SUBSEP)
        for(j=1;j<=m;j++){ d=ds[j]; if(d!=""&&!(d in seen)){seen[d]=1;q[++qn]=d} }
      }
    }
    for(k=1;k<=qn;k++) print q[k]
  }
' "$MAP" | sort -u)"

# format at-risk list
al=""
while IFS= read -r c; do [ -n "$c" ] && al=$([ -z "$al" ] && printf '%s' "$c" || printf '%s, %s' "$al" "$c"); done <<< "$atrisk"
printf 'at-risk-components=[%s]\n' "$al"

# membership test helper
is_atrisk() { printf '%s\n' "$atrisk" | grep -qx "$1"; }

pending=0; count=0
for f in "$ROOT"/*.yaml; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  case "$base" in index.yaml|dependency-map.yaml) continue ;; esac
  while IFS= read -r bid; do
    [ -n "$bid" ] || continue
    raw="$(sc_get_field_raw "$f" behaviors id "$bid" via)"
    viaclean="${raw//[][]/}"; viaclean="${viaclean//\"/}"
    hit=0; joined=""
    IFS=',' read -ra parts <<< "$viaclean"
    for p in "${parts[@]}"; do
      p="$(printf '%s' "$p" | sed 's/^ *//;s/ *$//')"
      [ -z "$p" ] && continue
      joined=$([ -z "$joined" ] && printf '%s' "$p" || printf '%s|%s' "$joined" "$p")
      is_atrisk "$p" && hit=1
    done
    if [ "$hit" = "1" ]; then
      status="$(sc_get_field "$f" behaviors id "$bid" status)"
      printf 'behaviour=%s domain=%s via=%s status=%s\n' "$bid" "$base" "$joined" "$status"
      count=$((count+1))
      [ "$status" = "pending-reverification" ] && pending=$((pending+1))
    fi
  done < <(sc_list_ids "$f" behaviors)
done
printf 'pending-count=%s\n' "$pending"
printf 'at-risk-count=%s\n' "$(printf '%s\n' "$atrisk" | grep -c .)"
