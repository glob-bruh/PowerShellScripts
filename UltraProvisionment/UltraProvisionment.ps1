# #########################
# ULTRA PROVISIONMENT 
# #########################
# CREATED BY GlobBruh
# #########################

function checkNetwork ($targIp) {
    $x = $true ; $i = $true
    while ($x -eq $true) {
        Test-Connection -Count 3 -ComputerName $targIp -ErrorAction SilentlyContinue > $null
        if ($? -eq $true) {$x = $false} else {
            if ($i -eq $true) {
                Write-Output "You need network..."
                $i = $false
            }
        }
    }
}

function setDateTime () {
    Set-TimeZone -Id "Mountain Standard Time"
}

function setPowerPlan ($ppName) {
    Write-Output "1 = Desktop", "2 = Laptop"
    $sel = Read-Host "Choice"
    $x = powercfg.exe /GETACTIVESCHEME
    $x = $x.Split(":")[1].Split("(")[0].Trim()
    $x = powercfg.exe /DUPLICATESCHEME $x
    $x = $x.Split(":")[1].Split("(")[0].Trim()
    powercfg.exe /CHANGENAME $x $ppName
    powercfg.exe /SETACTIVE $x
    powercfg.exe /H off
    powercfg.exe /X monitor-timeout-ac 0
    powercfg.exe /X standby-timeout-ac 0
    if ($sel -eq 2) {
        powercfg.exe /X monitor-timeout-dc 5
        powercfg.exe /X standby-timeout-dc 10
    }
}

function installChrome () {
    (New-Object System.Net.WebClient).DownloadFile("https://dl.google.com/ChromeSetup.exe", "$env:TEMP\chrome.exe")
    Start-Process -FilePath "$env:TEMP\chrome.exe"
}

#checkNetwork "8.8.8.8"
#setDateTime
#setPowerPlan "High Performance"
installChrome