#Requires -Version 5.1
<#
.SYNOPSIS
    Shared surgical-edit helpers for the SDA system-context CLI scripts.

.DESCRIPTION
    The system context is a set of canonical YAML files (index.yaml,
    dependency-map.yaml, <domain>.yaml, cross-domain.yaml). These helpers do
    line/block-level edits on that fixed, canonical shape - no general YAML
    engine, no external dependencies. Every write goes through these primitives
    so the emitted format stays identical to the bash side.

    Canonical shape:
      <key>: <scalar>                 # top-level scalar
      <key>:                          # top-level list
        - <field>: <value>            # first field of an item
          <field>: <value>            # further fields (4-space indent)
      <key>: []                       # empty list

    On any failure a script prints  error=<message>  and exits 1. The calling
    agent treats that as a hard stop.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- error / output -------------------------------------------------------

function Write-ScError {
    param([Parameter(Mandatory)][string]$Message)
    Write-Output "error=$Message"
    exit 1
}

# --- value formatting -----------------------------------------------------

# Fields whose values are free text and must be quoted.
$script:ScTextFields = @('claim', 'summary', 'rationale', 'note', 'path')

function Format-ScValue {
    param([string]$Field, $Value)
    if ($null -eq $Value -or $Value -eq '' -or $Value -eq 'null') { return 'null' }
    if ($script:ScTextFields -contains $Field) {
        $escaped = ([string]$Value) -replace '\\', '\\' -replace '"', '\"'
        return '"' + $escaped + '"'
    }
    return [string]$Value
}

