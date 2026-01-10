<#
    .SYNOPSIS
    ----------------
    AUDIT DEEP SCAN:
    ----------------
    Scans audit log entries and enriches them with information from external API and conversions.

    .DESCRIPTION
    This PowerShell script processes audit log entries from a specified CSV file, extracts IP addresses, and queries an external API to retrieve detailed information about those IPs. It enriches the audit log entries with this information and provides options to filter the output based on specific criteria such as mobile, proxy, or hosting IP addresses.

    .PARAMETER filterType
    Specifies the type of filter to apply to the audit log entries.
    Accepted values are:
    - "mobile": Outputs only entries from mobile IP addresses.
    - "proxy": Outputs only entries from proxy/VPN IP addresses.
    - "hosting": Outputs only entries from hosting provider IP addresses.
    If no filterType is provided, all audit log entries are output.

    .PARAMETER file2Scan
    The path to the CSV Purview audit export containing the audit log entries to be scanned.
    Accepts a string value representing the file path.

    .INPUTS
    None. This script does not accept input from the pipeline.

    .OUTPUTS
    Outputs the audit log entries with enriched information.

    .EXAMPLE
    PS> AuditDeepscan.ps1 -file2Scan "C:\path\to\auditlog.csv"
    Scans the audit log entries and outputs all entries.

    .EXAMPLE
    PS> AuditDeepscan.ps1 -file2Scan "C:\path\to\auditlog.csv" -filterType "mobile"
    Scans the audit log entries and outputs only those from mobile IP addresses.

    .EXAMPLE
    PS> auditdeepscan.ps1 -file2Scan "C:\path\to\auditlog.csv" -filterType "proxy"
    Scans the audit log entries and outputs only those from proxy/VPN IP addresses.

    .LINK
    GitHub: https://github.com/glob-bruh/PowerShellScripts/tree/main/AuditDeepscan
    Homepage: https://tech.beyondgone.xyz
#>

[CmdletBinding()]
param($file2Scan, $filterType)

# ----------------
# CONFIGURATION
# ----------------
$apiURL = "http://ip-api.com"
$apiPath = "/batch"
$apiParams = "?fields=17035263"
# ----------------

function convertToBoolean($inStr) {
    if ($inStr -like "true") {
        return $true
    } else {
        return $false
    }
}

function ipAddressParse($inStr) {
    if ($inStr.contains("[") -and $inStr.contains("]")) {
        $outStr = $inStr.split("]")[0].split("[")[1]
        return $outStr
    } else {
        return $inStr
    }
}

function ipLookup($request) {
    $response = Invoke-WebRequest -Uri $($apiURL + $apiPath + $apiParams) -Method POST -Body $request -UseBasicParsing 
    $output = ConvertFrom-Json $response.Content
    return $output  
}

function outputEntry($auditData, $time, $userAgent, $clientIP, $clientIPcountry, $clientIPregion, $clientIPcity, $clientIPisp, $clientIPorg, $clientIPas, $clientIPismobile, $clientIPisproxy, $clienIPishosting) {
    Write-Output "$($auditData.UserID) --> $($auditData.Operation)"
    Write-Output "|- Time: $($time)."
    Write-Output "|- User Agent: $($userAgent)."
    Write-Output "|- IP Address: $($clientIP)."
    Write-Output "|--- Location: $($clientIPcity), $($clientIPregion), $($clientIPcountry)."
    Write-Output "|--- ISP: $($clientIPisp)."
    Write-Output "|----- Organization: $($clientIPorg)."
    Write-Output "|----- AS: $($clientIPas)."
    Write-Output "|--- Special Properties:"
    Write-Output "|----- Is mobile: $($clientIPismobile)."
    Write-Output "|----- Is proxy: $($clientIPisproxy)."
    Write-Output "|----- Is hosting: $($clienIPishosting)."
}

Write-Output "========================"
Write-Output "AUDIT DEEP SCAN"
Write-Output "GlobBruh - tech.beyondgone.xyz"
Write-Output "========================"

