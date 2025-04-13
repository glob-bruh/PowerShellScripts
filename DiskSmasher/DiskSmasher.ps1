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

function listLargeFilesInFolders ($inDir) {
    Write-Output "not yet"
}

function newSection ($sectionTxt) {
    Write-Output "==============", ($sectionTxt + ":")
}

Write-Output "=============="
Write-Output "DISK SMASHER"
newSection "BASIC INFORMATION"
getBasicInformation
# getVolumeRootStats
# getUserFolderStats
# checkNoteableLargeFolders
# checkForRemediation