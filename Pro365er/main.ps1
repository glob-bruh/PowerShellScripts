#############################
#         PRO365ER          #
# ------------------------- #
# GLOBBRUH MS ENTRA MANAGER #
#############################

function passwordGenerator () {
    # NOT IMPLEMENTED
    $pass = 1234
    return $pass
}

function checkImportGraph () {
    if ("Microsoft.Graph.Users" -notin (Get-Module).Name) {
        Write-Output "MS Graph not imported. Importing..."
        $maximumfunctioncount = "39999"
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
            if ($?) { Write-Output "CONNECTED TO TENANT!" }
            else { Write-Output "CONNECT FAILED!" }
        }
        "2" {
            $x = Get-Content -Raw "SECRET.json" | ConvertFrom-Json
            $y = ConvertTo-SecureString -AsPlainText -Force ($x.SECRET)
            $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($x.CLIENT, $y)
            Connect-MgGraph -TenantId $x.TENANT -ClientSecretCredential $cred -NoWelcome -ErrorAction SilentlyContinue
            if ($?) { Write-Output "CONNECTED TO TENANT!" }
            else { Write-Output "CONNECT FAILED!" }
        }
    }
}

function userManageFunc () {
    Write-Output "", "---", "USERS:", "---"
    Write-Output (Get-MgUser).DisplayName
    Write-Output "1) Add User"
    Write-Output "2) Delete User"
    Write-Output "3) Exit"
    $sel = Read-Host "Choice" ; switch ($sel) {
        "1" {
            $nameF = Read-Host "[NEW USER] First name"
            $nameL = Read-Host "[NEW USER]  Last name"
            $dispName =  $nameF + " " + $nameL
            $passwd = passwordGenerator
            Write-Output "", "NEW USER CONFROMATION:"
            Write-Output "Name: $dispName"
            New-MgUser -GivenName $nameF -Surname $nameL -DisplayName ($dispName)
        }
    }
}

function shutdownAndExitTenant () {
    Disconnect-Graph
}

Write-Output "---------------------------------"
Write-Output "PRO                GLOBBRUH"
Write-Output "    365            CLOUD"
Write-Output "        ER         PROJECT"
Write-Output "---------------------------------"
Write-Output "WARNING:"
Write-Output "Please read license before using!"
Write-Output "---------------------------------"

checkImportGraph
connectGraph

while ($curActive -ne 0) {
    $name = (Get-MgContext).Account
    if ( $name -eq $null ) { $name = "User" }
    Write-Output "", "=== WELCOME $name! ==="
    Write-Output "1) User Managment"
    Write-Output "2) EXIT"
    Write-Output "=========="
    $sel = Read-Host "Choice" ; switch ($sel) {
        "1" { userManageFunc }
        "2" { shutdownAndExitTenant ; $curActive = 0 }
        default { Write-Output "Not a valid selection." }
    }
}