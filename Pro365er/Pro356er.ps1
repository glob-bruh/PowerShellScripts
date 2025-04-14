#############################
#         PRO365ER          #
# ------------------------- #
# GLOBBRUH MS ENTRA MANAGER #
#############################

function lineBreaks ($style) {
    switch ($style) {
        "#"   {Write-Output "================================================================"}
        "##"  {Write-Output "----------------------------------------------------------------"}
        "###" {Write-Output "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "}
    }
}

function searchParser ($inVar) {
    $txtPfx = "[SEARCH]"
    $term = Read-Host "$txtPfx Enter search term"
    lineBreaks "###" ; Write-Output "SEARCH RESULTS:"
    $itemInLine = 0 ; $targStr = ""
    foreach ($x in $inVar) {
        if ($x -like "*$term*") {
            if ($itemInLine -eq 2) {
                Write-Output ($targStr + $x)
                $targStr = "" ; $itemInLine = 0
            } else {
                $targStr += "$x [] " ; $itemInLine += 1
            }
        }
    }
    Write-Output $targStr
    lineBreaks "###"
}

function passwordGenerator () {
    $txtPfx = "[PASS GEN]" 
    $length = [int](Read-Host "$txtPfx Length")
    $symbNum = [int](Read-Host "$txtPfx Number of symbols")
    Add-Type -AssemblyName System.Web
    return [System.Web.Security.Membership]::GeneratePassword($length, $symbNum)
}

function checkImportGraph ($skipCheck) {
    if (("Microsoft.Graph.Users" -notin (Get-Module).Name) -or ($skipCheck -eq $true)) {
        if (-not (Get-Module -ListAvailable -Name "Microsoft.Graph")) {
            Write-Output "MS Graph is not installed! It's required to run this script!"
            $sel = Read-Host "Install MS Graph (Y/n)" ; if ($sel -like "y") {
                Write-Output "Installing MS Graph..." 
                Install-Module -Name "Microsoft.Graph"
                Write-Output "MS Graph installed."
            }
        }
        Write-Output "MS Graph not imported. Importing..."
        $maximumfunctioncount = "32768"
        Import-Module -Name Microsoft.Graph -Force
        Write-Output "MS Graph Imported!"
    }
}

function connectGraph () {
    Write-Output "--- CONNECT TO TENANT ---"
    Write-Output "1) Authenticate with SIGNIN"
    Write-Output "2) Authenticate with SECRET (requires SECRET.json)"
    $sel = Read-Host "Choice"
    Write-Output "Connect to tenant..."
    $scopes = "User.ReadWrite.All", "Group.ReadWrite.All", "Domain.ReadWrite.All"
    switch ($sel) {
        "1" {
            Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction SilentlyContinue
            if ($?) { Write-Output "CONNECTED TO TENANT!" } else { Write-Output "CONNECT FAILED!" }
        }
        "2" {
            $x = Get-Content -Raw "SECRET.json" | ConvertFrom-Json
            $y = ConvertTo-SecureString -AsPlainText -Force ($x.SECRET)
            $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($x.CLIENT, $y)
            Connect-MgGraph -TenantId $x.TENANT -ClientSecretCredential $cred -NoWelcome -ErrorAction SilentlyContinue
            if ($?) { Write-Output "CONNECTED TO TENANT!" } else { Write-Output "CONNECT FAILED!" }
        }
    }
}

function userManageFunc () {
    Write-Output "Get user list..."
    $usersList = Get-MgUser
    Write-Output "" ; lineBreaks "##" ; Write-Output "USERS:" ; lineBreaks "##"
    Write-Output $usersList.DisplayName ; lineBreaks "##"
    Write-Output "Please enter the name of the user you want to manage or select an option:"
    Write-Output "SEARCH will let you search for a user."
    Write-Output "1) Add User", "2) User License Managment", "3) Delete User", "4) Exit"
    $sel = Read-Host "Choice" ; switch ($sel) {
        "1" {
            $txtPfx = "[NEW USER]" 
            $nameF = Read-Host "$txtPfx First name"
            $nameL = Read-Host "$txtPfx Last name"
            $dispName =  $nameF + " " + $nameL
            $emailName = Read-Host "$txtPfx Email Name"
            $domains = Get-MgDomain ; foreach ($x in $domains) {
                if ($x.IsDefault -eq $true) { $domain = $x.Id }
            }
            Write-Output "Default domain is: $domain."
            $sel = Read-Host "$txtPfx Do you want to use this domain (Y/n)" ; if ($sel -like "n") {
                Write-Output "", "DOMAINS:", $domains.Id, ""
                $domain = Read-Host "$txtPfx Type in the domain to use"
            }
            $upn = $emailName + "@" + $domain
            $sel = Read-Host "$txtPfx Password (enter GEN to generate one)" ; if ($sel -eq "GEN") {
                write-output "Will generate password..."
                $passwd = passwordGenerator
            } else { $passwd = $sel }
            $passProf = @{ Password = (ConvertTo-SecureString -AsPlainText -Force $passwd) }
            Write-Output "", "NEW USER CONFROMATION:", "Name: $dispName", "Email/UPN: $upn", "Password: $passwd", ""
            $sel = Read-Host "$txtPfx Proceed with account creation (Y/n)" ; if ($sel -like "y") {
                Write-Output "Create new user..."
                $out = New-MgUser -GivenName $nameF -Surname $nameL -DisplayName $dispName -PasswordProfile $passProf `
                    -AccountEnabled -MailNickname $emailName -UserPrincipalName $upn
                Write-Output "New user created (ID: $($out.Id))."
            }
        }
        "SEARCH" {searchParser $usersList.DisplayName}
        default {
            if ($sel -in $usersList.DisplayName) {
                $userInfo = ($usersList | Where-Object {$_.DisplayName -eq $sel})
                lineBreaks "##"
                Write-Output "USER INFORMATION:", "NAME - $($userInfo.DisplayName)", "ID - $($userInfo.Id)" `
                    "UPN - $($userInfo.UserPrincipalName)", "ABOUT - $($userInfo.AboutMe)" `
                    "LICENSES - $($userInfo.AssignedLicenses)", "ACC ENABLED - $($userInfo.AccountEnabled)"
                lineBreaks "##"
                Write-Output "1) Manage License", "2) Disable User", "3) Exit"
            }
        }
    }
}

function shutdownAndExitTenant () {
    Write-Output "Disconnect from tenant..."
    $out = Disconnect-Graph
    Write-Output "Disconnected from tenant $($out.TenantId)."
}

lineBreaks "#"
Write-Output "PRO           GLOBBRUH CLOUD PROJECT"
Write-Output "    365"
Write-Output "        ER"
lineBreaks "#"
Write-Output "WARNING:"
Write-Output "Please read license before using!"
lineBreaks "#"

checkImportGraph $false
connectGraph

$curActive = 1 ; while ($curActive -ne 0) {
    $name = (Get-MgContext).Account
    if ( $name -eq $null ) { $name = "User" }
    Write-Output "=== WELCOME $name! ==="
    Write-Output "1) User Managment", "2) Force-reimport of MSGraph", "3) EXIT"
    Write-Output "=========="
    $sel = Read-Host "Choice"
    switch ($sel) {
        1 { userManageFunc }
        2 { checkImportGraph $true }
        3 { shutdownAndExitTenant ; $curActive = 0 }
        default { Write-Output "Not a valid selection." }
    }
}