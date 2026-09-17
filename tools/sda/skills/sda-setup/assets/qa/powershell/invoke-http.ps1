# invoke-http.ps1 — Execute an HTTP request; output STATUS: <code> and BODY: <body>.
# Usage: .sda/scripts/qa/invoke-http.ps1 -Method GET -Uri "http://..." [-Headers @{...}] [-Body "..."] [-StatusOnly]
param(
    [string]$Method = 'GET',
    [Parameter(Mandatory)][string]$Uri,
    [hashtable]$Headers = @{},
    [string]$Body,
    [string]$ContentType = 'application/json; charset=utf-8',
    [switch]$StatusOnly
)

$iwrParams = @{
    Uri             = $Uri
    Method          = $Method
    Headers         = $Headers
    UseBasicParsing = $true
    ErrorAction     = 'Stop'
}
if ($PSBoundParameters.ContainsKey('Body')) {
    $iwrParams.Body        = $Body
    $iwrParams.ContentType = $ContentType
}

try {
    $resp = Invoke-WebRequest @iwrParams
    Write-Host "STATUS: $($resp.StatusCode)"
    if (-not $StatusOnly) { Write-Host "BODY: $($resp.Content)" }
} catch {
    $statusCode = 0
    $bodyText   = $null

    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode

        if (-not $StatusOnly) {
            # PowerShell 7+: ErrorDetails.Message contains the decoded response body
            if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                $bodyText = $_.ErrorDetails.Message
            } else {
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
                $bodyText = $reader.ReadToEnd()
                $reader.Close()
            }
        }
    } else {
        if (-not $StatusOnly) { $bodyText = $_.Exception.Message }
    }

    Write-Host "STATUS: $statusCode"
    if (-not $StatusOnly) { Write-Host "BODY: $bodyText" }
}