$IPArray = @()
$reportData = Import-Csv -LiteralPath $file2Scan

foreach ($i in $reportData) {
    $auditData = ConvertFrom-Json $i.AuditData
    if ($null -ne $auditData.ClientIP) {
        $clientIP = $auditData.ClientIP
        $IPArray += ipAddressParse $clientIP
    } elseif ($null -ne $auditData.ActorIpAddress) {
        $clientIP = $auditData.ActorIpAddress
        $IPArray += ipAddressParse $clientIP
    } 
}

$IPArray = $IPArray | Select-Object -Unique
$requestBody = '[{"query":"0.0.0.0", "lang":"en"}'
# NOTE: API CAN ONLY HANDLE UP TO 100 IP'S IN BATCH REQUEST. 
foreach ($i in $IPArray) {
    $requestBody += ",`"$($i)`""
}
$requestBody += "]"
#if ($IPArray -gt 100) {
#    Write-Output "WARNING: IP Address count exceeds 100. Truncating to first 100 entries."
#    $requestBody = $requestBody[0..99]
#}
if ($IPArray.Length -gt 95) {
    Write-Warning "WARNING: IP Address count is $($IPArray.Length). API may not process more than 100 entries in a single batch request. Proceed?"
    $userInput = Read-Host "Type 'Y' to proceed, or any other key to abort"
    if ($userInput -ne "Y") {
        Write-Output "Aborting operation."
        exit
    } elseif ($userInput -eq "Y") {
        Write-Verbose "Proceeding with IP lookup."
        $ipLookupResults = ipLookup $requestBody
    }
} else {
    $ipLookupResults = ipLookup $requestBody
}

foreach ($i in $reportData) {
    $auditData = ConvertFrom-Json $i.AuditData
    if ($null -ne $auditData.ClientIP) {
        $clientIP = ipAddressParse $auditData.ClientIP
    } elseif ($null -ne $auditData.ActorIpAddress) {
        $clientIP = ipAddressParse $auditData.ActorIpAddress
    }
    foreach ($x in $ipLookupResults) {
        if ($x.query -eq $clientIP) {
            $clientIPcountry = $x.country
            $clientIPregion = $x.regionName
            $clientIPcity = $x.city
            $clientIPisp = $x.isp
            $clientIPorg = $x.org
            $clientIPas = $x.as
            $clientIPismobile = convertToBoolean $x.mobile
            $clientIPisproxy = convertToBoolean $x.proxy
            $clienIPishosting = convertToBoolean $x.hosting
        }
    }
    $time = ([datetime]$auditData.CreationTime).ToString("MMMM dd, yyyy hh:mm:ss tt")
    if ($null -ne $auditData.UserAgent) {
        $userAgent = $auditData.UserAgent
    } else {
        $userAgent = "N/A"
    }
    if ($filterType -eq "mobile") {
        if ($clientIPismobile -eq $true) {
            outputEntry $auditData $time $userAgent $clientIP $clientIPcountry $clientIPregion $clientIPcity $clientIPisp $clientIPorg $clientIPas $clientIPismobile $clientIPisproxy $clienIPishosting
        }
    } elseif ($filterType -eq "proxy") {
        if ($clientIPisproxy -eq $true) {
            outputEntry $auditData $time $userAgent $clientIP $clientIPcountry $clientIPregion $clientIPcity $clientIPisp $clientIPorg $clientIPas $clientIPismobile $clientIPisproxy $clienIPishosting
        }
    } elseif ($filterType -eq "hosting") {
        if ($clienIPishosting -eq $true) {
            outputEntry $auditData $time $userAgent $clientIP $clientIPcountry $clientIPregion $clientIPcity $clientIPisp $clientIPorg $clientIPas $clientIPismobile $clientIPisproxy $clienIPishosting
        }
    } else {
        outputEntry $auditData $time $userAgent $clientIP $clientIPcountry $clientIPregion $clientIPcity $clientIPisp $clientIPorg $clientIPas $clientIPismobile $clientIPisproxy $clienIPishosting
    }
}