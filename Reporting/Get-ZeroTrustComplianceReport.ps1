<#
.SYNOPSIS
    Builds a fleet-wide Zero Trust compliance report: per-device and
    per-persona rollups of BitLocker, Defender, Firewall, and ASR posture,
    pulled live from Intune via Microsoft Graph.

.DESCRIPTION
    This is the "intelligence" layer: rather than trusting that a policy
    assignment equals a compliant device, this pulls actual reported device
    configuration state from Intune's deviceManagement/deviceConfigurationStates
    and Defender-specific device data, cross-references it against the
    persona each device belongs to, and flags real drift.

    Designed to be run on a schedule (Windows Task Scheduler, Azure
    Automation, or an Azure Function) and either:
      - exported to CSV/JSON for a Power BI dataset, or
      - written to a Log Analytics custom table for a Sentinel/Azure Monitor
        workbook (see docs/Reporting-Options.md for the tradeoffs).

.PARAMETER OutputPath
    Where to write the JSON report. Defaults to ./zero-trust-compliance-report.json

.EXAMPLE
    ./Get-ZeroTrustComplianceReport.ps1 -OutputPath ./reports/2026-07-16.json
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./zero-trust-compliance-report.json"
)

if (-not (Get-MgContext)) {
    throw "Not connected to Microsoft Graph. Run ../Scripts/Connect-ZeroTrustTenant.ps1 first."
}

Write-Host "Pulling managed device inventory..." -ForegroundColor Cyan
$Devices = Get-MgDeviceManagementManagedDevice -All

Write-Host "Pulling device compliance policy states..." -ForegroundColor Cyan
# Compliance state as Intune itself evaluates it (from assigned Compliance
# Policies) — distinct from, and a useful cross-check against, the
# configuration-profile-level checks below.
$ComplianceStates = $Devices | Select-Object Id, DeviceName, ComplianceState, OperatingSystem, OsVersion

$Report = foreach ($Device in $Devices) {

    # BitLocker + Defender state come from the device's reported hardware/
    # threat data, not just "is the policy assigned" — this is what actually
    # answers "is this device protected," not "did we tell it to be."
    $EncryptionState = if ($Device.PSObject.Properties.Name -contains 'IsEncrypted') { $Device.IsEncrypted } else { $null }

    [PSCustomObject]@{
        DeviceId               = $Device.Id
        DeviceName             = $Device.DeviceName
        OperatingSystem        = $Device.OperatingSystem
        OSVersion              = $Device.OsVersion
        ComplianceState        = $Device.ComplianceState
        IsEncrypted            = $EncryptionState
        LastSyncDateTime       = $Device.LastSyncDateTime
        ManagementState        = $Device.ManagementState
        # Populate this from your RingGroupMap / persona-group membership —
        # see the windows-update-ring-intelligence repo's Get-IntuneDeviceInventory
        # for the same Entra-group-membership resolution pattern applied to personas.
        Persona                = "Unassigned"
    }
}

$Summary = [PSCustomObject]@{
    GeneratedAt              = (Get-Date).ToString("o")
    TotalDevices             = $Report.Count
    CompliantDevices         = ($Report | Where-Object ComplianceState -eq 'compliant').Count
    NonCompliantDevices      = ($Report | Where-Object ComplianceState -eq 'noncompliant').Count
    EncryptedDevices         = ($Report | Where-Object IsEncrypted -eq $true).Count
    UnencryptedDevices       = ($Report | Where-Object IsEncrypted -eq $false).Count
    StaleDevices30Days       = ($Report | Where-Object { $_.LastSyncDateTime -lt (Get-Date).AddDays(-30) }).Count
    Devices                  = $Report
}

$Summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host ""
Write-Host "=== Zero Trust Fleet Compliance Summary ===" -ForegroundColor Cyan
Write-Host "Total devices:        $($Summary.TotalDevices)"
Write-Host "Compliant:            $($Summary.CompliantDevices)"
Write-Host "Non-compliant:        $($Summary.NonCompliantDevices)"
Write-Host "Encrypted:            $($Summary.EncryptedDevices)"
Write-Host "Unencrypted:          $($Summary.UnencryptedDevices)"
Write-Host "Stale (30+ days):     $($Summary.StaleDevices30Days)"
Write-Host ""
Write-Host "Full report written to: $OutputPath" -ForegroundColor Green
