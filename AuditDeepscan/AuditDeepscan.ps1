
# ==========================================================
# AUDIT DEEP SCAN
# GlobBruh - tech.beyondgone.xyz
# ==========================================================

# ----------------
# CONFIGURATION
# ----------------
$file2Scan = "a845363a-0ab3-4674-abcb-c5ff667d5611.csv"
$apiURL = "http://ip-api.com/"
$apiPath = "json/"
$apiParams = ""
# ----------------

$IPArray = @()
$reportData = Import-Csv -LiteralPath $file2Scan
foreach ($i in $reportData) {
    $auditData = ConvertFrom-Json $i.AuditData
    if ($null -ne $auditData.ClientIP) {
        $clientIP = $auditData.ClientIP.split("]")[0].split("[")[1]
        $IPArray += $clientIP
    }
}

Write-Output $IPArray
Write-Output $IPArray.Length