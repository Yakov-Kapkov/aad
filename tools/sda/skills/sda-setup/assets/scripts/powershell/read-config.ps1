param(
    [Parameter(Mandatory=$true)][string]$Agent
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Per-agent key manifests — controls what each agent receives
$agentKeys = @{
    'sda-ba'            = @('paths.userStories','paths.workflows','scripts.workflow')
    'sda-dev'           = @('standardsSkill','paths.workflows','scripts.workflow','tests.coverage.enabled')
    'sda-dev-quality'   = @('tests.coverage.enabled')
    'sda-qa'            = @('paths.issues','scripts.qaSessionInit','scripts.loadQaSecrets','scripts.invokeHttp')
    'sda-qa-task'       = @('designOwnership','paths.issues','paths.specs','scripts.listQaSecrets')
    'sda-design'        = @('designOwnership','paths.specs','docsSkill','paths.workflows','scripts.workflow')
    'sda-workflow'      = @('paths.workflows','scripts.workflow')
    'sda-scribe'        = @('paths.specs','paths.issues','docsSkill')
    'sda-docs-check'    = @('docsSkill','docsCheck.enabled','paths.specs')
}

$keys = $agentKeys[$Agent]
if (-not $keys) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}'
    exit 0
}

$defaults = @{
    'scripts.loadQaSecrets'  = '.sda/scripts/qa/load-qa-secrets.ps1'
    'scripts.listQaSecrets'  = '.sda/scripts/qa/list-qa-secrets.ps1'
    'scripts.qaSessionInit'  = '.sda/scripts/qa/qa-session-init.ps1'
    'scripts.invokeHttp'     = '.sda/scripts/qa/invoke-http.ps1'
    'scripts.workflow'       = '.sda/scripts/workflow/workflow.ps1'
    'designOwnership'        = 'user'
    'standardsSkill'         = 'standards-compliance'
    'docsSkill'              = 'make-repo-ai-friendly'
    'docsCheck.enabled'      = 'true'
    'paths.specs'            = '.sda/specs'
    'paths.issues'           = '.sda/issues'
    'paths.userStories'      = '.sda/stories'
    'paths.workflows'        = '.sda/workflows'
    'tests.coverage.enabled' = 'true'
}

function Get-NestedValue {
    param($obj, [string]$dottedKey)
    $parts = $dottedKey -split '\.'
    $node = $obj
    foreach ($part in $parts) {
        if ($null -eq $node) { return $null }
        $prop = $node.PSObject.Properties[$part]
        if ($null -eq $prop) { return $null }
        $node = $prop.Value
    }
    return $node
}

$repoRoot = (Get-Location).Path
$configPath = '.sda/project-config.json'

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('Project configuration:')
$lines.Add("repoRoot=$repoRoot")

$systemMessage = $null

if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    foreach ($key in $keys) {
        $val = Get-NestedValue $config $key
        if ($null -ne $val) {
            $valStr = if ($val -is [bool]) { $val.ToString().ToLower() } else { "$val" }
            $lines.Add("$key=$valStr")
        } elseif ($defaults.ContainsKey($key)) {
            $lines.Add("$key=$($defaults[$key])")
        }
    }
} else {
    $systemMessage = "Project not initialized. Say 'setup sda tool' to configure project paths."
    foreach ($key in $keys) {
        if ($defaults.ContainsKey($key)) {
            $lines.Add("$key=$($defaults[$key])")
        }
    }
}

# $lines.Add('')
# $lines.Add('Display the above configuration to the user in your first response.')
$additionalContext = $lines -join "`n"

$output = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName     = 'SessionStart'
        additionalContext = $additionalContext
    }
}
if ($systemMessage) {
    $output['systemMessage'] = $systemMessage
}

Write-Output ($output | ConvertTo-Json -Compress -Depth 5)
