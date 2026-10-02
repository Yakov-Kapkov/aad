#!/usr/bin/env bash
set -euo pipefail

# task-state.sh — Manages state.json for SDA task tracking.
#
# Usage:
#   task-state.sh init   <task-folder> <task-name> <units-json>
#   task-state.sh get    <task-folder>
#   task-state.sh next   <task-folder>
#   task-state.sh update <task-folder> <unit-number> <state> [symbols-json]

COMMAND="${1:-}"
TASK_FOLDER="${2:-}"

if [[ -z "$COMMAND" || -z "$TASK_FOLDER" ]]; then
  echo "Usage: task-state.sh <command> <task-folder> [args...]" >&2
  exit 1
fi

# Resolve task folder — accept full path or just folder name
resolve_task_folder() {
  local input="$1"

  # Already a valid path
  if [[ -f "$input/state.json" || -f "$input/task.md" ]]; then
    echo "$input"; return
  fi

  # Search known locations
  for candidate in \
    ".sda/tasks/$input" \
    ".sda/backlog/$input"
  do
    if [[ -d "$candidate" ]]; then
      echo "$candidate"; return
    fi
  done

  # Init command — folder may not exist yet
  if [[ "$COMMAND" == "init" ]]; then
    echo "$input"; return
  fi

  echo "Error: Task folder '$input' not found in .sda/tasks/ or .sda/backlog/." >&2
  exit 1
}

TASK_FOLDER="$(resolve_task_folder "$TASK_FOLDER")"
STATE_FILE="$TASK_FOLDER/state.json"

update_task_status() {
  local file="$1"
  local all_done=true
  local any_started=false

  local count
  count=$(jq '.units | length' "$file")

  for ((i = 0; i < count; i++)); do
    local unit_state
    unit_state=$(jq -r ".units[$i].state" "$file")
    if [[ "$unit_state" != "DONE" ]]; then
      all_done=false
    fi
    if [[ "$unit_state" != "PENDING" ]]; then
      any_started=true
    fi
  done

  if [[ "$all_done" == "true" ]]; then
    jq '.status = "DONE"' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  elif [[ "$any_started" == "true" ]]; then
    jq '.status = "IN-PROGRESS"' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
}

case "$COMMAND" in
  init)
    TASK_NAME="${3:-}"
    UNITS_JSON="${4:-}"

    if [[ -z "$TASK_NAME" ]]; then
      echo "Error: task-name is required for init." >&2
      exit 1
    fi
    if [[ -z "$UNITS_JSON" ]]; then
      echo "Error: units JSON is required for init." >&2
      exit 1
    fi

    mkdir -p "$TASK_FOLDER"

    jq -n \
      --arg task "$TASK_NAME" \
      --argjson units "$UNITS_JSON" \
      '{
        task: $task,
        status: "PENDING",
        units: [$units | to_entries[] | {number: (.value.number // (.key + 1)), name: .value.name, state: "PENDING", scenarios: (.value.scenarios // 0), symbols: []}]
      }' > "$STATE_FILE"

    unit_count=$(jq '.units | length' "$STATE_FILE")
    echo "state.json created: ${unit_count} units."
    ;;

  get)
    if [[ ! -f "$STATE_FILE" ]]; then
      echo "Error: state.json not found in $TASK_FOLDER" >&2
      exit 1
    fi
    jq '.' "$STATE_FILE"
    ;;

  next)
    if [[ ! -f "$STATE_FILE" ]]; then
      echo "Error: state.json not found in $TASK_FOLDER" >&2
      exit 1
    fi
    result=$(jq '[.units[] | select(.state != "DONE")] | first // empty' "$STATE_FILE")
    if [[ -z "$result" ]]; then
      echo '{"done": true}'
    else
      echo "$result"
    fi
    ;;

  update)
    UNIT_NUMBER="${3:-}"
    NEW_STATE="${4:-}"

    if [[ -z "$UNIT_NUMBER" || -z "$NEW_STATE" ]]; then
      echo "Error: unit-number and state are required for update." >&2
      exit 1
    fi

    if [[ ! "$NEW_STATE" =~ ^(PENDING|RED|GREEN|DONE)$ ]]; then
      echo "Error: state must be PENDING, RED, GREEN, or DONE." >&2
      exit 1
    fi

    if [[ ! -f "$STATE_FILE" ]]; then
      echo "Error: state.json not found in $TASK_FOLDER" >&2
      exit 1
    fi

    # Update unit by stored number field
    idx=$(jq --argjson n "$UNIT_NUMBER" '.units | to_entries[] | select(.value.number == $n) | .key' "$STATE_FILE")
    if [[ -z "$idx" ]]; then
      echo "Error: Unit $UNIT_NUMBER not found." >&2
      exit 1
    fi

    SYMBOLS_JSON="${5:-}"
    if [[ -n "$SYMBOLS_JSON" ]]; then
      jq --argjson idx "$idx" --arg s "$NEW_STATE" --argjson sym "$SYMBOLS_JSON" \
        '.units[$idx].state = $s | .units[$idx].symbols = $sym' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    else
      jq --argjson idx "$idx" --arg s "$NEW_STATE" \
        '.units[$idx].state = $s' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    fi

    update_task_status "$STATE_FILE"

    task_status=$(jq -r '.status' "$STATE_FILE")
    echo "Unit $UNIT_NUMBER -> $NEW_STATE. Task status: $task_status."
    ;;

  *)
    echo "Error: Unknown command '$COMMAND'. Use: init, get, next, update." >&2
    exit 1
    ;;
esac
