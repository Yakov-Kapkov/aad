#Requires -Version 5.1
<#
.SYNOPSIS
    Renames .sda/project-tools.md to .sda/project-tools_backup.md before a
    fresh scan, preserving the previous result for reference.
#>

$target = '.sda/project-tools.md'
$backup = '.sda/project-tools_backup.md'

if (Test-Path $target) {
    if (Test-Path $backup) { Remove-Item $backup -Force }
    try {
        Rename-Item -Path $target -NewName 'project-tools_backup.md' -ErrorAction Stop
    } catch {
        # Fallback for PS 5.1 where Rename-Item rejects a path as the new name
        Copy-Item $target $backup -Force
        Remove-Item $target -Force
    }
    Write-Host "Renamed: $target -> $backup"
} else {
    Write-Host "Not found (nothing to back up): $target"
}
