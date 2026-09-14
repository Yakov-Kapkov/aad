#!/usr/bin/env bash
# End-to-end test for the DEV+QA cycle-state + next-step bash scripts.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="$(mktemp -d)/cyc"
fail=0
check() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fail=$((fail+1)); fi; }
cyc() { bash "$HERE/dev-qa-cycle-state.sh" "$@"; }
next() { bash "$HERE/dev-qa-next-step.sh" --dir "$DIR"; }
field() { cyc read --dir "$DIR" --field "$1"; }

o="$(cyc init --dir "$DIR" --task add-auth)"
check "init ok" '[[ "$o" == *"initialized cycle"* ]]'
check "run-01 folder" '[ -d "$DIR/runs/run-01" ]'
check "status implementing" '[ "$(field status)" = "implementing" ]'
check "spec default" '[ "$(field spec)" = "runs/run-01/task.md" ]'
check "sha null" '[ "$(field sha)" = "null" ]'
check "next=implement" '[[ "$(next)" == *"implement runs/run-01 with sda-dev"* ]]'

cyc set-sha --dir "$DIR" --sha abc123 >/dev/null
check "sha set" '[ "$(field sha)" = "abc123" ]'
check "next=primary QA" '[[ "$(next)" == *"PRIMARY QA with sda-qa"* ]]'

cyc set-verdict --dir "$DIR" --gate primary --verdict FAIL --failures "FR-3,NFR-1" >/dev/null
check "status rework" '[ "$(field status)" = "rework" ]'
check "open-failures set" '[ "$(field open-failures)" = "[FR-3, NFR-1]" ]'
check "verdict recorded" '[ "$(field verdict)" = "FAIL" ]'
check "next=rework" '[[ "$(next)" == *"author a fix task"* ]]'
check "next shows failures" '[[ "$(next)" == *"FR-3, NFR-1"* ]]'

cyc bump-run --dir "$DIR" >/dev/null
check "bumped to 2" '[ "$(field current-run)" = "2" ]'
check "run-02 folder" '[ -d "$DIR/runs/run-02" ]'
check "status implementing again" '[ "$(field status)" = "implementing" ]'
check "open cleared" '[ "$(field open-failures)" = "[]" ]'

cyc set-sha --dir "$DIR" --sha def456 >/dev/null
cyc set-verdict --dir "$DIR" --gate primary --verdict PASS >/dev/null
check "status qa-regression" '[ "$(field status)" = "qa-regression" ]'
check "next=ledgers" '[[ "$(next)" == *"sda-dev-context-writer"* && "$(next)" == *"sda-qa-context-writer"* ]]'

cyc set-verdict --dir "$DIR" --gate regression --verdict PASS >/dev/null
check "status passed" '[ "$(field status)" = "passed" ]'
check "next=done" '[[ "$(next)" == *"Cycle complete"* ]]'

check "two runs recorded" '[ "$(grep -c "^  - run:" "$DIR/dev-qa-cycle-state.yaml")" = "2" ]'
check "run1 sha" 'grep -q "sha: abc123" "$DIR/dev-qa-cycle-state.yaml"'
check "run2 sha" 'grep -q "sha: def456" "$DIR/dev-qa-cycle-state.yaml"'

check "read missing errors" '[[ "$(cyc read --dir "$DIR/nope")" == error=* ]]'
check "double init errors" '[[ "$(cyc init --dir "$DIR" --task x)" == error=* ]]'

# === outer SDLC-workflow scripts: workflow-state + workflow-next-step ===
WDIR="$(mktemp -d)/ws"
wf() { bash "$HERE/workflow-state.sh" "$@"; }
wnext() { bash "$HERE/workflow-next-step.sh" --dir "$1"; }
wfield() { wf read --dir "$WDIR" --field "$1"; }

o="$(wf init --dir "$WDIR" --id 0007-login)"
check "wf init ok" '[[ "$o" == *"initialized workflow"* ]]'
check "wf subfolders BA..DEP" '[ -d "$WDIR/BA" ] && [ -d "$WDIR/DEV" ] && [ -d "$WDIR/DEP" ]'
check "wf current-bc BA" '[ "$(wfield current-bc)" = "BA" ]'
check "wf branch default" '[ "$(wfield branch)" = "story/0007-login" ]'
check "wf status.ba active" '[ "$(wfield status.ba)" = "active" ]'
check "wf status.design pending" '[ "$(wfield status.design)" = "pending" ]'
check "wf output.dev" '[ "$(wfield output.dev)" = "DEV/task.md" ]'
check "wf ledger.ba pending" '[ "$(wfield ledger.ba)" = "pending" ]'
check "wf next=BA" '[[ "$(wnext "$WDIR")" == *"invoke sda-ba"* ]]'
check "wf next bash-native flags" '[[ "$(wnext "$WDIR")" == *"--bc BA --status done --ledger done"* ]]'

wf update --dir "$WDIR" --bc BA --status done --ledger done >/dev/null
check "wf BA done -> DESIGN" '[ "$(wfield current-bc)" = "DESIGN" ]'
check "wf ledger.ba done" '[ "$(wfield ledger.ba)" = "done" ]'
check "wf status.ba done" '[ "$(wfield status.ba)" = "done" ]'
check "wf next=DESIGN" '[[ "$(wnext "$WDIR")" == *"sda-system / sda-feature"* ]]'

wf update --dir "$WDIR" --bc DESIGN --status done --ledger done >/dev/null
check "wf DESIGN done -> DEV" '[ "$(wfield current-bc)" = "DEV" ]'
check "wf next=DEV span" '[[ "$(wnext "$WDIR")" == *"DEV+QA span"* ]]'

wf update --dir "$WDIR" --bc DEV --status done --ledger done >/dev/null
wf update --dir "$WDIR" --bc QA --status done --ledger done >/dev/null
check "wf DEV+QA done -> DEP" '[ "$(wfield current-bc)" = "DEP" ]'
check "wf next=DEP" '[[ "$(wnext "$WDIR")" == *"DEP step"* ]]'

wf update --dir "$WDIR" --bc DEP --status done --ledger done >/dev/null
check "wf all done" '[ "$(wfield current-bc)" = "done" ]'
check "wf next=merge" '[[ "$(wnext "$WDIR")" == *"Human merge"* ]]'

EDIR="$(mktemp -d)/we"
wf init --dir "$EDIR" --id x --branch story/custom >/dev/null
check "wf custom branch" '[ "$(wf read --dir "$EDIR" --field branch)" = "story/custom" ]'
wf escalate --dir "$EDIR" --from QA --to BA --reason "US-3 not testable" >/dev/null
check "wf escalate -> BA" '[ "$(wf read --dir "$EDIR" --field current-bc)" = "BA" ]'
check "wf escalate status.qa" '[ "$(wf read --dir "$EDIR" --field status.qa)" = "escalated" ]'
check "wf escalation recorded" 'grep -q "reason: US-3 not testable" "$EDIR/workflow-state.yaml"'

check "wf double init errors" '[[ "$(wf init --dir "$WDIR" --id y)" == error=* ]]'
check "wf read missing errors" '[[ "$(wf read --dir "$EDIR/none")" == error=* ]]'

rm -rf "$(dirname "$WDIR")" "$(dirname "$EDIR")"

rm -rf "$(dirname "$DIR")"
if [ "$fail" = "0" ]; then echo; echo "ALL PASS"; exit 0; else echo; echo "$fail FAILED"; exit 1; fi
