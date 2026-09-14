#Requires -Version 5.1
<#
.SYNOPSIS
    Probes for data-format validator tools and outputs a pipe-delimited table.

.DESCRIPTION
    Probes each validator tool in priority order for JSON, YAML, XML, and TOML.
    Runs every probe individually and records availability and exit code.

    Output format (one header row, then one row per probe):
        format|tool|available|exit_code|command

    Columns:
        format    — JSON | YAML | XML | TOML
        tool      — tool identifier (e.g. jq, yamllint, powershell, python, node)
        available — YES | NO
        exit_code — numeric exit code (0 = success; -1073740791 = EDR block; 9009 = not found)
        command   — validator command template with {path} placeholder; empty when available=NO

    The agent reads this table to:
      1. Select the first YES row per format as the validator command.
      2. Scan all rows for exit_code -1073740791 (EDR block) and warn the user.

    PowerShell built-ins (ConvertFrom-Json, [xml]) are always available on Windows —
    no probe needed; they are hardcoded YES.

    All probes suppress stderr to avoid noise from missing-binary errors.
    Each probe is run individually (never chained) to capture its own exit code.
#>

$ErrorActionPreference = 'SilentlyContinue'

Write-Output "format|tool|available|exit_code|command"

function Probe {
    param([string]$Format, [string]$Tool, [string]$ProbeCmd, [string]$ValidateCmd)

    $result = & cmd /c "$ProbeCmd 2>nul" 2>$null
    $ec = $LASTEXITCODE

    if ($ec -eq 0) {
        Write-Output "$Format|$Tool|YES|$ec|$ValidateCmd"
    } else {
        Write-Output "$Format|$Tool|NO|$ec|"
    }
}

# ── JSON ─────────────────────────────────────────────────────────────────────

# PowerShell built-in — always present on Windows
Write-Output "JSON|powershell|YES|0|Get-Content '{path}' | ConvertFrom-Json | Out-Null"

Probe -Format "JSON" -Tool "jq" `
    -ProbeCmd "jq --version" `
    -ValidateCmd "jq . {path}"

Probe -Format "JSON" -Tool "python" `
    -ProbeCmd "python -c `"import json`"" `
    -ValidateCmd "python -m json.tool {path}"

Probe -Format "JSON" -Tool "python3" `
    -ProbeCmd "python3 -c `"import json`"" `
    -ValidateCmd "python3 -m json.tool {path}"

Probe -Format "JSON" -Tool "node" `
    -ProbeCmd "node --version" `
    -ValidateCmd "node -e `"JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))`" {path}"

# ── YAML ─────────────────────────────────────────────────────────────────────

Probe -Format "YAML" -Tool "yamllint" `
    -ProbeCmd "yamllint --version" `
    -ValidateCmd "yamllint {path}"

Probe -Format "YAML" -Tool "yq" `
    -ProbeCmd "yq --version" `
    -ValidateCmd "yq e {path}"

Probe -Format "YAML" -Tool "python-yaml" `
    -ProbeCmd "python -c `"import yaml`"" `
    -ValidateCmd "python -c `"import yaml,sys;yaml.safe_load(open(sys.argv[1]))`" {path}"

Probe -Format "YAML" -Tool "python3-yaml" `
    -ProbeCmd "python3 -c `"import yaml`"" `
    -ValidateCmd "python3 -c `"import yaml,sys;yaml.safe_load(open(sys.argv[1]))`" {path}"

Probe -Format "YAML" -Tool "node-js-yaml" `
    -ProbeCmd "node -e `"require('./node_modules/js-yaml')`"" `
    -ValidateCmd "node -e `"const y=require('./node_modules/js-yaml');y.load(require('fs').readFileSync(process.argv[1],'utf8'))`" {path}"

# ── XML ──────────────────────────────────────────────────────────────────────

# PowerShell built-in — always present on Windows
Write-Output "XML|powershell|YES|0|[xml](Get-Content '{path}') | Out-Null"

Probe -Format "XML" -Tool "xmllint" `
    -ProbeCmd "xmllint --version" `
    -ValidateCmd "xmllint --noout {path}"

Probe -Format "XML" -Tool "python-xml" `
    -ProbeCmd "python -c `"import xml`"" `
    -ValidateCmd "python -c `"import xml.etree.ElementTree as ET;ET.parse(sys.argv[1])`" {path}"

Probe -Format "XML" -Tool "python3-xml" `
    -ProbeCmd "python3 -c `"import xml`"" `
    -ValidateCmd "python3 -c `"import xml.etree.ElementTree as ET;ET.parse(sys.argv[1])`" {path}"

# ── TOML ─────────────────────────────────────────────────────────────────────

Probe -Format "TOML" -Tool "taplo" `
    -ProbeCmd "taplo --version" `
    -ValidateCmd "taplo check {path}"

Probe -Format "TOML" -Tool "python-tomllib" `
    -ProbeCmd "python -c `"import tomllib`"" `
    -ValidateCmd "python -c `"import tomllib,sys;tomllib.load(open(sys.argv[1],'rb'))`" {path}"

Probe -Format "TOML" -Tool "python3-tomllib" `
    -ProbeCmd "python3 -c `"import tomllib`"" `
    -ValidateCmd "python3 -c `"import tomllib,sys;tomllib.load(open(sys.argv[1],'rb'))`" {path}"

Probe -Format "TOML" -Tool "python-tomli" `
    -ProbeCmd "python -c `"import tomli`"" `
    -ValidateCmd "python -c `"import tomli,sys;tomli.load(open(sys.argv[1],'rb'))`" {path}"

Probe -Format "TOML" -Tool "python3-tomli" `
    -ProbeCmd "python3 -c `"import tomli`"" `
    -ValidateCmd "python3 -c `"import tomli,sys;tomli.load(open(sys.argv[1],'rb'))`" {path}"
