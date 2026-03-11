<#
    .SYNOPSIS
    --------------------------------------------------
    | AUDIT DEEP SCAN - PURVIEW AUDIT LOG GENERATOR: |
    --------------------------------------------------
    Tool By: 
        GlobBruh @ tech.beyondgone.xyz
        
    Generates Microsoft Purview audit logs using Graph API. 

    .DESCRIPTION
    N/a

    --------
    LICENSE:
    --------
    This script is licensed under the BSD-3-Clause License. You are free to use, modify, and distribute this script as long as you comply with the terms of the license.
    For full license details, please refer to the included LICENSE file.

    -----------------
    DEFAULT BEHAVIOR:
    -----------------
    Generates an audit log. 

#>

if (Get-InstalledModule -Name Microsoft.Graph -ErrorAction SilentlyContinue) {
    Write-Verbose "Microsoft.Graph module is already installed."
    Import-Module Microsoft.Graph.Reports
} else {
    Write-Warning "Microsoft.Graph module is not installed. Aborting script execution."
    exit
}
Write-Output "Connecting to Microsoft Graph with required scopes."
Write-Output "You may be prompted to authenticate if you haven't already done so in this session."
#Connect-MgGraph -Scopes "AuditLog.Read.All", "Directory.Read.All" -NoWelcome
Write-Output "Successfully connected to Microsoft Graph."
