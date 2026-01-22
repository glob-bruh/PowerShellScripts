<#
    .SYNOPSIS
    ----------------
    AUDIT DEEP SCAN:
    ----------------
    *** CREATED BY: GlobBruh (https://tech.beyondgone.xyz) ***
    Scans audit log entries and enriches them with information from external API and conversions.

    .DESCRIPTION
    This PowerShell script processes audit log entries from a specified CSV file, extracts IP addresses, and queries an external API to retrieve detailed information about those IPs.
    It enriches the audit log entries with this information and provides options to filter based on multiple criteria such as IP type, UserID, and Operation type.
    The script respects API rate limits by batching requests and includes verbose logging for transparency.

    DEFAULT BEHAVIOR:
    If no filters are applied, the script will output all audit log entries with enriched information.

    .PARAMETER file2Scan
    The path to the CSV Purview audit export containing the audit log entries to be scanned.
    Accepts a string value representing the file path.
    This parameter is required.

    .PARAMETER IPAddressSearch
    Optional parameter to filter audit log entries by IP Address.
    Uses wildcard matching to find entries that contain the specified string.

    .PARAMETER IPdatasetOut
    Optional parameter to specify a file path to save the IP lookup data in JSON format.
    This is useful for caching the IP data to avoid redundant API calls in future scans.

    .PARAMETER IPdatasetIn
    Optional parameter to specify a file path to load existing IP lookup data in JSON format.
    This allows the script to bypass API calls and use previously retrieved data, avoiding the need to query the external API repetitively.

    .PARAMETER filterIPType
    Specifies the type of filter to apply to the audit log entries.
    Accepted values are:
    - "mobile": Outputs only entries from mobile IP addresses.
    - "proxy": Outputs only entries from proxy/VPN IP addresses.
    - "hosting": Outputs only entries from hosting provider IP addresses.

    .PARAMETER UserIDSearch
    Optional parameter to filter audit log entries by UserID (such as email or username).
    Uses wildcard matching to find entries that contain the specified string.

    .PARAMETER OperationSearch
    Optional parameter to filter audit log entries by Operation type (such as Set-Mailbox or AccessedAggregates).
    Uses wildcard matching to find entries that contain the specified string.

    .INPUTS
    None. This script does not accept input from the pipeline.

    .OUTPUTS
    Outputs the audit log entries with enriched information.

    .EXAMPLE
    PS> AuditDeepscan.ps1 -file2Scan C:\path\to\auditlog.csv
    Scans the audit log entries and outputs all entries.
    This is the default behavior when no filters are applied.
    NOTE: This may result in a large volume of output depending on the size of the audit log.

    .EXAMPLE 
    PS> AuditDeepscan.ps1 -file2Scan C:\path\to\auditlog.csv -IPdatasetOut C:\path\to\ipdataset.json
    Scans the audit log entries and outputs all entries, while also saving the IP lookup data to the specified JSON file for future use. 
    This is useful for avoiding redundant API calls in subsequent searches.

    .EXAMPLE
    PS> AuditDeepscan.ps1 -file2Scan C:\path\to\auditlog.csv -filterType proxy
    Scans the audit log entries and outputs only those from proxy/VPN IP addresses.

    .EXAMPLE
    PS> AuditDeepscan.ps1 -file2Scan C:\path\to\auditlog.csv -filterIPType hosting -UserIDSearch john.doe -OperationSearch create
    Scans the audit log entries and outputs only those from hosting provider IP addresses, where the UserID contains "john.doe" and the Operation contains "create".

    .EXAMPLE
    PS> AuditDeepscan.ps1 -file2Scan C:\path\to\auditlog.csv -OperationSearch UserLoggedIn -IPAddressSearch 1.2.3.4 -filterIPType proxy -UserIDSearch john.doe -IPdatasetOut C:\path\to\ipdataset.json -IPdatasetIn C:\path\to\ipdataset.json
    Scans the audit log entries and applies multiple filters:
    - Outputs only entries where the Operation contains "UserLoggedIn".
    - Outputs only entries where the IP Address contains "1.2.3.4".
    - Outputs only entries from proxy/VPN IP addresses.
    - Outputs only entries where the UserID contains "john.doe".
    - Uses existing IP lookup data from the specified JSON file to avoid API calls.
    This example demonstrates the use of multiple filters to narrow down the results, which is particularly useful for targeted investigations.

    .LINK
    GitHub: https://github.com/glob-bruh/PowerShellScripts/tree/main/AuditDeepscan
    Homepage: https://tech.beyondgone.xyz
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
        [string]$file2Scan,
    [Parameter(Mandatory=$false)]
        [string]$filterIPType, 
        [string]$UserIDSearch, 
        [string]$OperationSearch,
        [string]$IPAddressSearch,
        [string]$IPdatasetOut,
        [string]$IPdatasetIn
)

# ----------------
# CONFIGURATION
# ----------------
$apiURL = "http://ip-api.com/batch?fields=17035263"
$APIwaitTimeSeconds = 15
$APImaxIP = 97
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
    Write-Verbose "------------- IP LOOKUP ----------------"
    Write-Verbose "Performing IP lookup via external API..."
    write-Verbose "API Request Body: $request"
    $response = Invoke-WebRequest -Uri $apiURL -Method POST -Body $request -UseBasicParsing 
    $output = ConvertFrom-Json $response.Content
    Write-Verbose "----------------------------------------"
    return $output  
}

