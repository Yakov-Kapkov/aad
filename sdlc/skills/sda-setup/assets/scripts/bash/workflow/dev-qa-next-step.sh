#!/usr/bin/env bash
# Housekeeper for the inner DEV+QA cycle - reads dev-qa-cycle-state.yaml and reports
# the single next step. Advises only; never triggers a functional agent.
#   dev-qa-next-step --dir <cycle-dir>
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CYCLE="$HERE/dev-qa-cycle-state.sh"

DIR="."
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="$2"; shift 2 ;;
    *) printf 'error=dev-qa-next-step: unknown arg %s\n' "$1"; exit 1 ;;
  esac
done

state() { bash "$CYCLE" read --dir "$DIR" --field "$1"; }

status="$(state status)"
case "$status" in error=*) printf '%s\n' "$status"; exit 1 ;; esac

run="$(state current-run)"
folder="$(state run-folder)"
open="$(state open-failures)"

printf 'cycle: run %s, status %s\n' "$run" "$status"

case "$status" in
  implementing)
    sha="$(state sha)"
    if [ "$sha" = "null" ] || [ -z "$sha" ]; then
      printf 'NEXT -> implement %s with sda-dev, then record the commit: dev-qa-cycle-state set-sha --sha <sha>\n' "$folder"
    else
      printf 'NEXT -> run PRIMARY QA with sda-qa (output -> %s), then record: dev-qa-cycle-state set-verdict --gate primary --verdict PASS|FAIL [--failures ...]\n' "$folder"
    fi
    ;;
  qa-regression)
    printf 'PRIMARY passed. NEXT -> update the ledgers: sda-dev-context-writer (system context) + sda-qa-context-writer (test-case library).\n'
    printf '     then run blast-radius: if pending behaviours remain, author + run regression QA (sda-qa-task regression-only -> sda-qa) and record: dev-qa-cycle-state set-verdict --gate regression --verdict PASS|FAIL\n'
    printf '     if none pending, the cycle is done: dev-qa-cycle-state set-verdict --gate regression --verdict PASS\n'
    ;;
  rework)
    printf 'Run %s FAILED - open failures: %s\n' "$run" "$open"
    printf 'NEXT -> author a fix task from those failures with sda-dev-task, then: dev-qa-cycle-state bump-run  (and implement the new run)\n'
    ;;
  passed)
    printf 'NEXT -> none. Cycle complete - the task is verified across both gates.\n'
    ;;
  *)
    printf "error=dev-qa-next-step: unknown status '%s'\n" "$status"; exit 1 ;;
esac
