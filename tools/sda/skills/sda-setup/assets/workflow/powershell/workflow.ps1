#Requires -Version 5.1
<#
.SYNOPSIS
    Creates and maintains a workflow container and its workflow.json state.

.DESCRIPTION
    A workflow is a numbered folder holding one requirement's planning
    artifacts plus the state that tracks their progress. This script is the
    only writer of workflow.json; folders and state are never hand-edited.

    Commands:
      init      Create a workflow folder, its tasks/ folder, and workflow.json,
                at story by default or the -At stage.
      list      One line per workflow; marks the deepest open escalation.
      current   Print the stage, any open escalation, and artifact gaps.
      read      Print workflow.json, or one field with -Field.
      advance   Move the stage forward exactly one stage.
      escalate  Move the stage back, one or more stages, recording why and the evidence.
      resolve   Close the deepest open escalation, then move forward one stage.

    Output contract:
      mutation  ok: workflow '<folder>' <verb> <subject> -> '<stage>'
      status    header line, key=value lines, and a derived stages table (current)
      raw       pretty-printed JSON, or the bare field value (read)
      failure   error=<X cannot do Y because Z>, exit code 1

    The stage order is story -> design -> tasks -> ready. A container starts at
    story by default; -At design or -At tasks skips the stages before it, which
    then produce no artifact. Every stage from the start onward produces one
    artifact, and advance refuses to leave a stage whose artifact is absent.
    While any escalation is open, advance is refused and only resolve clears it.

.PARAMETER Command
    One of: init, list, current, read, advance, escalate, resolve.

.PARAMETER Slug
    Workflow folder name, numeric id, or slug.

.PARAMETER At
    (init only) The stage to create the container at: story, design, or tasks.
    Defaults to story. Stages before it are skipped.

.PARAMETER Field
    (read only) One of: id, slug, created, stage, start, notes.

.PARAMETER To
    (escalate only) The stage to move back to. Defaults to one stage back.

.PARAMETER Reason
    (escalate only) Why the stage cannot finish: the one-line ask. It may name the
    brief but never reproduces it.

.PARAMETER Brief
    (escalate only) Path of the escalation's evidence file, relative to the repo
    root. It must exist and sit in the workflow's escalations/ folder; the raise is
    refused otherwise, so an escalation never lacks evidence. Its path is recorded
    and the file itself is never read.

.PARAMETER Id
    (resolve only) The id of the open escalation to close, e.g. E1.

.PARAMETER Report
    (resolve only) What changed, where, and what the downstream stage must redo.

.PARAMETER Root
    Folder holding the workflow containers. Defaults to .sda/workflows.

.EXAMPLE
    workflow.ps1 init -Slug const-refactoring

.EXAMPLE
    workflow.ps1 init -Slug const-refactoring -At design

.EXAMPLE
    workflow.ps1 escalate -Slug 001 -Reason "outbox replaced by direct write" `
        -Brief ".sda/workflows/001. const-refactoring/escalations/001. 2026-09-15_14-20-tasks-to-design.md"

.EXAMPLE
    workflow.ps1 resolve -Slug 001 -Id E1 -Report "direct write chosen; design renewed"
#>

param(
    # Not Mandatory/ValidateSet: a binding failure prints a raw PowerShell error
    # and, with no command at all, prompts instead of failing.
    [Parameter(Position = 0)]
    [string] $Command,

    [string] $Slug,

    [string] $At,

    [string] $Field,

    [string] $To,

    [string] $Reason,

    [string] $Brief,

    [string] $Id,

    [string] $Report,

    [string] $Root
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$StageNames = @('story', 'design', 'tasks', 'ready')
$StartableStages = @('story', 'design', 'tasks')
$StageArtifacts = @{
    'story'  = 'user-story.md'
    'design' = 'design.md'
    'tasks'  = 'tasks'
}

$WorkflowsRoot = if ($Root) { $Root } else { '.sda/workflows' }
# Anchor relative paths to PowerShell's $PWD so .NET methods resolve correctly
if (-not [System.IO.Path]::IsPathRooted($WorkflowsRoot)) {
    $WorkflowsRoot = Join-Path $PWD $WorkflowsRoot
}

function Fail([string]$message) {
    Write-Output "error=$message"
    exit 1
}

function Get-StageIndex([string]$name) {
    return [array]::IndexOf($StageNames, $name)
}

function Format-Json {
    param($obj, [int]$depth = 0)
    $pad   = '  ' * $depth
    $inner = '  ' * ($depth + 1)
    if ($null -eq $obj)                                          { return 'null' }
    if ($obj -is [bool])                                         { return $obj.ToString().ToLower() }
    if ($obj -is [int] -or $obj -is [long] -or
        $obj -is [double] -or $obj -is [decimal])                { return "$obj" }
    if ($obj -is [string])                                       { return '"' + ($obj -replace '\\','\\' -replace '"','\"') + '"' }
    if ($obj -is [array] -or $obj -is [System.Collections.IList]) {
        if ($obj.Count -eq 0) { return '[]' }
        $items = $obj | ForEach-Object { "$inner$(Format-Json $_ ($depth + 1))" }
        return "[`n$($items -join ",`n")`n$pad]"
    }
    if ($obj -is [System.Collections.IDictionary]) {
        $props = @($obj.GetEnumerator())
        if ($props.Count -eq 0) { return '{}' }
        $entries = $props | ForEach-Object {
            $k = '"' + $_.Key + '"'
            $v = Format-Json $_.Value ($depth + 1)
            "$inner$k`: $v"
        }
        return "{`n$($entries -join ",`n")`n$pad}"
    }
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

