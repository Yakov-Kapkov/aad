#!/usr/bin/env bash
# workflow.sh - Creates and maintains a workflow container and its workflow.json state.
#
# A workflow is a numbered folder holding one requirement's planning artifacts
# plus the state that tracks their progress. This script is the only writer of
# workflow.json; folders and state are never hand-edited.
#
# Commands:
#   init      Create a workflow folder, its tasks/ folder, and workflow.json.
#   list      One line per workflow; marks the deepest open escalation.
#   current   Print the stage, any open escalation, and artifact gaps.
#   read      Print workflow.json, or one field with --field.
#   advance   Move the stage forward exactly one stage.
#   escalate  Move the stage back, one or more stages, recording why and the evidence.
#   resolve   Close the deepest open escalation, then move forward one stage.
#
# Output contract:
#   mutation  ok: workflow '<folder>' <verb> <subject> -> '<stage>'
#   status    key=value lines (current)
#   raw       pretty-printed JSON, or the bare field value (read)
#   failure   error=<X cannot do Y because Z>, exit code 1
#
# The stage order is story -> design -> tasks -> ready. Every stage produces one
# artifact, and advance refuses to leave a stage whose artifact is absent. While
# any escalation is open, advance is refused and only resolve clears it.
#
# Usage:
#   workflow.sh init     --slug <slug>
#   workflow.sh list
#   workflow.sh current  --slug <folder>
#   workflow.sh read     --slug <folder> [--field <id|slug|created|stage|notes>]
#   workflow.sh advance  --slug <folder>
#   workflow.sh escalate --slug <folder> [--to <stage>] --reason <text> --brief <path>
#   workflow.sh resolve  --slug <folder> --id <E#> --report <text>
#
# --brief is the escalation's evidence: it must exist and sit in the workflow's
# escalations/ folder, and the raise is refused otherwise.
#
# Requires jq. ROOT defaults to .sda/workflows; override with --root.

set -uo pipefail

ROOT=".sda/workflows"
COMMAND="${1:-}"
SLUG=""
FIELD=""
TO=""
REASON=""
BRIEF=""
ID=""
REPORT=""

fail() {
  printf 'error=%s\n' "$1"
  exit 1
}

COMMAND_LIST="init, list, current, read, advance, escalate, resolve"

if [ -z "$COMMAND" ]; then
  fail "workflow cannot run because no command was given; expected one of: $COMMAND_LIST"
fi
shift || true

while [ $# -gt 0 ]; do
  case "$1" in
    --slug)   SLUG="${2:-}";   shift 2 ;;
    --field)  FIELD="${2:-}";  shift 2 ;;
    --to)     TO="${2:-}";     shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    --brief)  BRIEF="${2:-}";  shift 2 ;;
    --id)     ID="${2:-}";     shift 2 ;;
    --report) REPORT="${2:-}"; shift 2 ;;
    --root)   ROOT="${2:-}";   shift 2 ;;
    *)        fail "workflow cannot run because '$1' is not a known option";;
  esac
done

command -v jq >/dev/null 2>&1 || fail "workflow cannot run because jq is required but was not found on PATH"

stage_index() {
  case "$1" in
    story)  printf '0' ;;
    design) printf '1' ;;
    tasks)  printf '2' ;;
    ready)  printf '3' ;;
    *)      printf '%s' '-1' ;;
  esac
}

stage_name() {
  case "$1" in
    0) printf 'story' ;;
    1) printf 'design' ;;
    2) printf 'tasks' ;;
    3) printf 'ready' ;;
  esac
}

# A container is consistent only when its workflow.json exists, parses, carries
# the four required fields, and holds a known stage. Verified before any command
# reads or lists state, so a corrupted container stops the command instead of
# yielding a half-answer or an empty field.
verify_state() {
  local folder="$1" file="$1/workflow.json" field value

  [ -f "$file" ] \
    || fail "workflow cannot be read because $folder has no workflow.json"
  jq empty "$file" >/dev/null 2>&1 \
    || fail "workflow cannot be read because $file is not valid JSON"

  for field in id slug created stage; do
    value="$(jq -r --arg f "$field" '.[$f] // empty' "$file")"
    [ -n "$value" ] \
      || fail "workflow cannot be read because $file is missing '$field'"
  done

  value="$(jq -r '.stage' "$file")"
  [ "$(stage_index "$value")" -ge 0 ] \
    || fail "workflow cannot be read because $file has an unknown stage '$value'"
}

