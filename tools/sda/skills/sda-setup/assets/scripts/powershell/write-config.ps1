# write-config.ps1
# Normalizes .sda/project-config.json against the template:
# adds missing fields, preserves existing values.
#
# Usage:
#   .\write-config.ps1 `
#       -TemplateFile  ".sda/resources/project-config.example.json" `
#       -ConfigFile    ".sda/project-config.json"
#
# Adds fields missing from the config. Existing field values are preserved.

param(
    [Parameter(Mandatory)][string]$TemplateFile,
    [Parameter(Mandatory)][string]$ConfigFile
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

# --- Step 2: Set platform script paths (never override user values) ---
$platformPaths = [ordered]@{
    taskState        = '.sda/scripts/dev/task-state.ps1'
    unitFileSize     = '.sda/scripts/dev/unit-file-size.ps1'
    readProjectTools = '.sda/scripts/read-project-tools.ps1'
    loadQaSecrets = '.sda/scripts/qa/load-qa-secrets.ps1'
    listQaSecrets = '.sda/scripts/qa/list-qa-secrets.ps1'
    qaSessionInit = '.sda/scripts/qa/qa-session-init.ps1'
    invokeHttp    = '.sda/scripts/qa/invoke-http.ps1'
    docsIntegrity = '.sda/scripts/docs/docs-integrity.ps1'
    workflow      = '.sda/scripts/workflow/workflow.ps1'
}
$shippedPaths = @{
    taskState        = @('.sda/scripts/dev/task-state.ps1', '.sda/scripts/dev/task-state.sh')
    unitFileSize     = @('.sda/scripts/dev/unit-file-size.ps1', '.sda/scripts/dev/unit-file-size.sh')
    readProjectTools = @('.sda/scripts/read-project-tools.ps1', '.sda/scripts/read-project-tools.sh')
    loadQaSecrets = @('.sda/scripts/qa/load-qa-secrets.ps1', '.sda/scripts/qa/load-qa-secrets.sh')
    listQaSecrets = @('.sda/scripts/qa/list-qa-secrets.ps1', '.sda/scripts/qa/list-qa-secrets.sh')
    qaSessionInit = @('.sda/scripts/qa/qa-session-init.ps1', '.sda/scripts/qa/qa-session-init.sh')
    invokeHttp    = @('.sda/scripts/qa/invoke-http.ps1', '.sda/scripts/qa/invoke-http.sh')
    # docsIntegrity: the first pair is the pre-rename location — kept so existing
    # installs migrate to the new folder instead of keeping a stale path.
    docsIntegrity = @('.sda/scripts/decisions/docs-integrity.ps1', '.sda/scripts/decisions/docs-integrity.sh',
                      '.sda/scripts/docs/docs-integrity.ps1',      '.sda/scripts/docs/docs-integrity.sh')
    workflow      = @('.sda/scripts/workflow/workflow.ps1', '.sda/scripts/workflow/workflow.sh')
}
foreach ($key in $platformPaths.Keys) {
    if ($null -eq $config.scripts.PSObject.Properties[$key]) {
        $config.scripts | Add-Member -NotePropertyName $key -NotePropertyValue $platformPaths[$key]
    } elseif ($config.scripts.$key -in $shippedPaths[$key]) {
        $config.scripts.$key = $platformPaths[$key]
    }
}

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
