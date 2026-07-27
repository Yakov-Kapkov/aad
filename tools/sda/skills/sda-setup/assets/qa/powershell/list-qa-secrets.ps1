# list-qa-secrets.ps1 — Outputs credential key names and descriptions from qa.secrets.env.
# Reads only KEY names and comments — never outputs values.
# Output format: table with VAR NAME and DESCRIPTION columns.
# Usage: .sda/scripts/qa/list-qa-secrets.ps1 [-SecretsRoot <path>]
param(
    [string]$SecretsRoot = '.sda/secrets'
)
$secretsFile = Join-Path $SecretsRoot 'qa.secrets.env'
if (-not (Test-Path $secretsFile)) {
    Write-Information "$secretsFile not found." -InformationAction Continue
    exit 0
}
$rows = [System.Collections.Generic.List[PSCustomObject]]::new()
$pendingComment = ''
foreach ($line in Get-Content $secretsFile) {
    if ($line -match '^#\s*(.+)') {
        $pendingComment = $Matches[1]
    } elseif ($line -match '^([A-Z_][A-Z0-9_]*)=') {
        $rows.Add([PSCustomObject]@{ 'VAR NAME' = $Matches[1]; 'DESCRIPTION' = $pendingComment })
        $pendingComment = ''
    } else {
        $pendingComment = ''
    }
}
$rows | Format-Table -AutoSize
