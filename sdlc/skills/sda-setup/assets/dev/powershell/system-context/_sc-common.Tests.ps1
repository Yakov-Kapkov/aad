#Requires -Version 5.1
# Ad-hoc tests for _sc-common.ps1 surgical primitives.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_sc-common.ps1"

$fail = 0
function Check($name, $cond) {
    if ($cond) { Write-Host "PASS $name" -ForegroundColor Green }
    else { Write-Host "FAIL $name" -ForegroundColor Red; $script:fail++ }
}

# --- value formatting ---
Check 'quote text field'   ((Format-ScValue 'claim' 'a: b') -eq '"a: b"')
Check 'null value'         ((Format-ScValue 'note' $null) -eq 'null')
Check 'token field'        ((Format-ScValue 'type' 'api') -eq 'api')
Check 'read quoted'        ((Read-ScValue '"a: b"') -eq 'a: b')
Check 'read null'          ($null -eq (Read-ScValue 'null'))
Check 'list format'        ((Format-ScList @('a','b')) -eq '[a, b]')
Check 'list empty'         ((Format-ScList @()) -eq '[]')
Check 'list read'          ((Read-ScList '[a, b]') -join ',' -eq 'a,b')

# --- section on empty file ---
$lines = @('components: []', 'dependencies: []')
$sec = Get-ScSection $lines 'components'
Check 'empty section inline' ($sec.Inline -eq $true)

# --- add first item to inline section ---
$item = New-ScItemLines @(
    @{ Name = 'id'; Value = 'auth-api' },
    @{ Name = 'type'; Value = 'api' },
    @{ Name = 'path'; Value = 'src/auth' },
    @{ Name = 'domain'; Value = 'auth' }
)
$lines = Add-ScItem $lines 'components' $item
Check 'add converts inline'  ($lines -contains 'components:')
Check 'add item id line'     ($lines -contains '  - id: auth-api')
Check 'add item path quoted' ($lines -contains '    path: "src/auth"')

# --- locate item + read field ---
$sec = Get-ScSection $lines 'components'
$it = Get-ScItem $lines $sec.Start $sec.End 'id' 'auth-api'
Check 'locate item'          ($null -ne $it)
Check 'read field type'      ((Get-ScItemField $lines $it.Start $it.End 'type') -eq 'api')
Check 'read field path'      ((Get-ScItemField $lines $it.Start $it.End 'path') -eq 'src/auth')

# --- update field ---
$lines = Set-ScItemField $lines $it.Start $it.End 'type' 'service'
$sec = Get-ScSection $lines 'components'
$it = Get-ScItem $lines $sec.Start $sec.End 'id' 'auth-api'
Check 'update field'         ((Get-ScItemField $lines $it.Start $it.End 'type') -eq 'service')

# --- add second item, then remove first ---
$item2 = New-ScItemLines @(
    @{ Name = 'id'; Value = 'user-api' },
    @{ Name = 'type'; Value = 'api' },
    @{ Name = 'path'; Value = 'src/user' },
    @{ Name = 'domain'; Value = 'user' }
)
$lines = Add-ScItem $lines 'components' $item2
$sec = Get-ScSection $lines 'components'
$it = Get-ScItem $lines $sec.Start $sec.End 'id' 'auth-api'
$lines = Remove-ScItem $lines 'components' $it.Start $it.End
$sec = Get-ScSection $lines 'components'
Check 'removed first'        ($null -eq (Get-ScItem $lines $sec.Start $sec.End 'id' 'auth-api'))
Check 'kept second'          ($null -ne (Get-ScItem $lines $sec.Start $sec.End 'id' 'user-api'))

# --- remove last item collapses to inline ---
$it = Get-ScItem $lines $sec.Start $sec.End 'id' 'user-api'
$lines = Remove-ScItem $lines 'components' $it.Start $it.End
Check 'collapse to inline'   ($lines -contains 'components: []')

if ($fail -eq 0) { Write-Host "`nALL PASS" -ForegroundColor Green; exit 0 }
else { Write-Host "`n$fail FAILED" -ForegroundColor Red; exit 1 }
