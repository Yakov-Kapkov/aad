#!/usr/bin/env bash
# Housekeeper for the outer SDLC workflow - reads workflow-state.yaml and reports the
# single next BC action. Advises only; never triggers a functional agent. Mirrors
# workflow-next-step.ps1 and prints identical text.
#   workflow-next-step --dir <workflow-dir>
# Per the housekeeper guardrail it MUST NOT invoke any BC agent - bookkeeping and
# "here is what is next" only.
set -uo pipefail

DIR="."
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="$2"; shift 2 ;;
    *) printf 'error=workflow-next-step: unknown arg %s\n' "$1"; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state() { bash "$SCRIPT_DIR/workflow-state.sh" read --dir "$DIR" --field "$1" 2>&1; }

cur="$(state current-bc)"
case "$cur" in error=*) printf '%s\n' "$cur"; exit 1 ;; esac
branch="$(state branch)"
printf 'workflow: current-bc %s, branch %s\n' "$cur" "$branch"

case "$cur" in
  BA)
    o="$(state output.ba)"
    printf 'NEXT -> invoke sda-ba with the requirement. output -> %s\n' "$o"
    printf '     then record: workflow-state update --bc BA --status done --ledger done\n'
    ;;
  DESIGN)
    ba="$(state output.ba)"; o="$(state output.design)"
    printf 'NEXT -> invoke sda-system / sda-feature with the User Story (%s). output -> %s (staged in the pending overlay).\n' "$ba" "$o"
    printf '     then record: workflow-state update --bc DESIGN --status done --ledger done\n'
    ;;
  DEV)
    printf 'DEV+QA span. NEXT -> author DEV/task.md (sda-dev-task) + QA/qa-task.md (sda-qa-task), then drive the inner cycle with dev-qa-next-step in DEV/.\n'
    printf "     when the inner cycle status is 'passed', record the span: workflow-state update --bc DEV --status done --ledger done ; workflow-state update --bc QA --status done --ledger done\n"
    ;;
  QA)
    o="$(state output.qa)"
    printf 'NEXT -> QA pending. If the inner DEV+QA cycle passed, record: workflow-state update --bc QA --status done --ledger done.\n'
    printf '     for standalone QA, run sda-qa against %s first.\n' "$o"
    ;;
  DEP)
    o="$(state output.dep)"
    printf 'NEXT -> run the DEP step (deployment context). output -> %s\n' "$o"
    printf '     then record: workflow-state update --bc DEP --status done --ledger done\n'
    ;;
  done)
    pending=""
    for k in ba design dev qa dep; do
      [ "$(state "ledger.$k")" != "done" ] && pending=$([ -z "$pending" ] && printf '%s' "$k" || printf '%s, %s' "$pending" "$k")
    done
    if [ -z "$pending" ]; then
      printf 'NEXT -> all BCs + ledgers done. Human merge of %s to complete the story.\n' "$branch"
    else
      printf 'current-bc done, but ledgers pending: %s. Resolve before merge.\n' "$pending"
    fi
    ;;
  *)
    printf "error=workflow-next-step: unknown current-bc '%s'\n" "$cur"; exit 1
    ;;
esac
