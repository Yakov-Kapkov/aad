# qa-session-init.ps1 — Initialise a QA terminal session.
# Must be dot-sourced so env vars propagate to the caller.
# Sets console output encoding to UTF-8, then loads QA credentials.
# Outputs a combined summary: script | result | notes, followed by a var_name | is_empty credentials table.
# Usage: . ".sda/scripts/qa/qa-session-init.ps1" [-SecretsRoot <path>]
param(
    [string]$SecretsRoot = '.sda/secrets'
)

$summary = [System.Collections.Generic.List[PSCustomObject]]::new()

# 1. Set UTF-8 output encoding
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $summary.Add([PSCustomObject]@{ script = 'set-encoding'; result = 'OK'; notes = 'UTF-8' })
} catch {
    $summary.Add([PSCustomObject]@{ script = 'set-encoding'; result = 'ERROR'; notes = $_.Message })
}

# 2. Load QA credentials from secrets file
$secretsFile = Join-Path $SecretsRoot 'qa.secrets.env'
$credRows    = [System.Collections.Generic.List[PSCustomObject]]::new()
if (Test-Path $secretsFile) {
    Get-Content $secretsFile |
        Where-Object { $_ -match '^[A-Z_][A-Z0-9_]*=' } |
        ForEach-Object {
            $k, $v = $_ -split '=', 2
            Set-Item "Env:$k" $v
            $credRows.Add([PSCustomObject]@{
                var_name = $k
                is_empty = [string]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable($k))
            })
        }
    $summary.Add([PSCustomObject]@{ script = 'load-qa-secrets'; result = 'OK'; notes = "$($credRows.Count) variable(s) loaded" })
} else {
    $summary.Add([PSCustomObject]@{ script = 'load-qa-secrets'; result = 'WARN'; notes = 'Secrets file not found — credentials must already be in environment' })
}

# Output combined summary
Write-Host ''
Write-Host '=== QA Session Init ==='
$summary | Format-Table -AutoSize
if ($credRows.Count -gt 0) {
    Write-Host '--- Credentials ---'
    $credRows | Format-Table -AutoSize
}