function Get-WorkflowFolders {
    if (-not (Test-Path $WorkflowsRoot)) { return @() }
    return @(Get-ChildItem -Path $WorkflowsRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d{3}\. .+$' } |
        Sort-Object { [int]($_.Name.Substring(0, 3)) })
}

# The leading comma stops PowerShell unrolling the array on return: an empty
# array would arrive as $null and a one-element array as its element. Call
# sites must NOT wrap the result in @() -- that re-wraps it as a nested array.
function Get-NoteList($state) {
    if ($null -eq $state.notes) { return ,([object[]]@()) }
    return ,([object[]]@($state.notes))
}

function Resolve-WorkflowFolder([string]$value) {
    # 1. Exact folder name
    $direct = Join-Path $WorkflowsRoot $value
    if (Test-Path (Join-Path $direct 'workflow.json')) { return (Resolve-Path $direct).Path }

    # 2. Numeric id
    if ($value -match '^\d{1,3}$') {
        $id = '{0:d3}' -f [int]$value
        $byId = @(Get-WorkflowFolders | Where-Object { $_.Name.StartsWith("$id. ") })
        if ($byId.Count -eq 1) { return $byId[0].FullName }
    }

    # 3. Slug (case-sensitive, matching the bash twin)
    $bySlug = @(Get-WorkflowFolders | Where-Object { $_.Name.Substring(5) -ceq $value })
    if ($bySlug.Count -eq 1) { return $bySlug[0].FullName }
    if ($bySlug.Count -gt 1) {
        Fail "workflow '$value' cannot be resolved because several workflows use the slug '$value'"
    }

    Fail "workflow '$value' cannot be resolved because no folder in $WorkflowsRoot matches that name, id, or slug"
}

# A container is consistent only when its workflow.json exists, parses, carries
# the four required fields, and holds a known stage. Every command that reads
# state goes through here, so a corrupted container stops the command instead of
# yielding a half-answer or an empty field.
function Read-State([string]$folder) {
    $file = Join-Path $folder 'workflow.json'
    if (-not (Test-Path $file)) {
        Fail "workflow cannot be read because $folder has no workflow.json"
    }

    $state = $null
    try {
        $state = Get-Content $file -Raw | ConvertFrom-Json
    } catch {
        Fail "workflow cannot be read because $file is not valid JSON"
    }

    foreach ($field in @('id', 'slug', 'created', 'stage')) {
        $prop = $state.PSObject.Properties[$field]
        if ($null -eq $prop -or [string]::IsNullOrEmpty([string]$prop.Value)) {
            Fail "workflow cannot be read because $file is missing '$field'"
        }
    }

    if ((Get-StageIndex $state.stage) -lt 0) {
        Fail "workflow cannot be read because $file has an unknown stage '$($state.stage)'"
    }

    $startProp = $state.PSObject.Properties['start']
    if ($null -ne $startProp -and -not [string]::IsNullOrEmpty([string]$startProp.Value)) {
        if ([array]::IndexOf($StartableStages, [string]$startProp.Value) -lt 0) {
            Fail "workflow cannot be read because $file has an unknown start stage '$($startProp.Value)'"
        }
    }
    return $state
}

