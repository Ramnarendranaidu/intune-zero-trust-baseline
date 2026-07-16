<#
.SYNOPSIS
    Reads Attack Surface Reduction audit-mode hits from the local event log,
    for use during the L1→L2 validation window before promoting ASR rules
    from Audit to Block.

.DESCRIPTION
    Not a detect/remediate pair — this is a reporting-only script, meant to
    run on a schedule (or via Proactive Remediation's detection-script-only
    mode) and feed results into Reporting/Get-ZeroTrustComplianceReport.ps1
    or a Log Analytics workspace.

    Event ID 1121 = ASR rule blocked (Block mode)
    Event ID 1122 = ASR rule audited, would have blocked (Audit mode)

    A device with zero 1122 events over the validation window is a strong
    signal that Block mode is safe for that device/persona. Devices with
    frequent hits need investigation (legitimate workflow needing an
    exclusion, vs. actual malicious activity) before their persona is
    promoted to L2 Block mode.
#>

param(
    [Parameter(Mandatory = $false)]
    [int]$LookbackDays = 14
)

$LogName = 'Microsoft-Windows-Windows Defender/Operational'
$StartTime = (Get-Date).AddDays(-1 * $LookbackDays)

try {
    $Events = Get-WinEvent -FilterHashtable @{
        LogName   = $LogName
        Id        = 1121, 1122
        StartTime = $StartTime
    } -ErrorAction Stop

    $Summary = $Events | Group-Object Id | ForEach-Object {
        [PSCustomObject]@{
            EventId       = $_.Name
            Mode          = if ($_.Name -eq '1121') { 'Block' } else { 'Audit (would-have-blocked)' }
            HitCount      = $_.Count
        }
    }

    [PSCustomObject]@{
        DeviceName      = $env:COMPUTERNAME
        LookbackDays    = $LookbackDays
        TotalAuditHits  = ($Events | Where-Object Id -eq 1122).Count
        TotalBlockHits  = ($Events | Where-Object Id -eq 1121).Count
        ReadyForL2Block = ($Events | Where-Object Id -eq 1122).Count -eq 0
        Detail          = $Summary
    } | ConvertTo-Json -Depth 4
}
catch [System.Exception] {
    if ($_.Exception -is [System.Diagnostics.Eventing.Reader.EventLogNotFoundException] -or
        $_.CategoryInfo.Category -eq 'ObjectNotFound') {
        # No matching events is a valid (good) outcome, not a script failure.
        [PSCustomObject]@{
            DeviceName      = $env:COMPUTERNAME
            LookbackDays    = $LookbackDays
            TotalAuditHits  = 0
            TotalBlockHits  = 0
            ReadyForL2Block = $true
            Detail          = @()
        } | ConvertTo-Json -Depth 4
    }
    else {
        Write-Error "Failed to read ASR event log: $($_.Exception.Message)"
        exit 1
    }
}
