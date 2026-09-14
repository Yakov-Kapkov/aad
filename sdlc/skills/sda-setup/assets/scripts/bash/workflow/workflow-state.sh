#!/usr/bin/env bash
# Manage workflow-state.yaml - the outer SDLC-workflow state for one User Story
# across BA -> DESIGN -> DEV -> QA -> DEP (human-orchestrated workflow layer).
# Mirrors workflow-state.ps1 and emits identical YAML.
#   init     --dir <d> --id <id> [--branch <b>] [--user-story <path>]
#   read     --dir <d> [--field <f>]
#   update   --dir <d> --bc BA|DESIGN|DEV|QA|DEP [--output <p>] [--status ...] [--ledger ...]
#   escalate --dir <d> --from <bc> --to <bc> [--reason <text>]
# Pure state + folder manager: never runs git, never triggers an agent. Only writer
# of workflow-state.yaml. On failure prints error=<message> and exits 1.
set -uo pipefail

wf_error() { printf 'error=%s\n' "$1"; exit 1; }

# --- domain vocabulary (single source of truth) ---
ORDER=(BA DESIGN DEV QA DEP)                              # BC advance order
LEDGER_KEYS=(); for _b in "${ORDER[@]}"; do LEDGER_KEYS+=("$(printf '%s' "$_b" | tr 'A-Z' 'a-z')"); done
FIRST_BC="${ORDER[0]}"
BC_DONE="done"                                            # terminal current-bc
DEV_CYCLE="DEV/dev-qa-cycle-state.yaml"
ST_PENDING="pending"; ST_ACTIVE="active"; ST_DONE="done"; ST_ESCALATED="escalated"
output_for() {
  case "$1" in
    BA)     printf 'BA/user-story.md' ;;
    DESIGN) printf 'DESIGN/design-delta.md' ;;
    DEV)    printf 'DEV/task.md' ;;
    QA)     printf 'QA/qa-task.md' ;;
    DEP)    printf 'DEP/' ;;
  esac
}
bc_index() { local b="$1" i; for i in "${!ORDER[@]}"; do [ "${ORDER[$i]}" = "$b" ] && { printf '%s' "$i"; return 0; }; done; return 1; }
upper() { printf '%s' "$1" | tr 'a-z' 'A-Z'; }
lower() { printf '%s' "$1" | tr 'A-Z' 'a-z'; }

ACTION="${1:-}"; shift 2>/dev/null || true
DIR="."; ID=""; BRANCH=""; USERSTORY=""; BC=""; OUTPUT=""; STATUS=""; LEDGER=""; FROM=""; TO=""; REASON=""; FIELD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="$2"; shift 2 ;;
    --id) ID="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --user-story) USERSTORY="$2"; shift 2 ;;
    --bc) BC="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --ledger) LEDGER="$2"; shift 2 ;;
    --from) FROM="$2"; shift 2 ;;
    --to) TO="$2"; shift 2 ;;
    --reason) REASON="$2"; shift 2 ;;
    --field) FIELD="$2"; shift 2 ;;
    *) wf_error "workflow-state: unknown arg $1" ;;
  esac
done
FILE="$DIR/workflow-state.yaml"

WID=""; WSTORY=""; WCUR=""; WBRANCH=""
ST=(); OUT=(); CYC=(); LV=(); EFROM=(); ETO=(); EREASON=()
init_state_defaults() {
  local i
  ST=(); OUT=(); CYC=(); LV=(); EFROM=(); ETO=(); EREASON=()
  for i in "${!ORDER[@]}"; do ST[$i]="$ST_PENDING"; OUT[$i]="$(output_for "${ORDER[$i]}")"; CYC[$i]=""; done
  for i in "${!LEDGER_KEYS[@]}"; do LV[$i]="$ST_PENDING"; done
}