function Write-State($folder, $state) {
    $file = Join-Path $folder 'workflow.json'
    # No BOM: the state file is data, and the bash twin's jq-written file has
    # none. jq writes a trailing newline, so match that too.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($file, (Format-Json $state) + "`n", $utf8NoBom)
}

# The notes log is append-only and never edited, so open-ness is derived: an
# escalation stays open until a resolution with the same id follows it. Open
# escalations form a LIFO stack -- the last one raised is the deepest.
function Get-OpenEscalations($state) {
    $open = [System.Collections.Generic.List[object]]::new()
    foreach ($n in (Get-NoteList $state)) {
        if ($n.type -eq 'escalation') {
            $open.Add($n)
        } elseif ($n.type -eq 'resolution') {
            for ($i = $open.Count - 1; $i -ge 0; $i--) {
                if ($open[$i].id -eq $n.id) { $open.RemoveAt($i); break }
            }
        }
    }
    return ,([object[]]$open.ToArray())
}

# The deepest open escalation, or $null. Call sites must not wrap this in @().
function Get-DeepestOpen($state) {
    $open = Get-OpenEscalations $state
    if ($open.Count -eq 0) { return $null }
    return $open[$open.Count - 1]
}

function Get-NextEscalationId($state) {
    $count = 0
    foreach ($n in (Get-NoteList $state)) {
        if ($n.type -eq 'escalation') { $count++ }
    }
    return "E$($count + 1)"
}

# 'ready' has no artifact of its own. A stage counts as produced only when its
# artifact exists; 'tasks' counts only when the folder holds at least one entry.
function Test-StageArtifact($folder, [string]$stage) {
    $name = $StageArtifacts[$stage]
    if (-not $name) { return $true }
    $path = Join-Path $folder $name
    if ($stage -eq 'tasks') {
        return (Test-Path $path) -and (@(Get-ChildItem $path -ErrorAction SilentlyContinue).Count -gt 0)
    }
    return (Test-Path $path)
}

function Get-ArtifactLabel([string]$stage) {
    if ($stage -eq 'tasks') { return 'the tasks/ folder has no task folder' }
    return "$($StageArtifacts[$stage]) does not exist"
}

$CommandList = 'init, list, current, read, advance, escalate, resolve'

if (-not $Command) {
    Fail "workflow cannot run because no command was given; expected one of: $CommandList"
}

