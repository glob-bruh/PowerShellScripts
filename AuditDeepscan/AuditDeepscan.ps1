
# ==========================================================
# AUDIT DEEP SCAN
# GlobBruh - tech.beyondgone.xyz
# ==========================================================

# ----------------
# CONFIGURATION
# ----------------
$file2Scan = "purviewAuditExport.csv"
$apiURL = "http://ip-api.com"
$apiPath = "/batch"
# ----------------

function ipAddressParse($inStr) {
    if ($inStr.contains("[") -and $inStr.contains("]")) {
        $outStr = $inStr.split("]")[0].split("[")[1]
        return $outStr
    } else {
        return $inStr
    }
}

$IPArray = @()
$reportData = Import-Csv -LiteralPath $file2Scan

Write-Output "========================"
foreach ($i in $reportData) {
    $auditData = ConvertFrom-Json $i.AuditData
    if ($null -ne $auditData.ClientIP) {
        $clientIP = $auditData.ClientIP
        $IPArray += ipAddressParse $clientIP
    } elseif ($null -ne $auditData.ActorIpAddress) {
        $clientIP = $auditData.ActorIpAddress
        $IPArray += ipAddressParse $clientIP
    } 
    #Write-Output "$($auditData.UserID)"
    #Write-Output "|- Operation: $($auditData.Operation)."
    #Write-Output "|- IP Address: $($auditData.ActorIpAddress)."
    #Write-Output "|- IP Address: $($auditData.ClientIP)."
    #Write-Output "+++"
    #Write-Output ""
}


Write-Output "***************************"
#$auditData = ConvertFrom-Json $reportData[1].AuditData
#Write-Output $auditData.ClientIP
#Write-Output $auditData.ActorIpAddress
Write-Output "============"

$IPArray = $IPArray | Select-Object -Unique
$requestBody = '[{"query":"0.0.0.0", "fields":"city,country,countryCode,query", "lang":"en"}'
# NOTE: API CAN ONLY HANDLE UP TO 100 IP'S IN BATCH REQUEST. 
foreach ($i in $IPArray) {
    $requestBody += ",`"$($i)`""
    Write-Output $requestBody
}
$requestBody += "]"
$response = Invoke-WebRequest -Uri $($apiURL + $apiPath) -Method POST -Body $requestBody -UseBasicParsing 
$ipLookupResult = ConvertFrom-Json $response.Content
Write-Output $ipLookupResult[1]

#Write-Output $IPArray
#Write-Output $IPArray.Length
Write-Output "***"