# One folder name per line, <NNN>. <slug> only, in numeric order.
list_folders() {
  [ -d "$ROOT" ] || return 0
  for dir in "$ROOT"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    if [[ "$name" =~ ^[0-9]{3}\.\ .+$ ]]; then
      printf '%s\n' "$name"
    fi
  done | sort
}

# The deepest open escalation as compact JSON on one line, or 'null'.
# Open-ness is derived from the append-only notes log: an escalation stays open
# until a resolution with the same id follows it. The stack is LIFO, so the last
# one raised is the deepest.
open_escalation() {
  jq -c '
    reduce .notes[] as $n ([];
      if   $n.type == "escalation" then . + [$n]
      elif $n.type == "resolution" then (map(.id) | index($n.id)) as $i
           | if $i == null then . else del(.[$i]) end
      else . end
    ) | if length > 0 then last else null end' "$1"
}

# E1, E2, ... assigned in order, never reused.
next_escalation_id() {
  jq -r '([.notes[] | select(.type == "escalation")] | length) + 1 | "E\(.)"' "$1"
}

# 0 when the stage's artifact exists. 'ready' has no artifact of its own, and
# 'tasks' counts only when the folder holds at least one entry.
artifact_present() {
  local folder="$1"
  case "$2" in
    story)  [ -e "$folder/user-story.md" ] && return 0 ;;
    design) [ -e "$folder/design.md" ] && return 0 ;;
    tasks)  [ -d "$folder/tasks" ] && [ -n "$(ls -A "$folder/tasks" 2>/dev/null)" ] && return 0 ;;
  esac
  return 1
}

artifact_label() {
  case "$1" in
    tasks)  printf 'the tasks/ folder has no task folder' ;;
    story)  printf 'user-story.md does not exist' ;;
    design) printf 'design.md does not exist' ;;
  esac
}

