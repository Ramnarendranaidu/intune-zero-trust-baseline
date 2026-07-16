<#
.SYNOPSIS
    Assigns an existing Intune Settings Catalog policy to a persona's Entra
    ID security group.

.DESCRIPTION
    Deliberately a separate step from Deploy-IntunePolicy.ps1 — creating a
    policy never auto-assigns it, so nothing reaches a real device without
    this explicit, logged, one-persona-at-a-time step.

    Loads persona metadata from Config/Personas/*.psd1 so the EntraSecurityGroup
    and ComplianceTier are always driven by that single source of truth
    rather than typed inline each time.

.PARAMETER PolicyId
    The Intune policy ID (from Deploy-IntunePolicy.ps1's output).

.PARAMETER PersonaName
    One of: StandardUser, PrivilegedAdmin, KioskSharedDevice — matches a
    file under Config/Personas/.

.EXAMPLE
    ./New-PersonaAssignment.ps1 -PolicyId "00000000-...." -PersonaName PrivilegedAdmin
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$PolicyId,

    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'StandardUser', 'PrivilegedAdmin', 'KioskSharedDevice',
        'Developer', 'CallCenterAgent', 'ServiceDesk', 'Finance', 'Marketing'
    )]
    [string]$PersonaName
)

if (-not (Get-MgContext)) {
    throw "Not connected to Microsoft Graph. Run ./Connect-ZeroTrustTenant.ps1 first."
}

$PersonaPath = Join-Path -Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'Config/Personas') -ChildPath "$PersonaName.psd1"
if (-not (Test-Path $PersonaPath)) {
    throw "Persona definition not found: $PersonaPath"
}

$Persona = Import-PowerShellDataFile -Path $PersonaPath
Write-Host "Persona: $($Persona.PersonaName) — $($Persona.Description)"
Write-Host "Target Entra group (placeholder name in repo): $($Persona.EntraSecurityGroup)"
Write-Host ""
Write-Host "NOTE: $($Persona.EntraSecurityGroup) is a placeholder name — replace it in the persona .psd1 with your real Entra group Object ID before running this for real." -ForegroundColor Yellow

$GroupId = $Persona.EntraSecurityGroup
# If a real Object ID (GUID) hasn't been substituted in, resolve by display name instead.
if ($GroupId -notmatch '^[0-9a-fA-F-]{36}$') {
    $Group = Get-MgGroup -Filter "displayName eq '$GroupId'" -ErrorAction SilentlyContinue
    if (-not $Group) {
        throw "Could not resolve Entra group '$GroupId' by display name, and it isn't a GUID. Create the group first or update the persona file with the correct name/ID."
    }
    $GroupId = $Group.Id
}

$AssignmentBody = @{
    assignments = @(
        @{
            target = @{
                "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                groupId       = $GroupId
            }
        }
    )
} | ConvertTo-Json -Depth 5

Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$PolicyId/assign" `
    -Body $AssignmentBody -ContentType "application/json"

Write-Host "Assigned policy $PolicyId to persona '$PersonaName' (group $GroupId)." -ForegroundColor Green
Write-Host "Update ring for this persona: $($Persona.UpdateRing) — cross-reference with the windows-update-ring-intelligence repo for rollout pacing."
