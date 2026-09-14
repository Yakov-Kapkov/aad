#!/usr/bin/env bash
# list-qa-secrets.sh — Outputs credential key names and descriptions from qa.secrets.env.
# Reads only KEY names and comments — never outputs values.
# Output format: table with VAR NAME and DESCRIPTION columns.
# Usage: .sda/scripts/qa/list-qa-secrets.sh [secrets-root]
SECRETS_ROOT="${1:-.sda/secrets}"
SECRETS_FILE="$SECRETS_ROOT/qa.secrets.env"
if [ ! -f "$SECRETS_FILE" ]; then
  echo "INFO: $SECRETS_FILE not found." >&2
  exit 0
fi
pending_comment=""
keys=()
descs=()
while IFS= read -r line; do
  if [[ "$line" =~ ^#[[:space:]]*(.*) ]]; then
    pending_comment="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^([A-Z_][A-Z0-9_]*)= ]]; then
    keys+=("${BASH_REMATCH[1]}")
    descs+=("$pending_comment")
    pending_comment=""
  else
    pending_comment=""
  fi
done < "$SECRETS_FILE"

max_key=8  # minimum width for "VAR NAME" header
for k in "${keys[@]}"; do
  (( ${#k} > max_key )) && max_key=${#k}
done

fmt="%-${max_key}s | %s\n"
sep=$(printf '%*s' "$max_key" '' | tr ' ' '-')
printf "$fmt" "VAR NAME" "DESCRIPTION"
printf "%s-+-%s\n" "$sep" "-----------------------------"
for i in "${!keys[@]}"; do
  printf "$fmt" "${keys[$i]}" "${descs[$i]}"
done