# Resolves a folder into FOLDER. Sets a global rather than printing to stdout:
# fail() inside $( ) exits only the subshell, so the error text would be captured
# as the path and the caller would prepend a second error to it.
# Accepts a folder name, a numeric id, or a slug.
resolve_folder() {
  local value="$1" name id

  FOLDER=""
  if [ -f "$ROOT/$value/workflow.json" ]; then
    FOLDER="$ROOT/$value"
    return 0
  fi

  if [[ "$value" =~ ^[0-9]{1,3}$ ]]; then
    id="$(printf '%03d' "$((10#$value))")"
    while IFS= read -r name; do
      case "$name" in
        "$id. "*) FOLDER="$ROOT/$name"; return 0 ;;
      esac
    done < <(list_folders)
  fi

  while IFS= read -r name; do
    if [ "${name:5}" = "$value" ]; then
      if [ -n "$FOLDER" ]; then
        fail "workflow '$value' cannot be resolved because several workflows use the slug '$value'"
      fi
      FOLDER="$ROOT/$name"
    fi
  done < <(list_folders)

  if [ -z "$FOLDER" ]; then
    fail "workflow '$value' cannot be resolved because no folder in $ROOT matches that name, id, or slug"
  fi
  return 0
}

case "$COMMAND" in
  init)
    [ -n "$SLUG" ] || fail "init cannot run because --slug is required"
    [[ "$SLUG" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] \
      || fail "init cannot create '$SLUG' because the slug must be kebab-case (lowercase letters, digits, single hyphens)"

    while IFS= read -r name; do
      if [ "${name:5}" = "$SLUG" ]; then
        fail "init cannot create '$SLUG' because $name already uses that slug"
      fi
    done < <(list_folders)

    highest=0
    while IFS= read -r name; do
      number=$((10#${name:0:3}))
      [ "$number" -gt "$highest" ] && highest="$number"
    done < <(list_folders)

    next=$((highest + 1))
    [ "$next" -le 999 ] \
      || fail "init cannot create a workflow because the numbering is exhausted (maximum prefix is 999)"

    id="$(printf '%03d' "$next")"
    folder="$ROOT/$id. $SLUG"
    mkdir -p "$folder/tasks" "$folder/escalations" \
      || fail "init cannot create '$SLUG' because $folder could not be created"

    jq -n --arg id "$id" --arg slug "$SLUG" --arg created "$(date +%F)" \
      '{id: $id, slug: $slug, created: $created, stage: "story", notes: []}' \
      > "$folder/workflow.json" \
      || fail "init cannot create '$SLUG' because $folder/workflow.json could not be written"

    printf "ok: workflow '%s. %s' created -> 'story'\n" "$id" "$SLUG"
    ;;

  list)
    names="$(list_folders)"
    if [ -z "$names" ]; then
      printf 'ok: no workflows\n'
      exit 0
    fi

    # Verify every container before printing anything: a corrupted folder must
    # stop the command, never leave a half-list behind.
    while IFS= read -r name; do
      verify_state "$ROOT/$name"
    done <<< "$names"

    while IFS= read -r name; do
      folder="$ROOT/$name"
      file="$folder/workflow.json"

      id="$(jq -r '.id' "$file")"
      slug="$(jq -r '.slug' "$file")"
      stage="$(jq -r '.stage' "$file")"
      created="$(jq -r '.created' "$file")"

      ejson="$(open_escalation "$file")"
      mark='-'
      if [ "$ejson" != "null" ]; then
        mark="escalation $(printf '%s' "$ejson" | jq -r '.id') open"
      fi

      printf '%s. %s | %s | %s | %s\n' "$id" "$slug" "$stage" "$mark" "$created"
    done <<< "$names"
    ;;

  read)
    [ -n "$SLUG" ] || fail "read cannot run because --slug is required"
    resolve_folder "$SLUG"
    folder="$FOLDER"
    file="$folder/workflow.json"
    verify_state "$folder"

    if [ -z "$FIELD" ]; then
      jq '.' "$file"
      exit 0
    fi

    case "$FIELD" in
      id|slug|created|stage) jq -r --arg f "$FIELD" '.[$f]' "$file" ;;
      notes)                 jq '.notes' "$file" ;;
      *)                     fail "read cannot print '$FIELD' because '$FIELD' is not a workflow field" ;;
    esac
    ;;

  current)
    [ -n "$SLUG" ] || fail "current cannot run because --slug is required"
    resolve_folder "$SLUG"
    folder="$FOLDER"
    file="$folder/workflow.json"
    verify_state "$folder"

    stage="$(jq -r '.stage' "$file")"
    index="$(stage_index "$stage")"

    printf "ok: workflow '%s'\n" "$(basename "$folder")"
    printf 'stage=%s\n' "$stage"

    # Artifact gaps up to and including the current stage. 'ready' has none.
    i=0
    while [ "$i" -le "$index" ]; do
      name="$(stage_name "$i")"
      if [ "$name" != "ready" ] && ! artifact_present "$folder" "$name"; then
        printf 'gap=%s\n' "$name"
      fi
      i=$((i + 1))
    done

    ejson="$(open_escalation "$file")"
    if [ "$ejson" = "null" ]; then
      printf 'escalation=none\n'
    else
      printf 'escalation=%s\n' "$(printf '%s' "$ejson" | jq -r '.id')"
      printf 'owner=%s\n'    "$(printf '%s' "$ejson" | jq -r '.to')"
      printf 'raisedBy=%s\n' "$(printf '%s' "$ejson" | jq -r '.from')"
      printf 'since=%s\n'    "$(printf '%s' "$ejson" | jq -r '.date')"
      printf 'reason=%s\n'   "$(printf '%s' "$ejson" | jq -r '.reason')"
      printf 'brief=%s\n'    "$(printf '%s' "$ejson" | jq -r '.brief // "-"')"
    fi
    ;;

  advance)
    [ -n "$SLUG" ] || fail "advance cannot run because --slug is required"
    resolve_folder "$SLUG"
    folder="$FOLDER"
    file="$folder/workflow.json"
    verify_state "$folder"

    current="$(jq -r '.stage' "$file")"
    ejson="$(open_escalation "$file")"
    if [ "$ejson" != "null" ]; then
      eid="$(printf '%s' "$ejson" | jq -r '.id')"
      fail "advance cannot move from '$current' because escalation $eid is open; run 'current', then 'resolve $eid'"
    fi

    index="$(stage_index "$current")"
    [ "$index" -lt 3 ] || fail "advance cannot move because the workflow is already at '$current'"
    artifact_present "$folder" "$current" \
      || fail "advance cannot leave '$current' because $(artifact_label "$current"); produce it first"

    next="$(stage_name "$((index + 1))")"
    jq --arg s "$next" '.stage = $s' "$file" > "$file.tmp" \
      && mv "$file.tmp" "$file" \
      || fail "advance cannot move from '$current' because $file could not be written"

    printf "ok: workflow '%s' advanced '%s' -> '%s'\n" "$(basename "$folder")" "$current" "$next"
    ;;

  escalate)
    [ -n "$SLUG" ] || fail "escalate cannot run because --slug is required"
    [ -n "$REASON" ] || fail "escalate cannot record an escalation because --reason is required"
    resolve_folder "$SLUG"
    folder="$FOLDER"
    file="$folder/workflow.json"
    verify_state "$folder"

    current="$(jq -r '.stage' "$file")"
    current_index="$(stage_index "$current")"
    [ "$current_index" -ge 1 ] \
      || fail "escalate cannot move back from '$current' because '$current' is the first stage"

    target="$TO"
    [ -n "$target" ] || target="$(stage_name "$((current_index - 1))")"
    target_index="$(stage_index "$target")"
    [ "$target_index" -ge 0 ] \
      || fail "escalate cannot target '$target' because '$target' is not a known stage"
    [ "$target_index" -ne "$current_index" ] \
      || fail "escalate cannot target '$target' because the workflow is already at '$target'"
    [ "$target_index" -lt "$current_index" ] \
      || fail "escalate cannot target '$target' because escalate only moves backwards"

    eid="$(next_escalation_id "$file")"

    # The brief is the escalation's evidence: it must exist and sit with the
    # workflow, so a raise can never point at an unrelated file. The path is
    # recorded as given and the file itself is never read.
    [ -n "$BRIEF" ] \
      || fail "escalate cannot open $eid because --brief is required; the evidence is not optional"

    case "$BRIEF" in
      /*) brief_path="$BRIEF" ;;
      *)  brief_path="$PWD/$BRIEF" ;;
    esac
    brief_parent="$(cd "$(dirname "$brief_path")" 2>/dev/null && pwd -P)" || brief_parent=""
    briefs_root="$(cd "$folder/escalations" 2>/dev/null && pwd -P)" || briefs_root=""
    if [ -z "$brief_parent" ] || [ "$brief_parent" != "$briefs_root" ]; then
      fail "escalate cannot open $eid because the brief must live in '$folder/escalations'"
    fi
    [ -f "$brief_path" ] \
      || fail "escalate cannot open $eid because brief '$BRIEF' is missing; write it first"

    jq --arg i "$eid" --arg f "$current" --arg t "$target" --arg r "$REASON" --arg b "$BRIEF" --arg d "$(date +%F)" \
      '.notes += [{type: "escalation", id: $i, from: $f, to: $t, reason: $r, brief: $b, date: $d}] | .stage = $t' \
      "$file" > "$file.tmp" && mv "$file.tmp" "$file" \
      || fail "escalate cannot open $eid because $file could not be written"

    printf "ok: workflow '%s' escalated '%s' -> '%s'\n" "$(basename "$folder")" "$current" "$target"
    ;;

  resolve)
    [ -n "$SLUG" ] || fail "resolve cannot run because --slug is required"
    [ -n "$ID" ] || fail "resolve cannot close an escalation because --id is required"
    [ -n "$REPORT" ] || fail "resolve cannot close $ID because --report is required; the next stage needs it"
    resolve_folder "$SLUG"
    folder="$FOLDER"
    file="$folder/workflow.json"
    verify_state "$folder"

    exists="$(jq --arg i "$ID" '[.notes[] | select(.type == "escalation" and .id == $i)] | length' "$file")"
    [ "$exists" -gt 0 ] \
      || fail "resolve cannot close $ID because no escalation $ID exists; run 'current' to list open escalations"

    ejson="$(open_escalation "$file")"
    [ "$ejson" != "null" ] || fail "resolve cannot close $ID because no escalation is open; run 'current'"

    deepest="$(printf '%s' "$ejson" | jq -r '.id')"
    [ "$deepest" = "$ID" ] \
      || fail "resolve cannot close $ID because $deepest is still open; close $deepest first"

    stage="$(jq -r '.stage' "$file")"
    index="$(stage_index "$stage")"
    next="$stage"
    if [ "$index" -lt 3 ]; then next="$(stage_name "$((index + 1))")"; fi

    jq --arg i "$ID" --arg r "$REPORT" --arg d "$(date +%F)" --arg s "$next" \
      '.notes += [{type: "resolution", id: $i, report: $r, date: $d}] | .stage = $s' \
      "$file" > "$file.tmp" && mv "$file.tmp" "$file" \
      || fail "resolve cannot close $ID because $file could not be written"

    printf "ok: workflow '%s' resolved '%s' -> '%s'\n" "$(basename "$folder")" "$ID" "$next"
    ;;

  *)
    fail "workflow cannot run because '$COMMAND' is not a known command; expected one of: $COMMAND_LIST"
    ;;
esac

# Exit code is explicit so a caller never sees a stale status from an earlier
exit 0
