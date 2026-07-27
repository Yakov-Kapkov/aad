#!/usr/bin/env bash
# load-qa-secrets.sh — Sources qa.secrets.env into the current shell session.
# Must be dot-sourced (not executed) for env vars to propagate to the caller.
# Outputs a table: var_name | is_empty — showing every variable loaded.
# Usage: . ".sda/scripts/qa/load-qa-secrets.sh" [secrets-root]
SECRETS_ROOT="${1:-.sda/secrets}"
SECRETS_FILE="$SECRETS_ROOT/qa.secrets.env"
if [ -f "$SECRETS_FILE" ]; then
  # Collect key names before sourcing
  _qa_keys=()
  while IFS= read -r _qa_line; do
    if [[ "$_qa_line" =~ ^([A-Z_][A-Z0-9_]*)= ]]; then
      _qa_keys+=("${BASH_REMATCH[1]}")
    fi
  done < "$SECRETS_FILE"
  set -a
  # shellcheck source=/dev/null
  . "$SECRETS_FILE"
  set +a
  # Output table
  printf "%-40s %s\n" "var_name" "is_empty"
  printf "%-40s %s\n" "--------" "--------"
  for _qa_k in "${_qa_keys[@]}"; do
    if [ -z "${!_qa_k}" ]; then
      printf "%-40s %s\n" "$_qa_k" "true"
    else
      printf "%-40s %s\n" "$_qa_k" "false"
    fi
  done
  unset _qa_keys _qa_line _qa_k
else
  echo "WARNING: Secrets file not found - credentials must already be in environment." >&2
fi
