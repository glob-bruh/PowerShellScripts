#############################
#         PRO365ER          #
# ------------------------- #
# GLOBBRUH MS ENTRA MANAGER #
#############################

function passwordGenerator () {
    $txtPfx = "[PASS GEN]" 
    $length = [int](Read-Host "$txtPfx Length")
    $symbNum = [int](Read-Host "$txtPfx Number of symbols")
    Add-Type -AssemblyName System.Web
    return [System.Web.Security.Membership]::GeneratePassword($length, $symbNum)
}

function checkImportGraph () {
    if ("Microsoft.Graph.Users" -notin (Get-Module).Name) {
        Write-Output "MS Graph not imported. Importing..."
        $maximumfunctioncount = "32768"
        Import-Module -Name Microsoft.Graph
        Write-Output "MS Graph Imported!"
    }
}

function connectGraph () {
    Write-Output "--- CONNECT TO TENANT ---"
    Write-Output "1) Authenticate with SIGNIN"
    Write-Output "2) Authenticate with SECRET (requires SECRET.json)"
    $sel = Read-Host "Choice"
    Write-Output "Connect to tenant..."
    switch ($sel) {
        "1" {
            Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All" -NoWelcome -ErrorAction SilentlyContinue
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
    Write-Output "", "---", "USERS:", "---"
    Write-Output (Get-MgUser).DisplayName, "---"
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
    }
}

function shutdownAndExitTenant () {
    Write-Output "Disconnect from tenant..."
    Disconnect-Graph
}

Write-Output "-----------------------------------------"
Write-Output "PRO           GLOBBRUH CLOUD PROJECT"
Write-Output "    365"
Write-Output "        ER"
Write-Output "-----------------------------------------"
Write-Output "WARNING:"
Write-Output "Please read license before using!"
Write-Output "-----------------------------------------"

checkImportGraph
connectGraph

while ($curActive -ne 0) {
    $name = (Get-MgContext).Account
    if ( $name -eq $null ) { $name = "User" }
    Write-Output "", "=== WELCOME $name! ==="
    Write-Output "1) User Managment"
    Write-Output "2) EXIT"
    Write-Output "=========="
    $sel = Read-Host "Choice"
    switch ($sel) {
        "1" { userManageFunc }
        "2" { shutdownAndExitTenant ; $curActive = 0 }
        default { Write-Output "Not a valid selection." }
    }
}