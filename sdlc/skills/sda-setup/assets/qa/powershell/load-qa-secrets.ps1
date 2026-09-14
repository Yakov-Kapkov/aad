# load-qa-secrets.ps1 - Loads qa.secrets.env into the current PowerShell session.
# Must be dot-sourced (not executed) for env vars to propagate to the caller.
# Outputs a table: var_name | is_empty — showing every variable loaded.
# Usage: . ".sda/scripts/qa/load-qa-secrets.ps1" [-SecretsRoot <path>]
param(
    [string]$SecretsRoot = '.sda/secrets'
)
$secretsFile = Join-Path $SecretsRoot 'qa.secrets.env'
$loaded = [System.Collections.Generic.List[string]]::new()
if (Test-Path $secretsFile) {
    Get-Content $secretsFile |
        Where-Object { $_ -match '^[A-Z_][A-Z0-9_]*=' } |
        ForEach-Object {
            $k, $v = $_ -split '=', 2
            Set-Item "Env:$k" $v
            $loaded.Add($k)
        }
} else {
    Write-Warning "Secrets file not found - credentials must already be in environment."
}

$loaded | ForEach-Object {
    [PSCustomObject]@{
        var_name = $_
        is_empty = [string]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable($_))
    }
} | Format-Table -AutoSize