# Parse a stored scalar back to its raw value ("null" -> $null, strip quotes).
function Read-ScValue {
    param([string]$Raw)
    $t = $Raw.Trim()
    if ($t -eq 'null' -or $t -eq '') { return $null }
    if ($t.StartsWith('"') -and $t.EndsWith('"') -and $t.Length -ge 2) {
        $inner = $t.Substring(1, $t.Length - 2)
        return ($inner -replace '\\"', '"' -replace '\\\\', '\')
    }
    return $t
}

# Format an inline list value: [a, b] or [].
function Format-ScList {
    param([string[]]$Items)
    if ($null -eq $Items -or $Items.Count -eq 0) { return '[]' }
    return '[' + ($Items -join ', ') + ']'
}

# Parse an inline list value "[a, b]" -> @('a','b'); "[]" -> @().
function Read-ScList {
    param([string]$Raw)
    $t = $Raw.Trim()
    if (-not ($t.StartsWith('[') -and $t.EndsWith(']'))) { return @() }
    $inner = $t.Substring(1, $t.Length - 2).Trim()
    if ($inner -eq '') { return @() }
    return @($inner -split '\s*,\s*' | Where-Object { $_ -ne '' })
}

# --- file IO --------------------------------------------------------------

function Read-ScLines {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { return @() }
    return @(Get-Content -LiteralPath $Path)
}

function Write-ScLines {
    param([Parameter(Mandatory)][string]$Path, [string[]]$Lines)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $text = ($Lines -join "`n") + "`n"
    [System.IO.File]::WriteAllText($Path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

# --- section / item location ---------------------------------------------

# Return @{ Start; End; Inline } for a top-level list section named $Key.
#   Start/End = index range [Start, End) of the item lines (after "<Key>:").
#   Inline    = $true when the section is "<Key>: []" (no item lines yet).
# Returns $null when the section key is absent.
function Get-ScSection {
    param([string[]]$Lines, [string]$Key)
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "^$([regex]::Escape($Key)):\s*(\S.*)?$") {
            $rest = $Matches[1]
            if ($rest -eq '[]') { return @{ Start = $i + 1; End = $i + 1; Inline = $true; KeyLine = $i } }
            if ($null -ne $rest -and $rest.Trim() -ne '') {
                # scalar top-level key, not a list section
                return $null
            }
            # list section: items run until the next column-0 line
            $j = $i + 1
            while ($j -lt $Lines.Count -and ($Lines[$j] -match '^\s' -or $Lines[$j] -eq '')) { $j++ }
            return @{ Start = $i + 1; End = $j; Inline = $false; KeyLine = $i }
        }
    }
    return $null
}

# Within [SectionStart, SectionEnd) find the item whose first field
# "<IdField>: <IdValue>" matches. Returns @{ Start; End } or $null.
function Get-ScItem {
    param([string[]]$Lines, [int]$SectionStart, [int]$SectionEnd, [string]$IdField, [string]$IdValue)
    $itemStart = -1
    for ($i = $SectionStart; $i -lt $SectionEnd; $i++) {
        if ($Lines[$i] -match '^\s{2}-\s') {
            if ($itemStart -ge 0) {
                $m = Test-ScItemId $Lines $itemStart $i $IdField $IdValue
                if ($m) { return @{ Start = $itemStart; End = $i } }
            }
            $itemStart = $i
        }
    }
    if ($itemStart -ge 0) {
        $m = Test-ScItemId $Lines $itemStart $SectionEnd $IdField $IdValue
        if ($m) { return @{ Start = $itemStart; End = $SectionEnd } }
    }
    return $null
}

function Test-ScItemId {
    param([string[]]$Lines, [int]$Start, [int]$End, [string]$IdField, [string]$IdValue)
    $val = Get-ScItemField $Lines $Start $End $IdField
    return ($val -eq $IdValue)
}

# Read a field's raw stored token from an item block (or $null if absent).
function Get-ScItemFieldRaw {
    param([string[]]$Lines, [int]$Start, [int]$End, [string]$Field)
    for ($i = $Start; $i -lt $End; $i++) {
        if ($Lines[$i] -match "^\s{2,4}-?\s*$([regex]::Escape($Field)):\s*(.*)$") {
            return $Matches[1]
        }
    }
    return $null
}

# Read a field's decoded scalar value from an item block.
function Get-ScItemField {
    param([string[]]$Lines, [int]$Start, [int]$End, [string]$Field)
    $raw = Get-ScItemFieldRaw $Lines $Start $End $Field
    if ($null -eq $raw) { return $null }
    return Read-ScValue $raw
}

# --- item block construction ---------------------------------------------

# Build the canonical lines for one list item from an ordered field spec.
# $Fields is an array of @{ Name; Value; List } hashtables (List=$true for
# inline-list fields whose Value is a string[]). The first entry is the id line.
function New-ScItemLines {
    param([object[]]$Fields)
    $out = New-Object System.Collections.Generic.List[string]
    for ($k = 0; $k -lt $Fields.Count; $k++) {
        $f = $Fields[$k]
        $prefix = if ($k -eq 0) { '  - ' } else { '    ' }
        if ($f.ContainsKey('List') -and $f.List) {
            $out.Add("$prefix$($f.Name): $(Format-ScList $f.Value)")
        } else {
            $out.Add("$prefix$($f.Name): $(Format-ScValue $f.Name $f.Value)")
        }
    }
    return $out.ToArray()
}

# --- mutations ------------------------------------------------------------

# Append a new item (given as canonical lines) to a list section, creating the
# section from "<Key>: []" when needed. Returns the new line array.
function Add-ScItem {
    param([string[]]$Lines, [string]$Key, [string[]]$ItemLines)
    $sec = Get-ScSection $Lines $Key
    if ($null -eq $sec) { Write-ScError "section '$Key' not found" }
    $list = New-Object System.Collections.Generic.List[string]
    $list.AddRange($Lines)
    if ($sec.Inline) {
        # replace "<Key>: []" with "<Key>:" then the item
        $list[$sec.KeyLine] = "$Key`:"
        $list.InsertRange($sec.KeyLine + 1, [string[]]$ItemLines)
    } else {
        $list.InsertRange($sec.End, [string[]]$ItemLines)
    }
    return $list.ToArray()
}

# Remove an item block [Start, End). If that empties its section, collapse the
# "<Key>:" header back to "<Key>: []". Returns the new line array.
function Remove-ScItem {
    param([string[]]$Lines, [string]$Key, [int]$Start, [int]$End)
    $list = New-Object System.Collections.Generic.List[string]
    $list.AddRange($Lines)
    $list.RemoveRange($Start, $End - $Start)
    $sec = Get-ScSection $list.ToArray() $Key
    if ($null -ne $sec -and -not $sec.Inline -and $sec.Start -eq $sec.End) {
        $list[$sec.KeyLine] = "$Key`: []"
    }
    return $list.ToArray()
}

# Set (replace or insert) a scalar field on an item block. Returns new lines.
function Set-ScItemField {
    param([string[]]$Lines, [int]$Start, [int]$End, [string]$Field, $Value)
    $formatted = Format-ScValue $Field $Value
    $list = New-Object System.Collections.Generic.List[string]
    $list.AddRange($Lines)
    for ($i = $Start; $i -lt $End; $i++) {
        if ($Lines[$i] -match "^(\s{2,4}-?\s*)$([regex]::Escape($Field)):\s*(.*)$") {
            $list[$i] = "$($Matches[1])$Field`: $formatted"
            return $list.ToArray()
        }
    }
    # field absent - insert as a continuation line at end of block
    $list.Insert($End, "    $Field`: $formatted")
    return $list.ToArray()
}

# Set (replace or insert) an inline-list field on an item block.
function Set-ScItemFieldList {
    param([string[]]$Lines, [int]$Start, [int]$End, [string]$Field, [string[]]$Values)
    $formatted = Format-ScList $Values
    $list = New-Object System.Collections.Generic.List[string]
    $list.AddRange($Lines)
    for ($i = $Start; $i -lt $End; $i++) {
        if ($Lines[$i] -match "^(\s{2,4}-?\s*)$([regex]::Escape($Field)):\s*(.*)$") {
            $list[$i] = "$($Matches[1])$Field`: $formatted"
            return $list.ToArray()
        }
    }
    $list.Insert($End, "    $Field`: $formatted")
    return $list.ToArray()
}

# --- init ------------------------------------------------------------------

# Create a list-only file (e.g. dependency-map.yaml) with empty sections.
function Initialize-ScListFile {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string[]]$Keys)
    if (Test-Path $Path) { return }
    $lines = @($Keys | ForEach-Object { "$_`: []" })
    Write-ScLines $Path $lines
}

function Get-ScToday { return (Get-Date).ToString('yyyy-MM-dd') }

# Set (or insert) a top-level scalar "<Key>: <Value>". Returns new lines.
function Set-ScScalar {
    param([string[]]$Lines, [string]$Key, [string]$Value)
    $list = New-Object System.Collections.Generic.List[string]
    $list.AddRange($Lines)
    for ($i = 0; $i -lt $list.Count; $i++) {
        if ($list[$i] -match "^$([regex]::Escape($Key)):\s") {
            $list[$i] = "$Key`: $Value"
            return $list.ToArray()
        }
    }
    $list.Insert(0, "$Key`: $Value")
    return $list.ToArray()
}
