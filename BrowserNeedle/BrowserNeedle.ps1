<#
.SYNOPSIS
////////////////////////////////////////////////////////////////////////////////////

****************** BrowserNeedle - Web Browser Analysis Tool ***********************
                         GlobBruh @ tech.beyondgone.xyz

////////////////////////////////////////////////////////////////////////////////////

.DESCRIPTION
BrowserNeedle is a PowerShell script designed to analyze web browsers on a Windows system. It can extract browser history, installed extensions, and other relevant data from popular browsers like Microsoft Edge, Google Chrome, and Mozilla Firefox.

.PARAMETER Browser
Specifies the browser to analyze. Supported values are "Edge", "Chrome", and "Firefox".

.EXAMPLE
.\BrowserNeedle.ps1 -Browser Edge -Username targetuser
Analyzes the Microsoft Edge browser for the specified user "targetuser".

#>

[CmdletBinding()]
    Param(
        [string]$Browser,
        [string]$Username
    )

function edgeHistory {
    $urlList = @()
    $Regex = '(http(|s))://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'
    $historyFile = Get-Content -Path "C:\Users\$Username\AppData\Local\Microsoft\Edge\User Data\Default\History"
    Write-Output "Browser History for $Username - Edge:"
    foreach ($line in $historyFile) {
        if ($line -match $Regex) {
            $urlList += $matches[0]
        }
    }
    foreach ($url in $urlList | Sort-Object -Unique) {
        Write-Output "--> $url"
    }
}

function edgePreferences {
    $prefPath = "C:\Users\$Username\AppData\Local\Microsoft\Edge\User Data\Default\Preferences"
    if (Test-Path $prefPath) {
        $preferences = Get-Content -Path $prefPath | ConvertFrom-Json
        Get-ChildItem -Path "C:\Users\$Username\AppData\Local\Microsoft\Edge\User Data\Default\Extensions" | ForEach-Object {
            $extID = $_.Name
            $extensionVersions = Get-ChildItem "C:\Users\$Username\AppData\Local\Microsoft\Edge\User Data\Default\Extensions\$extID"
            foreach ($x in $extensionVersions) {
                $extVersion = $x.Name
                $manifestPath = "C:\Users\$Username\AppData\Local\Microsoft\Edge\User Data\Default\Extensions\$extID\$extVersion\manifest.json"
                if (Test-Path $manifestPath) {
                    $manifest = Get-Content -Path $manifestPath | ConvertFrom-Json
                    $manName = $manifest.name
                    if ($manAuthor -eq $null) {
                        $manAuthor = "N/A"
                    } else {
                        $manAuthor = $manifest.author
                    }
                    $manVersion = $manifest.version
                    $manDesc = $manifest.description
                    $manPermissions = $manifest.permissions
                    Write-Output "--> Extension: $manName."
                    Write-Output "-----> ID: $extID."
                    Write-Output "-----> Author: $manAuthor."
                    write-Output "-----> Version: $manVersion."
                    write-Output "-----> Description: $manDesc."
                    Write-Output "-----> Permissions:"
                    if ($manPermissions -ne $null) {
                        foreach ($perm in $manPermissions) {
                            Write-Output "---------> $perm"
                        }
                    } else {
                        Write-Output "---------> N/A"
                    }
                }
            }
        }
    } else {
        Write-Warning "Preferences file not found."
        return $null
    }
}

function scanEdge {
    edgeHistory
    write-Output "EDGE EXTENSIONS:"
    edgePreferences
}

Write-Output "*****************************************************"
Write-Output "***** BrowserNeedle - Web Browser Analysis Tool *****"
Write-Output "***  Developed by GlobBruh @ tech.beyondgone.xyz  ***"
Write-Output "*****************************************************"
Write-Output "USER TO ANALYZE: $Username"
switch ($Browser.ToLower()) {
    'edge' {
        Write-Output "BROWSER: Microsoft Edge", "=============================="
        scanEdge
    }
    'firefox' {
        Write-Output "BROWSER: Mozilla Firefox", "=============================="
        Write-Output "Firefox scanning not yet implemented."
    }
    'chrome' {
        Write-Output "BROWSER: Google Chrome", "=============================="
        Write-Output "Chrome scanning not yet implemented."
    }
    default { Write-Warning "Invalid mode specified." }
}