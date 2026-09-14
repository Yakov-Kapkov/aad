#!/usr/bin/env bash
# Manage dev-qa-cycle-state.yaml - the inner DEV+QA run-loop state.
# Mirrors dev-qa-cycle-state.ps1 and emits identical YAML.
#   init        --dir <d> --task <name> [--spec <path>]
#   read        --dir <d> [--field <f>]
#   set-sha     --dir <d> --sha <sha>
#   set-verdict --dir <d> --gate primary|regression --verdict PASS|FAIL [--failures "a,b"]
#   bump-run    --dir <d> [--spec <path>]
set -uo pipefail

wf_error() { printf 'error=%s\n' "$1"; exit 1; }
wf_format_list() {
  local raw="${1:-}" out="" tok; raw="${raw//,/ }"
  for tok in $raw; do [ -z "$tok" ] && continue; out=$([ -z "$out" ] && printf '%s' "$tok" || printf '%s, %s' "$out" "$tok"); done
  printf '[%s]' "$out"
}
run_folder() { printf 'runs/run-%02d' "$1"; }

ACTION="${1:-}"; shift 2>/dev/null || true
DIR="."; TASK=""; SPEC=""; SHA=""; GATE="primary"; VERDICT=""; FAILURES=""; FIELD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="$2"; shift 2 ;;
    --task) TASK="$2"; shift 2 ;;
    --spec) SPEC="$2"; shift 2 ;;
    --sha) SHA="$2"; shift 2 ;;
    --gate) GATE="$2"; shift 2 ;;
    --verdict) VERDICT="$2"; shift 2 ;;
    --failures) FAILURES="$2"; shift 2 ;;
    --field) FIELD="$2"; shift 2 ;;
    *) wf_error "dev-qa-cycle-state: unknown arg $1" ;;
  esac
done
FILE="$DIR/dev-qa-cycle-state.yaml"

# update a field of the LAST run block
update_last_run() {
  local file="$1" fld="$2" val="$3" tmp; tmp="$(mktemp)"
  awk -v fld="$fld" -v val="$val" '
    { lines[NR]=$0 } END{
      last=0
      for(i=1;i<=NR;i++) if(lines[i] ~ /^  - run:/) last=i
      endl=NR+1
      for(i=last+1;i<=NR;i++){ if(lines[i] ~ /^  - / || lines[i] ~ /^[^ ]/){endl=i;break} }
      for(i=1;i<=NR;i++){
        if(i>last && i<endl && lines[i] ~ "^    "fld":"){ print "    "fld": "val } else print lines[i]
      }
    }' "$file" > "$tmp" && mv "$tmp" "$file"
}
set_scalar() {
  local file="$1" key="$2" val="$3" tmp; tmp="$(mktemp)"
  awk -v key="$key" -v val="$val" '{ if($0 ~ "^"key":"){print key": "val} else print }' "$file" > "$tmp" && mv "$tmp" "$file"
}

