#Requires -Version 5.1
# End-to-end integration test for the system-context CLI scripts.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dir = Join-Path ([System.IO.Path]::GetTempPath()) ("sc-test-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
$sc = Join-Path $dir 'sysctx'
New-Item -ItemType Directory -Force -Path $sc | Out-Null
$here = $PSScriptRoot

$fail = 0
function Check($name, $cond) {
    if ($cond) { Write-Host "PASS $name" -ForegroundColor Green }
    else { Write-Host "FAIL $name" -ForegroundColor Red; $script:fail++ }
}
function Run($script, $scriptArgs) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here $script) @scriptArgs 2>&1
}
function ReadF($name) { Get-Content -Raw (Join-Path $sc $name) }

try {
    # domains
    $o = Run 'domains.ps1' @('add', '-Name', 'auth', '-Project', 'demo', '-Root', $sc)
    Check 'domain add ok' ($o -match 'ok: added domain auth')
    Check 'index has auth' ((ReadF 'index.yaml') -match 'name: auth')
    Check 'domain file created' (Test-Path (Join-Path $sc 'auth.yaml'))
    $o = Run 'domains.ps1' @('add', '-Name', 'user', '-Root', $sc)
    Check 'second domain' ((ReadF 'index.yaml') -match 'name: user')

    # components
    $o = Run 'components.ps1' @('add', '-Id', 'auth-api', '-Type', 'api', '-Path', 'src/auth/api.ts', '-Domain', 'auth', '-Root', $sc)
    Check 'component add' ($o -match 'ok: added component auth-api')
    $o = Run 'components.ps1' @('add', '-Id', 'token-svc', '-Type', 'service', '-Path', 'src/auth/token.ts', '-Domain', 'auth', '-Root', $sc)
    $o = Run 'components.ps1' @('add', '-Id', 'user-api', '-Type', 'api', '-Path', 'src/user/api.ts', '-Domain', 'user', '-Root', $sc)
    Check 'three components' (@((ReadF 'dependency-map.yaml') -split "`n" | Where-Object { $_ -match '^\s+- id:' }).Count -eq 3)
    # duplicate rejected
    $o = Run 'components.ps1' @('add', '-Id', 'auth-api', '-Type', 'api', '-Path', 'x', '-Domain', 'auth', '-Root', $sc)
    Check 'dup component rejected' ($o -match 'error=')

    # component update
    $o = Run 'components.ps1' @('update', '-Id', 'auth-api', '-Path', 'src/auth/v2.ts', '-Root', $sc)
    Check 'component update' ((ReadF 'dependency-map.yaml') -match 'path: "src/auth/v2.ts"')

    # edges
    $o = Run 'edges.ps1' @('add', '-From', 'auth-api', '-To', 'token-svc', '-Root', $sc)
    Check 'edge add' ($o -match 'ok: added edge auth-api -> token-svc')
    $o = Run 'edges.ps1' @('add', '-From', 'user-api', '-To', 'auth-api', '-Root', $sc)
    Check 'edge add 2' ((ReadF 'dependency-map.yaml') -match 'from: user-api')
    # dedup
    $o = Run 'edges.ps1' @('add', '-From', 'auth-api', '-To', 'token-svc', '-Root', $sc)
    Check 'edge dedup' ($o -match 'already present')
    # edge to missing node rejected
    $o = Run 'edges.ps1' @('add', '-From', 'auth-api', '-To', 'ghost', '-Root', $sc)
    Check 'edge missing node' ($o -match 'error=')

    # decisions
    $o = Run 'decisions.ps1' @('add', '-Domain', 'auth', '-Id', 'D001', '-Summary', 'JWT: stateless', '-Rationale', 'scale', '-Root', $sc)
    Check 'decision add' ($o -match 'ok: added decision D001')
    Check 'decision text quoted' ((ReadF 'auth.yaml') -match 'summary: "JWT: stateless"')
    $o = Run 'decisions.ps1' @('update', '-Domain', 'auth', '-Id', 'D001', '-Status', 'superseded', '-SupersededBy', 'D002', '-Root', $sc)
    Check 'decision supersede' ((ReadF 'auth.yaml') -match 'superseded_by: D002')

    # behaviors (domain)
    $o = Run 'behaviors.ps1' @('add', '-Domain', 'auth', '-Id', 'B001', '-Claim', 'rejects expired token', '-Via', 'auth-api', '-Status', 'verified', '-VerifiedBy', 'TC-1', '-Root', $sc)
    Check 'behaviour add' ($o -match 'ok: added behaviour B001')
    Check 'behaviour verified_by' ((ReadF 'auth.yaml') -match 'verified_by: TC-1')
    $o = Run 'behaviors.ps1' @('update', '-Domain', 'auth', '-Id', 'B001', '-Status', 'pending-reverification', '-Note', 'touched by change', '-Root', $sc)
    Check 'behaviour update' ((ReadF 'auth.yaml') -match 'status: pending-reverification')
    Check 'behaviour note' ((ReadF 'auth.yaml') -match 'note: "touched by change"')

    # behaviors (cross-domain)
    $o = Run 'behaviors.ps1' @('add', '-Domain', 'cross-domain', '-Id', 'XB001', '-Claim', 'login issues user session', '-Via', 'auth-api,user-api', '-Domains', 'auth,user', '-Status', 'verified', '-Root', $sc)
    Check 'cross behaviour add' (Test-Path (Join-Path $sc 'cross-domain.yaml'))
    Check 'cross via list' ((ReadF 'cross-domain.yaml') -match 'via: \[auth-api, user-api\]')

    # blast-radius: change token-svc -> auth-api depends on it -> user-api depends on auth-api
    $o = Run 'blast-radius.ps1' @('-Components', 'token-svc', '-Root', $sc)
    $txt = ($o -join "`n")
    Check 'blast at-risk auth-api' ($txt -match 'at-risk-components=\[.*auth-api.*\]')
    Check 'blast at-risk user-api' ($txt -match 'user-api')
    Check 'blast finds B001' ($txt -match 'behaviour=B001')
    Check 'blast pending count' ($txt -match 'pending-count=1')

    # cascade: delete auth-api -> removes node, edges, and B001 (via auth-api) + XB001 (via list)
    $o = Run 'components.ps1' @('delete', '-Id', 'auth-api', '-Root', $sc)
    $txt = ($o -join "`n")
    Check 'delete reports component' ($txt -match 'removed: component auth-api')
    Check 'delete cascades B001' ($txt -match 'removed: behaviour B001')
    Check 'delete cascades XB001' ($txt -match 'removed: behaviour XB001')
    Check 'auth-api gone from map' (-not ((ReadF 'dependency-map.yaml') -match 'id: auth-api'))
    Check 'B001 gone' (-not ((ReadF 'auth.yaml') -match 'id: B001'))
    Check 'edge user-api->auth-api stripped' (-not ((ReadF 'dependency-map.yaml') -match 'to: \[auth-api\]'))

    # domain delete cascade
    $o = Run 'domains.ps1' @('delete', '-Name', 'user', '-Root', $sc)
    Check 'domain delete' (-not (Test-Path (Join-Path $sc 'user.yaml')))
    Check 'domain unregistered' (-not ((ReadF 'index.yaml') -match 'name: user'))

    # edge delete
    $o = Run 'edges.ps1' @('delete', '-From', 'auth-api', '-To', 'token-svc', '-Root', $sc)
    # auth-api already deleted above; this from-item was removed -> expect error
    Check 'edge delete missing from' ($o -match 'error=')
}
finally {
    Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
}

if ($fail -eq 0) { Write-Host "`nALL PASS" -ForegroundColor Green; exit 0 }
else { Write-Host "`n$fail FAILED" -ForegroundColor Red; exit 1 }
