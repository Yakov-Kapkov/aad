#!/usr/bin/env bash
# qa-session-init.sh — Initialise a QA terminal session.
# Must be dot-sourced so env vars propagate to the caller.
# Sets UTF-8 output, then loads QA credentials.
# Outputs a combined summary: script | result | notes, followed by a var_name | is_empty credentials table.
# Usage: . ".sda/scripts/qa/qa-session-init.sh" [secrets-root]
SECRETS_ROOT="${1:-.sda/secrets}"

_qa_summary=()

# 1. Set UTF-8 output
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
_qa_summary+=("set-encoding|OK|LC_ALL=$LC_ALL")

# 2. Load QA credentials from secrets file
SECRETS_FILE="$SECRETS_ROOT/qa.secrets.env"
_qa_keys=()
if [ -f "$SECRETS_FILE" ]; then
  while IFS= read -r _qa_line; do
    if [[ "$_qa_line" =~ ^([A-Z_][A-Z0-9_]*)= ]]; then
      _qa_keys+=("${BASH_REMATCH[1]}")
    fi
  done < "$SECRETS_FILE"
  set -a
  # shellcheck source=/dev/null
  . "$SECRETS_FILE"
  set +a
  _qa_summary+=("load-qa-secrets|OK|${#_qa_keys[@]} variable(s) loaded")
else
  _qa_summary+=("load-qa-secrets|WARN|Secrets file not found — credentials must already be in environment")
fi

# Output combined summary
echo ''
echo '=== QA Session Init ==='
printf "%-25s %-8s %s\n" "script" "result" "notes"
printf "%-25s %-8s %s\n" "------" "------" "-----"
for _qa_row in "${_qa_summary[@]}"; do
  IFS='|' read -r _s _r _n <<< "$_qa_row"
  printf "%-25s %-8s %s\n" "$_s" "$_r" "$_n"
done

if [ ${#_qa_keys[@]} -gt 0 ]; then
  echo ''
  echo '--- Credentials ---'
  printf "%-40s %s\n" "var_name" "is_empty"
  printf "%-40s %s\n" "--------" "--------"
  for _qa_k in "${_qa_keys[@]}"; do
    if [ -z "${!_qa_k}" ]; then
      printf "%-40s %s\n" "$_qa_k" "true"
    else
      printf "%-40s %s\n" "$_qa_k" "false"
    fi
  done
fi

unset _qa_summary _qa_keys _qa_line _qa_k _qa_row _s _r _n SECRETS_FILE SECRETS_ROOT
