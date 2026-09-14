param(
    [Parameter(Mandatory=$true)][string]$Agent
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Per-agent key manifests — controls what each agent receives
$agentKeys = @{
    'sda-ba'            = @('paths.baStandards','paths.baFeatures')
    'sda-dev'       = @('scripts.taskState','scripts.unitFileSize','scripts.readProjectTools','devTaskUnitSizeLimit','standardsSkill','paths.design','paths.specs','paths.devSystemContext','tests.coverage.enabled')
    'sda-dev-quality'   = @('scripts.readProjectTools','tests.coverage.enabled')
    'sda-dev-task'          = @('scripts.taskState','scripts.unitFileSize','devTaskUnitSizeLimit','designOwnership','standardsSkill','paths.design','paths.specs','paths.baFeatures','paths.pendingChanges','paths.devSystemContext','scripts.scBlastRadius')
    'sda-dev-task-verifier' = @('scripts.unitFileSize','devTaskUnitSizeLimit','paths.specs','paths.design')
    'sda-qa'            = @('scripts.qaSessionInit','scripts.loadQaSecrets','scripts.invokeHttp','scripts.readProjectTools')
    'sda-qa-task'       = @('designOwnership','paths.specs','scripts.listQaSecrets','scripts.readProjectTools','paths.baFeatures','paths.baStandards','paths.devSystemContext')
    'sda-dev-context-writer' = @('paths.devSystemContext','scripts.scComponents','scripts.scEdges','scripts.scBehaviors','scripts.scDecisions','scripts.scDomains','scripts.scBlastRadius')
    'sda-qa-context-writer'  = @('paths.qaTestCases')
    'sda-feature'       = @('designOwnership','paths.design','paths.specs','paths.baFeatures','paths.pendingChanges','paths.devSystemContext')
    'sda-system'        = @('designOwnership','paths.design','paths.specs','paths.baFeatures','paths.pendingChanges','paths.devSystemContext')
    'sda-scribe'        = @('paths.specs')
    'sda-workflow'      = @('paths.workflows','paths.baStandards','scripts.workflowState','scripts.workflowNextStep','scripts.devQaNextStep')
}

$keys = $agentKeys[$Agent]
if (-not $keys) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}'
    exit 0
}

$defaults = @{
    'scripts.taskState'      = '.sda/scripts/dev/task-state.ps1'
    'scripts.unitFileSize'   = '.sda/scripts/dev/unit-file-size.ps1'
    'scripts.readProjectTools' = '.sda/scripts/read-project-tools.ps1'
    'scripts.loadQaSecrets'  = '.sda/scripts/qa/load-qa-secrets.ps1'
    'scripts.listQaSecrets'  = '.sda/scripts/qa/list-qa-secrets.ps1'
    'scripts.qaSessionInit'  = '.sda/scripts/qa/qa-session-init.ps1'
    'scripts.invokeHttp'     = '.sda/scripts/qa/invoke-http.ps1'
    'scripts.scComponents'   = '.sda/scripts/system-context/components.ps1'
    'scripts.scEdges'        = '.sda/scripts/system-context/edges.ps1'
    'scripts.scBehaviors'    = '.sda/scripts/system-context/behaviors.ps1'
    'scripts.scDecisions'    = '.sda/scripts/system-context/decisions.ps1'
    'scripts.scDomains'      = '.sda/scripts/system-context/domains.ps1'
    'scripts.scBlastRadius'  = '.sda/scripts/system-context/blast-radius.ps1'
    'scripts.workflowState'  = '.sda/scripts/workflow/workflow-state.ps1'
    'scripts.workflowNextStep' = '.sda/scripts/workflow/workflow-next-step.ps1'
    'scripts.devQaNextStep'  = '.sda/scripts/workflow/dev-qa-next-step.ps1'
    'devTaskUnitSizeLimit'   = '1000'
    'designOwnership'        = 'user'
    'standardsSkill'         = 'standards-compliance'
    'paths.design'           = 'docs/design'
    'paths.specs'            = '.sda/specs'
    'paths.pendingChanges'   = '.sda/pending'
    'paths.baStandards'      = 'docs/standards'
    'paths.baFeatures'       = 'docs/features'
    'paths.devSystemContext' = 'docs/system-context'
    'paths.qaTestCases'      = 'docs/test-cases'
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