read_state() {
  [ -f "$FILE" ] || wf_error "workflow-state: no state at $FILE (run init first)"
  init_state_defaults
  local section="" curbc_idx=-1 line k v i
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      workflow-id:*) WID="${line#workflow-id:}"; WID="${WID# }"; section=""; continue ;;
      user-story:*)  WSTORY="${line#user-story:}"; WSTORY="${WSTORY# }"; section=""; continue ;;
      current-bc:*)  WCUR="${line#current-bc:}"; WCUR="${WCUR# }"; section=""; continue ;;
      branch:*)      WBRANCH="${line#branch:}"; WBRANCH="${WBRANCH# }"; section=""; continue ;;
      bcs:)          section="bcs"; continue ;;
      escalations:*) section="esc"; continue ;;
      ledgers:)      section="ledgers"; continue ;;
    esac
    if [ "$section" = "bcs" ]; then
      case "$line" in
        "  - bc: "*)     curbc_idx="$(bc_index "${line#  - bc: }")" || curbc_idx=-1 ;;
        "    status: "*) [ "$curbc_idx" -ge 0 ] && ST[$curbc_idx]="${line#    status: }" ;;
        "    output: "*) [ "$curbc_idx" -ge 0 ] && OUT[$curbc_idx]="${line#    output: }" ;;
        "    cycle: "*)  [ "$curbc_idx" -ge 0 ] && CYC[$curbc_idx]="${line#    cycle: }" ;;
      esac
    elif [ "$section" = "esc" ]; then
      case "$line" in
        "  - from: "*)   EFROM+=("${line#  - from: }"); ETO+=(""); EREASON+=("") ;;
        "    to: "*)     ETO[$(( ${#ETO[@]} - 1 ))]="${line#    to: }" ;;
        "    reason: "*) EREASON[$(( ${#EREASON[@]} - 1 ))]="${line#    reason: }" ;;
      esac
    elif [ "$section" = "ledgers" ]; then
      case "$line" in
        "  "*:*) k="${line#  }"; k="${k%%:*}"; v="${line#*: }"
                 for i in "${!LEDGER_KEYS[@]}"; do [ "${LEDGER_KEYS[$i]}" = "$k" ] && LV[$i]="$v"; done ;;
      esac
    fi
  done < "$FILE"
}

write_state() {
  local i
  mkdir -p "$DIR"
  {
    printf 'workflow-id: %s\n' "$WID"
    printf 'user-story: %s\n' "$WSTORY"
    printf 'current-bc: %s\n' "$WCUR"
    printf 'branch: %s\n' "$WBRANCH"
    printf 'bcs:\n'
    for i in "${!ORDER[@]}"; do
      printf '  - bc: %s\n' "${ORDER[$i]}"
      printf '    status: %s\n' "${ST[$i]}"
      printf '    output: %s\n' "${OUT[$i]}"
      [ -n "${CYC[$i]}" ] && printf '    cycle: %s\n' "${CYC[$i]}"
    done
    if [ "${#EFROM[@]}" -eq 0 ]; then
      printf 'escalations: []\n'
    else
      printf 'escalations:\n'
      for i in "${!EFROM[@]}"; do
        printf '  - from: %s\n' "${EFROM[$i]}"
        printf '    to: %s\n' "${ETO[$i]}"
        printf '    reason: %s\n' "${EREASON[$i]}"
      done
    fi
    printf 'ledgers:\n'
    for i in "${!LEDGER_KEYS[@]}"; do printf '  %s: %s\n' "${LEDGER_KEYS[$i]}" "${LV[$i]}"; done
  } > "$FILE"
}

advance() {
  local i
  for i in "${!ORDER[@]}"; do [ "${ST[$i]}" != "$ST_DONE" ] && { printf '%s' "${ORDER[$i]}"; return; }; done
  printf '%s' "$BC_DONE"
}

case "$ACTION" in
  init)
    [ -f "$FILE" ] && wf_error "workflow-state: state already exists at $FILE"
    [ -n "$ID" ] || wf_error "init: --id is required"
    init_state_defaults
    WID="$ID"
    if [ -n "$USERSTORY" ]; then WSTORY="$USERSTORY"; else WSTORY="$(output_for "$FIRST_BC")"; fi
    WCUR="$FIRST_BC"
    if [ -n "$BRANCH" ]; then WBRANCH="$BRANCH"; else WBRANCH="story/$ID"; fi
    fi_idx="$(bc_index "$FIRST_BC")"; ST[$fi_idx]="$ST_ACTIVE"
    dev_idx="$(bc_index DEV)"; CYC[$dev_idx]="$DEV_CYCLE"
    for b in "${ORDER[@]}"; do mkdir -p "$DIR/$b"; done
    write_state
    printf "ok: initialized workflow '%s' (branch %s) at BA\n" "$ID" "$WBRANCH"
    ;;
  read)
    read_state
    if [ -z "$FIELD" ]; then cat "$FILE"; exit 0; fi
    case "$FIELD" in
      workflow-id) printf '%s\n' "$WID" ;;
      user-story)  printf '%s\n' "$WSTORY" ;;
      current-bc)  printf '%s\n' "$WCUR" ;;
      branch)      printf '%s\n' "$WBRANCH" ;;
      status.*|output.*|ledger.*)
        kind="${FIELD%%.*}"; key="${FIELD#*.}"
        case "$kind" in
          status) idx="$(bc_index "$(upper "$key")")" || wf_error "read: unknown bc '$key'"; printf '%s\n' "${ST[$idx]}" ;;
          output) idx="$(bc_index "$(upper "$key")")" || wf_error "read: unknown bc '$key'"; printf '%s\n' "${OUT[$idx]}" ;;
          ledger) found=""; for i in "${!LEDGER_KEYS[@]}"; do [ "${LEDGER_KEYS[$i]}" = "$key" ] && { printf '%s\n' "${LV[$i]}"; found=1; break; }; done; [ -n "$found" ] || wf_error "read: unknown ledger '$key'" ;;
        esac ;;
      *) wf_error "read: unknown field '$FIELD'" ;;
    esac
    ;;
  update)
    [ -n "$BC" ] || wf_error "update: --bc is required"
    case " ${ORDER[*]} " in *" $BC "*) ;; *) wf_error "update: unknown --bc '$BC'" ;; esac
    read_state
    idx="$(bc_index "$BC")"
    [ -n "$OUTPUT" ] && OUT[$idx]="$OUTPUT"
    if [ -n "$STATUS" ]; then
      case "$STATUS" in pending|active|done|escalated) ;; *) wf_error "update: invalid --status '$STATUS'" ;; esac
      ST[$idx]="$STATUS"
    fi
    if [ -n "$LEDGER" ]; then
      case "$LEDGER" in pending|done) ;; *) wf_error "update: invalid --ledger '$LEDGER'" ;; esac
      lk="$(lower "$BC")"; for i in "${!LEDGER_KEYS[@]}"; do [ "${LEDGER_KEYS[$i]}" = "$lk" ] && LV[$i]="$LEDGER"; done
    fi
    WCUR="$(advance)"
    write_state
    printf 'ok: %s updated; current-bc=%s\n' "$BC" "$WCUR"
    ;;
  escalate)
    [ -n "$FROM" ] || wf_error "escalate: --from is required"
    [ -n "$TO" ] || wf_error "escalate: --to is required"
    read_state
    fu="$(upper "$FROM")"; tu="$(upper "$TO")"
    fidx="$(bc_index "$fu")" || wf_error "escalate: unknown --from '$FROM'"
    tidx="$(bc_index "$tu")" || wf_error "escalate: unknown --to '$TO'"
    EFROM+=("$fu"); ETO+=("$tu"); EREASON+=("$REASON")
    ST[$fidx]="$ST_ESCALATED"; ST[$tidx]="$ST_ACTIVE"
    WCUR="$tu"
    write_state
    printf 'ok: escalated %s -> %s; current-bc=%s\n' "$fu" "$tu" "$tu"
    ;;
  *) wf_error "workflow-state: action must be init|read|update|escalate" ;;
esac
