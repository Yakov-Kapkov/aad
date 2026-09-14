#Requires -Version 5.1
<#
.SYNOPSIS
    Outputs the current timestamp in the format used by project-tools.md.
    stdout: "Month DD, YYYY, HH:mm"
#>

Get-Date -Format "MMMM dd, yyyy, HH:mm"
