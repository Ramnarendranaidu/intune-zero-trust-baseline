<#
.SYNOPSIS
    Remediation script for Intune Proactive Remediations: re-enables Defender
    real-time protection and the AM service if disabled.

.DESCRIPTION
    Runs only when Detect-DefenderRealTimeProtection.ps1 exits 1. Runs as SYSTEM.

    Important honesty note: Tamper Protection specifically CANNOT be turned on
    from a local script by design — that's the entire point of Tamper
    Protection (it blocks local/registry/PowerShell changes to Defender
    settings, including re-enabling itself). If Tamper Protection is off,
    this script logs it as a finding for the Endpoint Security team to
    investigate (it typically means the device isn't receiving the
    ZeroTrust-L1-DefenderAV-Baseline policy, or Defender is misconfigured/
    third-party AV is present) rather than pretending to fix something a
    script structurally cannot fix.

    No reboot, no user-visible prompt for the parts this script can remediate.
#>

$LogPrefix = "[ZeroTrust-Defender-Remediation]"

try {
    $Status = Get-MpComputerStatus -ErrorAction Stop
    $ActionsTaken = [System.Collections.Generic.List[string]]::new()

    if (-not $Status.RealTimeProtectionEnabled) {
        Set-MpPreference -DisableRealtimeMonitoring $false
        $ActionsTaken.Add("Re-enabled real-time monitoring")
    }

    if (-not $Status.AMServiceEnabled) {
        Start-Service -Name WinDefend -ErrorAction SilentlyContinue
        $ActionsTaken.Add("Started WinDefend service")
    }

    if (-not $Status.IsTamperProtected) {
        Write-Output "$LogPrefix Tamper Protection is off — this cannot be remediated by a local script by design. Flagging for Endpoint Security review: check that ZeroTrust-L1-DefenderAV-Baseline is assigned to this device, and confirm no third-party AV is interfering."
    }

    if ($ActionsTaken.Count -gt 0) {
        Write-Output "$LogPrefix Actions taken: $($ActionsTaken -join '; ')"
    }
    else {
        Write-Output "$LogPrefix No locally-remediable issues found (remaining gap, if any, is Tamper Protection — see above)."
    }

    exit 0
}
catch {
    Write-Output "$LogPrefix Remediation failed: $($_.Exception.Message)"
    exit 1
}
