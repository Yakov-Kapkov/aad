#!/usr/bin/env bash
# No external tools required — only bash and awk (POSIX standard).
set -uo pipefail

AGENT="${1:-}"

if [ -z "$AGENT" ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}\n'
    exit 0
fi

CONFIG_FILE=".sda/project-config.json"
REPO_ROOT="$(pwd)"

# Agent → config keys (space-separated)
case "$AGENT" in
    sda-dev)           KEYS="scripts.taskState scripts.readProjectTools standardsSkill paths.specs tests.coverage.enabled" ;;
    sda-dev-quality)   KEYS="scripts.readProjectTools tests.coverage.enabled" ;;
    sda-dev-task)          KEYS="scripts.taskState scripts.unitFileSize devTaskUnitSizeLimit designOwnership standardsSkill paths.specs paths.tasks" ;;
    sda-dev-task-verifier) KEYS="scripts.unitFileSize devTaskUnitSizeLimit paths.specs" ;;
    sda-qa)            KEYS="paths.issues scripts.qaSessionInit scripts.loadQaSecrets scripts.invokeHttp scripts.readProjectTools" ;;
    sda-qa-task)       KEYS="designOwnership paths.tasks paths.issues paths.specs scripts.listQaSecrets scripts.readProjectTools" ;;
    sda-design)        KEYS="designOwnership paths.specs" ;;
    sda-scribe)        KEYS="paths.specs paths.issues" ;;
    sda-docs-check)    KEYS="scripts.docsIntegrity" ;;
    *)                 KEYS="" ;;
esac

if [ -z "$KEYS" ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}\n'
    exit 0
fi

# Return hardcoded default for a key, or empty string
get_default() {
    case "$1" in
        scripts.taskState)      echo ".sda/scripts/dev/task-state.sh" ;;
        scripts.unitFileSize)   echo ".sda/scripts/dev/unit-file-size.sh" ;;
        scripts.readProjectTools) echo ".sda/scripts/read-project-tools.sh" ;;
        scripts.loadQaSecrets)  echo ".sda/scripts/qa/load-qa-secrets.sh" ;;
        scripts.listQaSecrets)  echo ".sda/scripts/qa/list-qa-secrets.sh" ;;
        scripts.qaSessionInit)  echo ".sda/scripts/qa/qa-session-init.sh" ;;
        scripts.invokeHttp)     echo ".sda/scripts/qa/invoke-http.sh" ;;
        scripts.docsIntegrity)  echo ".sda/scripts/decisions/docs-integrity.sh" ;;
        devTaskUnitSizeLimit)   echo "1000" ;;
        designOwnership)        echo "user" ;;
        standardsSkill)         echo "standards-compliance" ;;
        paths.specs)            echo ".sda/specs" ;;
        paths.tasks)            echo ".sda/tasks" ;;
        paths.issues)           echo ".sda/issues" ;;
        tests.coverage.enabled) echo "true" ;;
        *)                      echo "" ;;
    esac
}

# Extract a scalar value from a JSON file by dotted path.
# Pure awk character-by-character parser — no external tools needed.
# Usage: json_get FILE DOTTED_PATH
# Returns the raw value (string unquoted, or number/boolean as-is), or "".
json_get() {
    local file="$1"
    local path="$2"
    awk -v path="$path" '
    { content = content $0 "\n" }
    END {
        n = split(path, keys, ".")
        pos = 1; len = length(content)
        while (pos <= len && substr(content, pos, 1) != "{") pos++
        pos++
        print traverse(n, 1)
    }
    function skip_ws(    c) {
        while (pos <= len) {
            c = substr(content, pos, 1)
            if (c != " " && c != "\t" && c != "\n" && c != "\r") break
            pos++
        }
    }
    function read_string(    c, ec, val) {
        pos++; val = ""
        while (pos <= len) {
            c = substr(content, pos, 1)
            if (c == "\\") {
                pos++; ec = substr(content, pos, 1)
                if      (ec == "\"") val = val "\""
                else if (ec == "\\") val = val "\\"
                else if (ec == "n")  val = val "\n"
                else if (ec == "t")  val = val "\t"
                else if (ec == "r")  val = val "\r"
                else                 val = val ec
            } else if (c == "\"") { pos++; return val }
            else { val = val c }
            pos++
        }
        return val
    }
    function read_scalar(    c, val) {
        val = ""
        while (pos <= len) {
            c = substr(content, pos, 1)
            if (c == "," || c == "}" || c == "]" || c == " " || c == "\t" || c == "\n" || c == "\r") break
            val = val c; pos++
        }
        return val
    }
    function skip_value(    c, d, bopen, bclose) {
        skip_ws(); c = substr(content, pos, 1)
        if (c == "\"") { read_string(); return }
        if (c == "{" || c == "[") {
            bopen = c; bclose = (c == "{") ? "}" : "]"; d = 1; pos++
            while (pos <= len && d > 0) {
                c = substr(content, pos, 1)
                if      (c == "\"")    read_string()
                else if (c == bopen)  { d++; pos++ }
                else if (c == bclose) { d--; pos++ }
                else                  pos++
            }
            return
        }
        read_scalar()
    }
    function traverse(total, level,    c, cur_key) {
        while (pos <= len) {
            skip_ws(); c = substr(content, pos, 1)
            if (c == "}") { pos++; return "" }
            if (c != "\"") { pos++; continue }
            cur_key = read_string()
            skip_ws(); pos++   # skip ":"
            skip_ws()
            if (cur_key == keys[level]) {
                if (level == total) {
                    c = substr(content, pos, 1)
                    if (c == "\"")             return read_string()
                    if (c == "{" || c == "[")  { skip_value(); return "" }
                    return read_scalar()
                } else {
                    if (substr(content, pos, 1) != "{") return ""
                    pos++
                    return traverse(total, level + 1)
                }
            } else {
                skip_value()
            }
            skip_ws()
            if (substr(content, pos, 1) == ",") pos++
        }
        return ""
    }
    ' "$file"
}

# Escape a string for embedding as a JSON string value.
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"       # backslash — must be first
    s="${s//\"/\\\"}"       # double quote
    s="${s//$'\n'/\\n}"     # newline
    s="${s//$'\t'/\\t}"     # tab
    s="${s//$'\r'/\\r}"     # carriage return
    printf '%s' "$s"
}

# --- Main logic ---

lines="Project configuration:"$'\n'"repoRoot=${REPO_ROOT}"
system_message=""

if [ -f "$CONFIG_FILE" ]; then
    for key in $KEYS; do
        val=$(json_get "$CONFIG_FILE" "$key")
        if [ -n "$val" ]; then
            lines="${lines}"$'\n'"${key}=${val}"
        else
            default=$(get_default "$key")
            [ -n "$default" ] && lines="${lines}"$'\n'"${key}=${default}"
        fi
    done
else
    system_message="Project not initialized. Say 'setup sda tool' to configure project paths."
    for key in $KEYS; do
        default=$(get_default "$key")
        [ -n "$default" ] && lines="${lines}"$'\n'"${key}=${default}"
    done
fi

ctx=$(json_escape "$lines")

if [ -n "$system_message" ]; then
    msg=$(json_escape "$system_message")
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"},"systemMessage":"%s"}\n' "$ctx" "$msg"
else
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$ctx"
fi
