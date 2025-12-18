######################
# DISKSMASHER
# --------------------
# Fully automatic disk search designed to point out reasons 
# behind large disk usage. 
# --------------------
# Created by GlobBruh
######################

[CmdletBinding()]
param()

function numRound ($inVar) {
    return [math]::Round($inVar, 2)
}

function getBasicInformation () {
    $x = Get-WmiObject -Class "Win32_ComputerSystem"
    $curUser = $x.Username
    $x = Get-CimInstance -ClassName "Win32_OperatingSystem"
    $upTm = (Get-Date) - $x.LastBootUpTime
    $upTmS = $upTm.Seconds ; $upTmM = $upTm.Minutes ; $upTmH = $upTm.Hours  ; $upTmD = $upTm.Days
    Write-Output "-> General Information:"
    Write-Output "--> Current Domain/User: $curUser. || Uptime: S:$upTmS M:$upTmM H:$upTmH D:$upTmD."
    $x = Get-PSDrive -Name "C"
    $usedSpace =  numRound ($x.Used / 1gb)
    $freeSpace =  numRound ($x.Free / 1gb)
    $totalSpace = $usedSpace + $freeSpace
    $percUsed = numRound (($usedSpace / $totalSpace) * 100)
    $percFree = numRound (($freeSpace / $totalSpace) * 100)
    Write-Output "-> Disk Usage:"
    Write-Output "--> Total (gb): $totalSpace. || Used/Free (gb): $usedSpace/$freeSpace. || Used/Free (%): $percUsed/$percFree."
}

function getSizeOfFolderContents ($path) {
    Write-Output "-> Retrieve total size of $path`:"
    $i = 0
    if ((Test-Path -Path $path) -eq $true) {
        foreach ($x in (Get-ChildItem -Path $path -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            $i += $x.Length
        }
        $out = numRound ($i / 1gb)
    } else {
        $out = "N/a"
    }
    Write-Output "--> Total size of accessible files: $out gb."
}

function listLargeFilesInFolders ($path, $fileCount) {
    Write-Output "-> Largest files in $path (top $fileCount):"
    $x = (Get-ChildItem -Path $path -Recurse -File -Force -ErrorAction SilentlyContinue | Sort-Object Length | Select-Object -Last $fileCount)
    foreach ($i in $x) {
        $size = numRound ($i.Length / 1gb)
        Write-Output "--> $size gb: $($i.FullName)"
    }
}

function getVolumeRootStats () {
    listLargeFilesInFolders "C:\" 12
}

function getUserFolderStats () {
    Write-Output "-> Last used desktop:"
    $x = (Get-ChildItem -Path "C:\Users\" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq "desktop.ini"})
    foreach ($i in $x) {
        if ($i.FullName.Split("\")[-2] -eq "Desktop") {
            $userFolder = $i.FullName.Split("\")[-3]
            Write-Output "--> $userFolder`: $($i.LastAccessTime)"
        }
    }
    listLargeFilesInFolders "C:\Users\" 12
}

function getSizeOfAllSignedFilesInDir($path, $subject) {
    $totalLen = 0
    $orgName = $subject.split(",")[2].split("=")[1]
    Write-Output "-> Check $path for files with specific signature from $orgName"
    $x = Get-ChildItem -Path $path -File -Force 
    foreach ($i in $x) {
        if ((Get-AuthenticodeSignature -FilePath $i.FullName).SignerCertificate.Subject -eq $subject) {
            $totalLen += $i.Length
            Write-Verbose "---> $i`: $(numRound($i.Length / 1gb)) gb"
        }
    }
    Write-Output "--> Total size of signed files in this folder: $(numRound($totalLen / 1gb)) gb."
}

function checkNoteableLargeFolders () {
    getSizeOfFolderContents "C:\Windows\CSC\"
    getSizeOfFolderContents "C:\Windows\SoftwareDistribution\Download\"
    $sigSubject = "CN=Adobe Inc., OU=Acrobat DC, O=Adobe Inc., L=San Jose, S=ca, C=US, SERIALNUMBER=2748129, OID.2.5.4.15=Private Organization, OID.1.3.6.1.4.1.311.60.2.1.2=Delaware, OID.1.3.6.1.4.1.311.60.2.1.3=US"
    getSizeOfAllSignedFilesInDir "C:\Windows\Installer\" $sigSubject
}

function newSection ($sectionTxt) {
    Write-Output "==============================", ($sectionTxt + ":")
}

Write-Output "=============================="
Write-Output "        DISK SMASHER"
Write-Output "GlobBruh @ tech.beyondgone.xyz"
newSection "BASIC INFORMATION"
getBasicInformation
newSection "STATS - ROOT OF VOLUME"
getVolumeRootStats
newSection "STATS - USER FOLDER"
getUserFolderStats
newSection "CHECK KNOWN PROBLEMATIC LOCATIONS"
checkNoteableLargeFolders
# checkForRemediation