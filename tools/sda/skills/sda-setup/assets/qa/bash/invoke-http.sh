#!/usr/bin/env bash
# invoke-http.sh — Execute an HTTP request; output STATUS: <code> and BODY: <body>.
# Usage: .sda/scripts/qa/invoke-http.sh -X GET -u "http://..." [-H "Name: Value"] [-d "<body>"] [--status-only]
METHOD='GET'
URI=''
STATUS_ONLY=0
CURL_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -X|--method)     METHOD="$2"; shift 2 ;;
    -u|--uri)        URI="$2"; shift 2 ;;
    -H|--header)     CURL_ARGS+=("-H" "$2"); shift 2 ;;
    -d|--data)       CURL_ARGS+=("-d" "$2"); shift 2 ;;
    --content-type)  CURL_ARGS+=("-H" "Content-Type: $2"); shift 2 ;;
    --status-only)   STATUS_ONLY=1; shift ;;
    *) shift ;;
  esac
done

BODY_FILE=$(mktemp)
HTTP_CODE=$(curl -s -o "$BODY_FILE" -w "%{http_code}" -X "$METHOD" "${CURL_ARGS[@]}" "$URI")
echo "STATUS: $HTTP_CODE"
if [[ $STATUS_ONLY -eq 0 ]]; then
  echo "BODY: $(cat "$BODY_FILE")"
fi
rm -f "$BODY_FILE"
