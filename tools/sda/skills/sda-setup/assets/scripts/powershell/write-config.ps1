# write-config.ps1
# Normalizes .sda/project-config.json against the template, then applies
# user answers for the fields that were configured in this session.
#
# Usage:
#   .\write-config.ps1 `
#       -TemplateFile  ".sda/resources/project-config.example.json" `
#       -ConfigFile    ".sda/project-config.json" `
#       -CoverageEnabled <true|false|keep>
#
# Pass "keep" for any field the user declined to reconfigure — its existing
# value (or the template default on first run) will be preserved.

param(
    [Parameter(Mandatory)][string]$TemplateFile,
    [Parameter(Mandatory)][string]$ConfigFile,
    [string]$CoverageEnabled = 'keep'
)

$ErrorActionPreference = 'Stop'

# Load template (source of defaults and schema)
$template = Get-Content $TemplateFile -Raw | ConvertFrom-Json

# Load existing config, or start from empty object
if (Test-Path $ConfigFile) {
    $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
} else {
    $config = [PSCustomObject]@{}
}

# --- Step 1: Add missing fields from template (deep merge, template wins for structure) ---
function Merge-Defaults {
    param($target, $source)
    foreach ($prop in $source.PSObject.Properties) {
        if ($null -eq $target.PSObject.Properties[$prop.Name]) {
            $target | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
        } elseif ($prop.Value -is [PSCustomObject]) {
            Merge-Defaults $target.$($prop.Name) $prop.Value
        }
    }
}
Merge-Defaults $config $template

# --- Step 2: Remove stale fields (present in config but not in template) ---
function Remove-Stale {
    param($target, $source)
    $toRemove = @()
    foreach ($prop in $target.PSObject.Properties) {
        if ($null -eq $source.PSObject.Properties[$prop.Name]) {
            $toRemove += $prop.Name
        } elseif ($prop.Value -is [PSCustomObject]) {
            Remove-Stale $prop.Value $source.$($prop.Name)
        }
    }
    foreach ($name in $toRemove) {
        $target.PSObject.Properties.Remove($name)
    }
}
Remove-Stale $config $template

# --- Step 3: Apply user answers (only non-"keep" values) ---
if ($CoverageEnabled -ne 'keep') {
    $config.tests.coverage.enabled = [System.Convert]::ToBoolean($CoverageEnabled)
}

# Set task-state script path for this platform
$config.scripts.taskState       = '.sda/scripts/dev/task-state.ps1'
$config.scripts.loadQaSecrets   = '.sda/scripts/qa/load-qa-secrets.ps1'
$config.scripts.listQaSecrets   = '.sda/scripts/qa/list-qa-secrets.ps1'
$config.scripts.qaSessionInit   = '.sda/scripts/qa/qa-session-init.ps1'
$config.scripts.invokeHttp      = '.sda/scripts/qa/invoke-http.ps1'

# Write result using a recursive serializer — avoids PS 5.1 ConvertTo-Json indent bugs
function Format-Json {
    param($obj, [int]$depth = 0)
    $pad   = '  ' * $depth
    $inner = '  ' * ($depth + 1)
    if ($null -eq $obj)                                          { return 'null' }
    if ($obj -is [bool])                                         { return $obj.ToString().ToLower() }
    if ($obj -is [int] -or $obj -is [long] -or
        $obj -is [double] -or $obj -is [decimal])                { return "$obj" }
    if ($obj -is [string])                                       { return '"' + ($obj -replace '\\','\\' -replace '"','\"') + '"' }
    if ($obj -is [PSCustomObject]) {
        $props = @($obj.PSObject.Properties)
        if ($props.Count -eq 0) { return '{}' }
        $entries = $props | ForEach-Object {
            $k = '"' + $_.Name + '"'
            $v = Format-Json $_.Value ($depth + 1)
            "$inner$k`: $v"
        }
        return "{`n$($entries -join ",`n")`n$pad}"
    }
    return '"' + "$obj" + '"'
}
(Format-Json $config) | Set-Content -Path $ConfigFile -NoNewline
Write-Output "project-config.json written: $ConfigFile"