case "$ACTION" in
  init)
    [ -f "$FILE" ] && wf_error "dev-qa-cycle-state: state already exists at $FILE"
    [ -n "$TASK" ] || wf_error "init: --task is required"
    [ -n "$SPEC" ] || SPEC="$(run_folder 1)/task.md"
    mkdir -p "$DIR/$(run_folder 1)"
    {
      printf 'task: %s\n' "$TASK"
      printf 'current-run: 1\n'
      printf 'status: implementing\n'
      printf 'runs:\n'
      printf '  - run: 1\n'
      printf '    spec: %s\n' "$SPEC"
      printf '    sha: null\n'
      printf '    verdict: null\n'
      printf '    failures: []\n'
      printf 'open-failures: []\n'
    } > "$FILE"
    printf "ok: initialized cycle for '%s' at run 1\n" "$TASK"
    ;;
  read)
    [ -f "$FILE" ] || wf_error "dev-qa-cycle-state: no state at $FILE (run init first)"
    if [ -z "$FIELD" ]; then cat "$FILE"; exit 0; fi
    case "$FIELD" in
      task|current-run|status|open-failures)
        awk -v k="$FIELD" '$0 ~ "^"k":"{sub("^"k":[ \t]*","");print;exit}' "$FILE" ;;
      run-folder)
        cr="$(awk '/^current-run:/{print $2;exit}' "$FILE")"; run_folder "$cr" ;;
      spec|sha|verdict|failures)
        awk -v fld="$FIELD" '
          /^  - run:/{last=NR}
          { lines[NR]=$0 } END{
            endl=NR+1; for(i=last+1;i<=NR;i++){if(lines[i] ~ /^  - /||lines[i] ~ /^[^ ]/){endl=i;break}}
            for(i=last;i<endl;i++){ if(lines[i] ~ "^    "fld":"){v=lines[i]; sub("^    "fld":[ \t]*","",v); print v; exit} }
          }' "$FILE" ;;
      *) wf_error "read: unknown field '$FIELD'" ;;
    esac
    ;;
  set-sha)
    [ -f "$FILE" ] || wf_error "dev-qa-cycle-state: no state at $FILE (run init first)"
    [ -n "$SHA" ] || wf_error "set-sha: --sha is required"
    update_last_run "$FILE" sha "$SHA"
    cr="$(awk '/^current-run:/{print $2;exit}' "$FILE")"
    printf 'ok: run %s sha=%s\n' "$cr" "$SHA"
    ;;
  set-verdict)
    [ -f "$FILE" ] || wf_error "dev-qa-cycle-state: no state at $FILE (run init first)"
    [ -n "$VERDICT" ] || wf_error "set-verdict: --verdict is required"
    case "$VERDICT" in PASS|FAIL) ;; *) wf_error "set-verdict: --verdict must be PASS|FAIL" ;; esac
    case "$GATE" in primary|regression) ;; *) wf_error "set-verdict: --gate must be primary|regression" ;; esac
    update_last_run "$FILE" verdict "$VERDICT"
    flist="$(wf_format_list "$FAILURES")"
    update_last_run "$FILE" failures "$flist"
    if [ "$VERDICT" = "FAIL" ]; then
      set_scalar "$FILE" status rework; set_scalar "$FILE" open-failures "$flist"
    else
      if [ "$GATE" = "primary" ]; then st="qa-regression"; else st="passed"; fi
      set_scalar "$FILE" status "$st"; set_scalar "$FILE" open-failures "[]"
    fi
    cr="$(awk '/^current-run:/{print $2;exit}' "$FILE")"
    st2="$(awk '/^status:/{print $2;exit}' "$FILE")"
    printf 'ok: run %s %s verdict=%s status=%s\n' "$cr" "$GATE" "$VERDICT" "$st2"
    ;;
  bump-run)
    [ -f "$FILE" ] || wf_error "dev-qa-cycle-state: no state at $FILE (run init first)"
    cr="$(awk '/^current-run:/{print $2;exit}' "$FILE")"
    n=$((cr+1))
    [ -n "$SPEC" ] || SPEC="$(run_folder "$n")/task.md"
    mkdir -p "$DIR/$(run_folder "$n")"
    tmp="$(mktemp)"
    awk -v n="$n" -v spec="$SPEC" '
      /^open-failures:/ && !done {
        print "  - run: " n; print "    spec: " spec; print "    sha: null"; print "    verdict: null"; print "    failures: []"; done=1
      }
      { print }
    ' "$FILE" > "$tmp" && mv "$tmp" "$FILE"
    set_scalar "$FILE" current-run "$n"
    set_scalar "$FILE" status implementing
    set_scalar "$FILE" open-failures "[]"
    printf 'ok: advanced to run %s\n' "$n"
    ;;
  *) wf_error "dev-qa-cycle-state: action must be init|read|set-sha|set-verdict|bump-run" ;;
esac
