#!/usr/bin/env bash
# Probes for data-format validator tools and outputs a pipe-delimited table.
#
# Output format (one header row, then one row per probe):
#     format|tool|available|exit_code|command
#
# Columns:
#     format    — JSON | YAML | XML | TOML
#     tool      — tool identifier (e.g. jq, yamllint, python, node)
#     available — YES | NO
#     exit_code — numeric exit code (0 = success; non-zero = absent/error)
#     command   — validator command template with {path} placeholder; empty when available=NO
#
# The agent reads this table to:
#   1. Select the first YES row per format as the validator command.
#   2. Scan all rows for unexpected non-zero exit codes and warn the user.
#
# All probes suppress stderr to avoid noise from missing-binary errors.
# Each probe is run individually to capture its own exit code.

echo "format|tool|available|exit_code|command"

probe() {
    local format="$1"
    local tool="$2"
    local probe_cmd="$3"
    local validate_cmd="$4"

    eval "$probe_cmd" >/dev/null 2>&1
    local ec=$?

    if [ $ec -eq 0 ]; then
        echo "$format|$tool|YES|$ec|$validate_cmd"
    else
        echo "$format|$tool|NO|$ec|"
    fi
}

# ── JSON ─────────────────────────────────────────────────────────────────────

probe "JSON" "jq" \
    "jq --version" \
    "jq . {path}"

probe "JSON" "python" \
    "python -c 'import json'" \
    "python -m json.tool {path}"

probe "JSON" "python3" \
    "python3 -c 'import json'" \
    "python3 -m json.tool {path}"

probe "JSON" "node" \
    "node --version" \
    "node -e \"JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))\" {path}"

# ── YAML ─────────────────────────────────────────────────────────────────────

probe "YAML" "yamllint" \
    "yamllint --version" \
    "yamllint {path}"

probe "YAML" "yq" \
    "yq --version" \
    "yq e {path}"

probe "YAML" "python-yaml" \
    "python -c 'import yaml'" \
    "python -c \"import yaml,sys;yaml.safe_load(open(sys.argv[1]))\" {path}"

probe "YAML" "python3-yaml" \
    "python3 -c 'import yaml'" \
    "python3 -c \"import yaml,sys;yaml.safe_load(open(sys.argv[1]))\" {path}"

probe "YAML" "node-js-yaml" \
    "node -e \"require('./node_modules/js-yaml')\"" \
    "node -e \"const y=require('./node_modules/js-yaml');y.load(require('fs').readFileSync(process.argv[1],'utf8'))\" {path}"

# ── XML ──────────────────────────────────────────────────────────────────────

probe "XML" "xmllint" \
    "xmllint --version" \
    "xmllint --noout {path}"

probe "XML" "python-xml" \
    "python -c 'import xml'" \
    "python -c \"import xml.etree.ElementTree as ET;ET.parse(sys.argv[1])\" {path}"

probe "XML" "python3-xml" \
    "python3 -c 'import xml'" \
    "python3 -c \"import xml.etree.ElementTree as ET;ET.parse(sys.argv[1])\" {path}"

# ── TOML ─────────────────────────────────────────────────────────────────────

probe "TOML" "taplo" \
    "taplo --version" \
    "taplo check {path}"

probe "TOML" "python-tomllib" \
    "python -c 'import tomllib'" \
    "python -c \"import tomllib,sys;tomllib.load(open(sys.argv[1],'rb'))\" {path}"

probe "TOML" "python3-tomllib" \
    "python3 -c 'import tomllib'" \
    "python3 -c \"import tomllib,sys;tomllib.load(open(sys.argv[1],'rb'))\" {path}"

probe "TOML" "python-tomli" \
    "python -c 'import tomli'" \
    "python -c \"import tomli,sys;tomli.load(open(sys.argv[1],'rb'))\" {path}"

probe "TOML" "python3-tomli" \
    "python3 -c 'import tomli'" \
    "python3 -c \"import tomli,sys;tomli.load(open(sys.argv[1],'rb'))\" {path}"
