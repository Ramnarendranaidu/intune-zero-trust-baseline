<#
.SYNOPSIS
    Authenticates to Microsoft Graph with the scopes this repo's scripts need.

.DESCRIPTION
    Thin wrapper around Connect-MgGraph so every script in this repo
    authenticates consistently. Requires the Microsoft.Graph.Authentication,
    Microsoft.Graph.DeviceManagement, and Microsoft.Graph.Groups modules.

.PARAMETER TenantId
    Your Entra ID tenant ID or verified domain (e.g. "contoso.onmicrosoft.com").
    Omit to use the interactive account picker.

.EXAMPLE
    ./Connect-ZeroTrustTenant.ps1 -TenantId "contoso.onmicrosoft.com"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId
)

$RequiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.DeviceManagement',
    'Microsoft.Graph.Groups'
)

foreach ($Module in $RequiredModules) {
    if (-not (Get-Module -Name $Module -ListAvailable)) {
        Write-Host "Installing missing module: $Module" -ForegroundColor Yellow
        Install-Module -Name $Module -Scope CurrentUser -Force
    }
}

$Scopes = @(
    'DeviceManagementConfiguration.ReadWrite.All',
    'DeviceManagementManagedDevices.Read.All',
    'Group.Read.All',
    'GroupMember.Read.All'
)

$ConnectParams = @{ Scopes = $Scopes }
if ($TenantId) { $ConnectParams['TenantId'] = $TenantId }

Connect-MgGraph @ConnectParams

$Context = Get-MgContext
Write-Host "Connected to tenant: $($Context.TenantId) as $($Context.Account)" -ForegroundColor Green
Write-Host "Granted scopes: $($Context.Scopes -join ', ')"
