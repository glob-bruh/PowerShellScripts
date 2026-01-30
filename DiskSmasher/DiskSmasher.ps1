<#
.SYNOPSIS
    --------------------------------------
    | DISK SMASHER - Disk Usage Analyzer |
    --------------------------------------
    Tool By: 
        GlobBruh @ tech.beyondgone.xyz
    A script to gather disk usage information and identify large files/folders and potential cleanup targets.
    This script used to be a proprietary internal tool, but has been ethically re-written with extra features and released to the public.

.DESCRIPTION
    This PowerShell script collects and displays various disk usage statistics, including general system information, largest files in specified directories, and sizes of known problematic folders.
    It is designed to help users identify areas where disk space can be reclaimed.
    --------
    LICENSE:
    --------
    The license for this script can be found at the following URL:
    https://github.com/glob-bruh/PowerShellScripts/blob/main/LICENSE

.PARAMETER topLargestFileCount
    Specifies the number of largest files to list in scanned directories.

.PARAMETER oneShotScanPath
    (Optional) Specifies a custom path to perform a one-time scan for large files.

.PARAMETER force
    Bypass system RAM check to allow execution on systems with less than 8 GB of RAM.
    This must be used with caution as it may lead to memory exhaustion.

.INPUTS
    None. This script does not take pipeline input.

.OUTPUTS
    Various disk usage statistics and information printed to the console.

.EXAMPLE
    .\DiskSmasher.ps1 -topLargestFileCount 10
    Runs the script to list the top 10 largest files in specified directories.

.EXAMPLE
    .\DiskSmasher.ps1 -topLargestFileCount 5 -oneShotScanPath "C:\CustomFolder"
    Runs the script to list the top 5 largest files in the specified custom folder.

.LINK
    Homepage: https://tech.beyondgone.xyz
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
        [int]$topLargestFileCount = 15,
    [Parameter(Mandatory=$false)]
        [string]$oneShotScanPath,
        [switch]$force
)

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
    Write-Output "-> Memory Information:"
    write-Output "--> Total Physical Memory (gb): $(numRound($totalRam))."
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

function getFileList($startPath) {
    Write-Verbose "--- Get File List for Path $startPath ---"
    Write-Verbose "Acquiring a list of all files recursively inside $startPath..."
    $returnVar = @()
    $filesInDir = Get-ChildItem -Path $startPath -Recurse -File -Force -ErrorAction SilentlyContinue
    foreach ($File in $filesInDir) {
        $offlineCheck = $File.Attributes -band [System.IO.FileAttributes]::Offline
        $sparseCheck  = $File.Attributes -band [System.IO.FileAttributes]::SparseFile
        if (-not $offlineCheck -and -not $sparseCheck) {
            $returnVar += $File
        }
    }
    Write-Output "Total files found: $($filesInDir.Count). Filter out cloud-only files to calculate actual disk usage..."
    return $returnVar
}

$checkDeceivingFiles = {
    $directoryCheck = $_.PSIsContainer
    $offlineCheck = $_.Attributes -band [System.IO.FileAttributes]::Offline
    $sparseCheck  = $_.Attributes -band [System.IO.FileAttributes]::SparseFile
    $reparseCheck = $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint
    $systemFileCheck  = $_.Attributes -band [System.IO.FileAttributes]::System
    if ($directoryCheck -and $reparseCheck -and $systemFileCheck) { return $false }
    if (-not $directoryCheck) {
        if ($offlineCheck -or $sparseCheck) {
            return $false
        }
        return $true
    }
    return $true # If this is reached, it's a directory that is not a reparse point, so include it.
}

function listLargeFilesInFolders ($path, $fileCount) {
    Write-Output "-> Largest files in $path (top $fileCount):"
    $x = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | 
        Where-Object -FilterScript $checkDeceivingFiles | 
        Where-Object {-not $_.PSIsContainer} | 
        Sort-Object Length -Descending | 
        Select-Object -First $fileCount
    foreach ($i in $x) {
        $size = numRound ($i.Length / 1gb)
        Write-Output "--> $size gb: $($i.FullName)"
    }
}

function getVolumeRootStats () {
    listLargeFilesInFolders "C:\" $topLargestFileCount
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
    listLargeFilesInFolders "C:\Users\" $topLargestFileCount
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
Write-Output "=============================="
$totalRam = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1gb
if ($totalRam -lt 8 -and $PSBoundParameters["force"] -ne $true) {
    Write-Warning "SYSTEM HAS LESS THAN 8 GB OF RAM! Aborting to prevent memory exhaustion."
    exit
}
Write-Output "BASIC INFORMATION:"
getBasicInformation
newSection "STATS - ROOT OF VOLUME"
getVolumeRootStats
newSection "STATS - USER FOLDER"
getUserFolderStats
newSection "CHECK KNOWN PROBLEMATIC LOCATIONS"
checkNoteableLargeFolders
# checkForRemediation