switch ($Command) {
    'init' {
        if (-not $Slug) { Fail 'init cannot run because --slug is required' }
        if ($Slug -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
            Fail "init cannot create '$Slug' because the slug must be kebab-case (lowercase letters, digits, single hyphens)"
        }

        $StartStage = if ($At) { $At } else { 'story' }
        if ([array]::IndexOf($StartableStages, $StartStage) -lt 0) {
            Fail "init cannot create '$Slug' because '$StartStage' is not a valid start stage (story, design, or tasks)"
        }

        $folders = @(Get-WorkflowFolders)
        foreach ($f in $folders) {
            if ($f.Name.Substring(5) -ceq $Slug) {
                Fail "init cannot create '$Slug' because $($f.Name) already uses that slug"
            }
        }

        $nextNumber = 1
        if ($folders.Count -gt 0) {
            $highest = ($folders | ForEach-Object { [int]$_.Name.Substring(0, 3) } | Measure-Object -Maximum).Maximum
            $nextNumber = [int]$highest + 1
        }
        if ($nextNumber -gt 999) {
            Fail 'init cannot create a workflow because the numbering is exhausted (maximum prefix is 999)'
        }

        $id = '{0:d3}' -f $nextNumber
        $folderName = "$id. $Slug"
        $folder = Join-Path $WorkflowsRoot $folderName

        New-Item -ItemType Directory -Force -Path $folder | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $folder 'tasks') | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $folder 'escalations') | Out-Null

        $state = [ordered]@{
            id      = $id
            slug    = $Slug
            created = (Get-Date -Format 'yyyy-MM-dd')
            stage   = $StartStage
            start   = $StartStage
            notes   = [object[]]@()
        }
        Write-State $folder $state
        Write-Output "ok: workflow '$folderName' created -> '$StartStage'"
    }

    'list' {
        $folders = @(Get-WorkflowFolders)
        if ($folders.Count -eq 0) {
            Write-Output 'ok: no workflows'
            exit 0
        }
        # Verify every container before printing anything: a corrupted folder
        # must stop the command, never leave a half-list behind.
        foreach ($f in $folders) { $null = Read-State $f.FullName }

        foreach ($f in $folders) {
            $state = Read-State $f.FullName
            $deepest = Get-DeepestOpen $state
            $mark = '-'
            if ($null -ne $deepest) { $mark = "escalation $($deepest.id) open" }
            Write-Output "$($state.id). $($state.slug) | $($state.stage) | $mark | $($state.created)"
        }
    }

    'read' {
        if (-not $Slug) { Fail 'read cannot run because --slug is required' }
        $folder = Resolve-WorkflowFolder $Slug
        $state = Read-State $folder

        if (-not $Field) {
            Write-Output (Format-Json $state)
            exit 0
        }

        if ($Field -eq 'start' -and $null -eq $state.PSObject.Properties['start']) {
            Write-Output 'story'
            exit 0
        }

        $prop = $state.PSObject.Properties[$Field]
        if ($null -eq $prop) {
            Fail "read cannot print '$Field' because '$Field' is not a workflow field"
        }
        if ($Field -eq 'notes') {
            Write-Output (Format-Json (Get-NoteList $state))
        } else {
            Write-Output "$($prop.Value)"
        }
    }

    'current' {
        if (-not $Slug) { Fail 'current cannot run because --slug is required' }
        $folder = Resolve-WorkflowFolder $Slug
        $state = Read-State $folder
        $folderName = Split-Path $folder -Leaf
        $index = Get-StageIndex $state.stage

        $startName = 'story'
        $startProp = $state.PSObject.Properties['start']
        if ($null -ne $startProp -and -not [string]::IsNullOrEmpty([string]$startProp.Value)) {
            $startName = [string]$startProp.Value
        }
        $startIndex = Get-StageIndex $startName
        $deepest = Get-DeepestOpen $state

        Write-Output "workflow '$folderName'"
        Write-Output "start=$startName"
        Write-Output "stage=$($state.stage)"
        Write-Output 'stages'
        foreach ($stageName in $StageNames) {
            $i = Get-StageIndex $stageName
            if ($i -eq $index) {
                $status = 'processing'
            } elseif ($null -ne $deepest -and $deepest.from -eq $stageName) {
                $status = 'pending'
            } elseif ($i -lt $startIndex -and $i -lt $index) {
                $status = 'skipped'
            } elseif ($i -lt $index) {
                $status = 'done'
            } else {
                $status = '-'
            }
            Write-Output ('  ' + $stageName.PadRight(6) + " [ $status ]")
        }

        # Artifact gaps from the start to the current stage. 'ready' has none.
        $from = $startIndex
        if ($index -lt $from) { $from = $index }
        for ($i = $from; $i -le $index; $i++) {
            $name = $StageNames[$i]
            if ($name -eq 'ready') { continue }
            if (-not (Test-StageArtifact $folder $name)) { Write-Output "gap=$name" }
        }

        if ($null -eq $deepest) {
            Write-Output 'escalation=none'
        } else {
            Write-Output "escalation=$($deepest.id)"
            Write-Output "owner=$($deepest.to)"
            Write-Output "raisedBy=$($deepest.from)"
            Write-Output "since=$($deepest.date)"
            Write-Output "reason=$($deepest.reason)"
            # A state file written before briefs existed has no 'brief' property,
            # and StrictMode makes a bare property read on it a terminating error.
            $brief = '-'
            if ($null -ne $deepest.PSObject.Properties['brief']) { $brief = $deepest.brief }
            Write-Output "brief=$brief"
        }
    }

    'advance' {
        if (-not $Slug) { Fail 'advance cannot run because --slug is required' }
        $folder = Resolve-WorkflowFolder $Slug
        $state = Read-State $folder
        $current = $state.stage
        $folderName = Split-Path $folder -Leaf

        $deepest = Get-DeepestOpen $state
        if ($null -ne $deepest) {
            Fail "advance cannot move from '$current' because escalation $($deepest.id) is open; run 'current', then 'resolve $($deepest.id)'"
        }

        $index = Get-StageIndex $current
        if ($index -ge ($StageNames.Count - 1)) {
            Fail "advance cannot move because the workflow is already at '$current'"
        }
        if (-not (Test-StageArtifact $folder $current)) {
            Fail "advance cannot leave '$current' because $(Get-ArtifactLabel $current); produce it first"
        }

        $next = $StageNames[$index + 1]
        $state.stage = $next
        Write-State $folder $state
        Write-Output "ok: workflow '$folderName' advanced '$current' -> '$next'"
    }

    'escalate' {
        if (-not $Slug) { Fail 'escalate cannot run because --slug is required' }
        if (-not $Reason) {
            Fail 'escalate cannot record an escalation because --reason is required'
        }
        $folder = Resolve-WorkflowFolder $Slug
        $state = Read-State $folder
        $current = $state.stage
        $currentIndex = Get-StageIndex $current
        $folderName = Split-Path $folder -Leaf

        if ($currentIndex -lt 1) {
            Fail "escalate cannot move back from '$current' because '$current' is the first stage"
        }

        $target = $To
        if (-not $target) { $target = $StageNames[$currentIndex - 1] }
        $targetIndex = Get-StageIndex $target

        if ($targetIndex -lt 0) {
            Fail "escalate cannot target '$target' because '$target' is not a known stage"
        }
        if ($targetIndex -eq $currentIndex) {
            Fail "escalate cannot target '$target' because the workflow is already at '$target'"
        }
        if ($targetIndex -gt $currentIndex) {
            Fail "escalate cannot target '$target' because escalate only moves backwards"
        }

        $id = Get-NextEscalationId $state

        # The brief is the escalation's evidence: it must exist and sit with the
        # workflow, so a raise can never point at an unrelated file. The path is
        # recorded as given and the file itself is never read.
        if (-not $Brief) {
            Fail "escalate cannot open $id because --brief is required; the evidence is not optional"
        }
        $briefPath = $Brief
        if (-not [System.IO.Path]::IsPathRooted($briefPath)) {
            $briefPath = Join-Path $PWD $briefPath
        }
        $briefPath  = [System.IO.Path]::GetFullPath($briefPath)
        $briefsRoot = [System.IO.Path]::GetFullPath((Join-Path $folder 'escalations'))
        if ((Split-Path $briefPath -Parent) -ne $briefsRoot) {
            Fail "escalate cannot open $id because the brief must live in '$briefsRoot'"
        }
        if (-not (Test-Path $briefPath -PathType Leaf)) {
            Fail "escalate cannot open $id because brief '$Brief' is missing; write it first"
        }

        $notes = Get-NoteList $state
        $notes += [ordered]@{
            type   = 'escalation'
            id     = $id
            from   = $current
            to     = $target
            reason = $Reason
            brief  = $Brief
            date   = (Get-Date -Format 'yyyy-MM-dd')
        }
        $state.stage = $target
        $state.notes = [object[]]$notes

        Write-State $folder $state
        Write-Output "ok: workflow '$folderName' escalated '$current' -> '$target'"
    }

    'resolve' {
        if (-not $Slug) { Fail 'resolve cannot run because --slug is required' }
        if (-not $Id) { Fail 'resolve cannot close an escalation because --id is required' }
        if (-not $Report) {
            Fail "resolve cannot close $Id because --report is required; the next stage needs it"
        }
        $folder = Resolve-WorkflowFolder $Slug
        $state = Read-State $folder
        $notes = Get-NoteList $state
        $folderName = Split-Path $folder -Leaf

        $exists = $false
        foreach ($n in $notes) {
            if ($n.type -eq 'escalation' -and $n.id -eq $Id) { $exists = $true; break }
        }
        if (-not $exists) {
            Fail "resolve cannot close $Id because no escalation $Id exists; run 'current' to list open escalations"
        }

        $deepest = Get-DeepestOpen $state
        if ($null -eq $deepest) {
            Fail "resolve cannot close $Id because no escalation is open; run 'current'"
        }
        if ($deepest.id -ne $Id) {
            Fail "resolve cannot close $Id because $($deepest.id) is still open; close $($deepest.id) first"
        }

        $notes += [ordered]@{
            type   = 'resolution'
            id     = $Id
            report = $Report
            date   = (Get-Date -Format 'yyyy-MM-dd')
        }
        $index = Get-StageIndex $state.stage
        $next = $state.stage
        if ($index -lt ($StageNames.Count - 1)) { $next = $StageNames[$index + 1] }
        $state.stage = $next
        $state.notes = [object[]]$notes

        Write-State $folder $state
        Write-Output "ok: workflow '$folderName' resolved '$Id' -> '$next'"
    }

    default {
        Fail "workflow cannot run because '$Command' is not a known command; expected one of: $CommandList"
    }
}

# Set the exit code explicitly -- a script that completes without calling exit
# leaves $LASTEXITCODE holding whatever the previous command set.
exit 0