function outputEntry($resultData) {
    Write-Output "$($resultData.AuditData.UserID) --> $($resultData.AuditData.Operation)"
    if ($null -ne $resultData.AuditData.UserAgent) {
        Write-Output "|- User Agent: $($resultData.AuditData.UserAgent)."
    }
    Write-Output "|- Time: $($resultData.Time)."
    if ($null -ne $resultData.ClientIPinfo.IP) {
        Write-Output "|- IP Address: $($resultData.ClientIPinfo.IP)."
        Write-Output "|--- Location: $($resultData.ClientIPinfo.City), $($resultData.ClientIPinfo.Region), $($resultData.ClientIPinfo.Country)."
        Write-Output "|--- ISP: $($resultData.ClientIPinfo.ISP)."
        Write-Output "|----- Organization: $($resultData.ClientIPinfo.Org)."
        Write-Output "|----- AS: $($resultData.ClientIPinfo.AS)."
        Write-Output "|--- Special Properties:"
        Write-Output "|----- Is mobile: $($resultData.ClientIPinfo.IsMobile)."
        Write-Output "|----- Is proxy: $($resultData.ClientIPinfo.IsProxy)."
        Write-Output "|----- Is hosting: $($resultData.ClientIPinfo.IsHosting)."
    } else {
        Write-Output "|- IP Address: N/A"
    }
}

Write-Output "========================"
Write-Output "AUDIT DEEP SCAN"
Write-Output "GlobBruh - tech.beyondgone.xyz"
Write-Output "========================"

$IPArray = @()
$reportData = Import-Csv -LiteralPath $file2Scan | Sort-Object -Property CreationDate
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
$chunks = @()
$IPLookups = @()
if ($PSBoundParameters.ContainsKey("IPdatasetIn") -and (Test-Path -Path $IPdatasetIn)) {
    Write-Verbose "Skipping API lookups and using existing dataset."
    Write-Verbose "Importing IP lookup data from JSON file: $IPdatasetIn"
    $IPLookups = Get-Content -Path $IPdatasetIn | ConvertFrom-Json
} else {
    Write-Verbose "Looking up $($IPArray.Count) unique IP addresses via external API..."
    for ($i = 0; $i -lt $IPArray.Count; $i += $APImaxIP) { 
            $high = $i + $APImaxIP - 1
            $low = $i
            $chunk = $IPArray[$high..$low]
            $chunks += ,$chunk
    }
    if ($chunks.Count -gt 1) {
        $howLong = ($chunks.Count - 1) * $APIwaitTimeSeconds
        Write-Warning "Over 100 unique IP's detected. Pausing between API requests to respect rate limits."
        Write-Warning "Estimated total wait time: $howLong seconds."
    }
    foreach ($x in $chunks) {
        $requestBody = '[{"query":"0.0.0.0", "lang":"en"}'
        foreach ($y in $x) {
            $requestBody += ",`"$($y)`""
        }
        $requestBody += "]"
        $IPLookups += ipLookup $requestBody
        if ($chunks.Count -gt 1) {
            Write-Verbose "Pausing for 15 second to respect API rate limits..."
            Start-Sleep -Seconds $APIwaitTimeSeconds
        }
    }
}

if ($PSBoundParameters.ContainsKey("IPdatasetOut")) {
    Write-Verbose "Exporting IP lookup data to JSON file: $IPdatasetOut"
    $IPLookups | ConvertTo-Json | Out-File -FilePath $IPdatasetOut
} 

foreach ($i in $reportData) {
    $auditData = ConvertFrom-Json $i.AuditData
    if ($null -ne $auditData.ClientIP) {
        $clientIP = ipAddressParse $auditData.ClientIP
    } elseif ($null -ne $auditData.ActorIpAddress) {
        $clientIP = ipAddressParse $auditData.ActorIpAddress
    }
    foreach ($x in $IPLookups) {
        if ($x.query -eq $clientIP) {
            $clientIPinfo = [PSCustomObject]@{
                "IP"        = $x.query
                "Country"   = $x.country
                "Region"    = $x.regionName
                "City"      = $x.city
                "ISP"       = $x.isp
                "Org"       = $x.org
                "AS"        = $x.as
                "IsMobile"  = convertToBoolean $x.mobile
                "IsProxy"   = convertToBoolean $x.proxy
                "IsHosting" = convertToBoolean $x.hosting
            }
        }
    }
    $time = ([datetime]$auditData.CreationTime).ToString("MMMM dd, yyyy hh:mm:ss tt")
    $resultData = [PSCustomObject]@{
        "AuditData"    = $auditData
        "Time"         = $time
        "ClientIPinfo" = $clientIPinfo
    }
    $showThisEntry = $true
    if ($PSBoundParameters.ContainsKey("filterIPType")) {
        switch ($filterIPType) {
            "mobile" { if ($clientIPinfo.IsMobile -ne $filterIPType) { $showThisEntry = $false ; continue } }
            "proxy" { if ($clientIPinfo.IsProxy -ne $filterIPType) { $showThisEntry = $false ; continue } }
            "hosting" { if ($clientIPinfo.IsHosting -ne $filterIPType) { $showThisEntry = $false ; continue }
            }
        }
    }
    if ($PSBoundParameters.ContainsKey("UserIDSearch")) {
        if ($auditData.UserID -notlike "*$UserIDSearch*") { $showThisEntry = $false ; continue }
    }
    if ($PSBoundParameters.ContainsKey("OperationSearch")) {
        if ($auditData.Operation -notlike  "*$OperationSearch*") { $showThisEntry = $false ; continue }
    }
    if ($PSBoundParameters.ContainsKey("IPAddressSearch")) {
        if ($clientIPinfo.IP -notlike "*$IPAddressSearch*") { $showThisEntry = $false ; continue }
    }
    if ($showThisEntry -eq $true) { outputEntry $resultData } 
}