<#
.SYNOPSIS
    Deploys a Settings Catalog policy JSON from this repo to Intune via
    Microsoft Graph, with a pre-flight schema validation pass.

.DESCRIPTION
    Safety-first by design:
      1. Validates every settingDefinitionId in the JSON against your
         tenant's actual current Settings Catalog before creating anything.
         A stale/renamed setting ID fails loudly here instead of silently
         creating a broken or partial policy.
      2. Defaults to -WhatIf (dry run) — you must pass -Confirm to actually
         create the policy in your tenant.
      3. Never assigns the policy to a group as part of this script. Creation
         and assignment are deliberately separate steps (see
         New-PersonaAssignment.ps1) so a newly created policy never
         auto-applies to production devices.

.PARAMETER PolicyPath
    Path to a policy JSON file under Policies/L1 or Policies/L2.

.PARAMETER Confirm
    Actually create the policy. Without this switch, the script only
    validates and reports what it would do.

.EXAMPLE
    ./Deploy-IntunePolicy.ps1 -PolicyPath ../Policies/L1/BitLocker-Baseline.json
    # Dry run: validates schema, shows what would be created, creates nothing.

.EXAMPLE
    ./Deploy-IntunePolicy.ps1 -PolicyPath ../Policies/L1/BitLocker-Baseline.json -Confirm
    # Actually creates the policy in Intune (unassigned).
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$PolicyPath,

    [Parameter(Mandatory = $false)]
    [switch]$Confirm
)

if (-not (Get-MgContext)) {
    throw "Not connected to Microsoft Graph. Run ./Connect-ZeroTrustTenant.ps1 first."
}

if (-not (Test-Path $PolicyPath)) {
    throw "Policy file not found: $PolicyPath"
}

$RawJson = Get-Content -Path $PolicyPath -Raw | ConvertFrom-Json
$Metadata = $RawJson._metadata

Write-Host "=== $($Metadata.name) ===" -ForegroundColor Cyan
Write-Host "Tier: $($Metadata.tier) | Personas: $($Metadata.personas -join ', ')"
Write-Host "CIS mapping: $($Metadata.cisMapping)"
Write-Host ""

# Strip _metadata before building the actual Graph payload — it's documentation, not schema.
$Payload = $RawJson | Select-Object -Property * -ExcludeProperty _metadata

# --- Pre-flight schema validation ---
Write-Host "Validating setting definition IDs against tenant catalog..." -ForegroundColor Yellow

function Get-SettingDefinitionIds {
    param($Node)
    $Ids = [System.Collections.Generic.List[string]]::new()
    if ($Node.settingInstance) {
        if ($Node.settingInstance.settingDefinitionId) {
            $Ids.Add($Node.settingInstance.settingDefinitionId)
        }
        if ($Node.settingInstance.groupSettingCollectionValue) {
            foreach ($Group in $Node.settingInstance.groupSettingCollectionValue) {
                foreach ($Child in $Group.children) {
                    if ($Child.settingDefinitionId) { $Ids.Add($Child.settingDefinitionId) }
                }
            }
        }
    }
    return $Ids
}

$AllIds = [System.Collections.Generic.List[string]]::new()
foreach ($Setting in $Payload.settings) {
    ($AllIds).AddRange([string[]](Get-SettingDefinitionIds -Node $Setting))
}

$MissingIds = [System.Collections.Generic.List[string]]::new()
foreach ($Id in $AllIds) {
    try {
        $null = Get-MgDeviceManagementConfigurationSettingDefinition -ConfigurationSettingDefinitionId $Id -ErrorAction Stop
    }
    catch {
        $MissingIds.Add($Id)
    }
}

if ($MissingIds.Count -gt 0) {
    Write-Host "VALIDATION FAILED — the following setting IDs were not found in your tenant's current catalog:" -ForegroundColor Red
    $MissingIds | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "This usually means Microsoft has renamed/versioned this setting since this repo's JSON was written." -ForegroundColor Yellow
    Write-Host "Search the current name via: Get-MgDeviceManagementConfigurationSettingDefinition -Filter `"contains(displayName,'<keyword>')`"" -ForegroundColor Yellow
    throw "Aborting: fix setting IDs before deploying."
}

Write-Host "All $($AllIds.Count) setting definition(s) validated OK." -ForegroundColor Green
Write-Host ""

if (-not $Confirm) {
    Write-Host "Dry run only (no -Confirm passed). Would create policy '$($Payload.name)' with $($Payload.settings.Count) setting(s). Nothing was changed in your tenant." -ForegroundColor Yellow
    return
}

Write-Host "Creating policy in Intune (unassigned — use New-PersonaAssignment.ps1 to assign)..." -ForegroundColor Cyan

$Body = $Payload | ConvertTo-Json -Depth 10
$Result = Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies" `
    -Body $Body -ContentType "application/json"

Write-Host "Created policy: $($Result.name) (id: $($Result.id))" -ForegroundColor Green
Write-Host "Next: run New-PersonaAssignment.ps1 to assign this policy to a persona's Entra group."
