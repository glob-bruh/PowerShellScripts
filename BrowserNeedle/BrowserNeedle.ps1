<#
.SYNOPSIS
////////////////////////////////////////////////////////////////////////////////////

****************** BrowserNeedle - Web Browser Analysis Tool ***********************
                    GlobBruh @ https://tech.beyondgone.xyz

////////////////////////////////////////////////////////////////////////////////////

.DESCRIPTION
BrowserNeedle is a PowerShell script designed to analyze web browsers on a Windows system. It can extract browser history, installed extensions, and other relevant data from popular browsers like Microsoft Edge, Google Chrome, and Mozilla Firefox.

.PARAMETER Browser
Specifies the browser to analyze. Supported values are "Edge", "Chrome", and "Firefox".
Specifying "detect" will attempt to automatically detect installed browsers and analyze them.

.PARAMETER Username
Specifies the username of the profile to analyze. 

.PARAMETER ProfileName
Specifies the profile to analyze (optional). If not provided, all profiles will be analyzed and displayed.

.EXAMPLE
.\BrowserNeedle.ps1 -Browser Edge -Username targetuser
Analyzes the Microsoft Edge browser for the specified user "targetuser".
#>

[CmdletBinding()]
    Param(
        [string]$Browser,
        [string]$Username,
        [string]$ProfileName
    )

function sqlBrowserHistoryExtraction ($dbPath) {
    $urlList = @()
    $Regex = '(http(|s))://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?' # Avoiding the use of external modules or portable versions of SQLite. 
    foreach ($line in Get-Content -Path $dbPath) {
        if ($line -match $Regex) {
            $urlList += $matches[0]
        }
    }
    foreach ($x in ($urlList | Sort-Object -Unique) ) {
        Write-Output "--> $x"
    }
}

function edge_History {
    # keeping function for profile implementation. 
    foreach ($x in sqlBrowserHistoryExtraction "C:\Users\$Username\AppData\Local\Microsoft\Edge\User Data\Default\History") {
        Write-Output "--> $x"
    }
}

function edge_Preferences {
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
                    Write-Output "--> Extension: $manName"
                    Write-Output "-----> ID: $extID"
                    Write-Output "-----> Author: $manAuthor"
                    write-Output "-----> Version: $manVersion"
                    write-Output "-----> Description: $manDesc"
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

function edge_SitePermissions {
    $edgePrefs = "C:\Users\$Username\AppData\Local\Microsoft\Edge\User Data\Default\Preferences"
    if (Test-Path $edgePrefs) {
        $preferences = Get-Content -path $edgePrefs | ConvertFrom-Json
        Write-Output $preferences
    }
}

function scanEdge {
    Write-Output "EDGE HISTORY:"
    sqlBrowserHistoryExtraction "C:\Users\$Username\AppData\Local\Microsoft\Edge\User Data\Default\History"
    write-Output "EDGE EXTENSIONS:"
    edge_Preferences
    #Write-Output "EDGE SITE-BASED PERMISSIONS:"
    #edge_SitePermissions
}

function firefox_History ($profileToScan) {
    Write-Output "FIREFOX HISTORY FOR PROFILE: $profileToScan"
    sqlBrowserHistoryExtraction "C:\Users\$Username\AppData\Roaming\Mozilla\Firefox\Profiles\$profileToScan\places.sqlite"
}

function scanFirefox {
    $firefoxPath = "C:\Users\$Username\AppData\Roaming\Mozilla\Firefox\Profiles"
    if ($ProfileName -eq "detect") {
        foreach ($profile in Get-ChildItem -Path $firefoxPath) {
            firefox_History $profile.Name
        }
    } else {
        Write-Warning "Please specify a valid profile name or use 'detect' to automatically scan all profiles."
    }
}

Write-Output "====================================================="
Write-Output "BROWSERNEEDLE"
Write-Output "GlobBruh @ https://tech.beyondgone.xyz"
Write-Output "====================================================="
if (-not $Username) {
    Write-Warning "No username specified. Please run Get-Help for more information."
    exit
}
if (-not (Test-Path C:\Users\$Username)) {
    Write-Warning "The specified user '$Username' does not exist on this system."
    exit
}
Write-Output "USER TO ANALYZE: $Username"
switch ($Browser.ToLower()) {
    'edge' {
        Write-Output "BROWSER: Microsoft Edge", "=============================="
        scanEdge
    }
    'firefox' {
        Write-Output "BROWSER: Mozilla Firefox", "=============================="
        scanFirefox
    }
    'chrome' {
        Write-Output "BROWSER: Google Chrome", "=============================="
        Write-Output "Chrome scanning not yet implemented."
    }
    default { Write-Warning "Invalid browser specified." }
}