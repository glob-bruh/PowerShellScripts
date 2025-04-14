######################
# DISKSMASHER
# --------------------
# Fully automatic disk search designed to point out reasons 
# behind large disk usage. 
# --------------------
# Created by GlobBruh
######################

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
    Write-Output "--> Current Domain/User: $curUser. [] Uptime: S:$upTmS M:$upTmM H:$upTmH D:$upTmD."
    $x = Get-PSDrive -Name "C"
    $usedSpace =  numRound ($x.Used / 1gb)
    $freeSpace =  numRound ($x.Free / 1gb)
    $totalSpace = $usedSpace + $freeSpace
    $percUsed = numRound (($usedSpace / $totalSpace) * 100)
    $percFree = numRound (($freeSpace / $totalSpace) * 100)
    Write-Output "-> Disk Usage:"
    Write-Output "--> Total (gb): $totalSpace. [] Used/Free (gb): $usedSpace/$freeSpace. [] Used/Free (%): $percUsed/$percFree."
}

function listLargeFilesInFolders ($path, $fileCount) {
    Write-Output "-> Largest files in $path (top $fileCount):"
    $x = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Sort-Object Length | Select-Object -Last $fileCount)
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

function newSection ($sectionTxt) {
    Write-Output "==============", ($sectionTxt + ":")
}

Write-Output "=============="
Write-Output "DISK SMASHER"
newSection "BASIC INFORMATION"
getBasicInformation
newSection "STATS - ROOT OF VOLUME"
getVolumeRootStats
newSection "STATS - USER FOLDER"
getUserFolderStats
# checkNoteableLargeFolders
# checkForRemediation