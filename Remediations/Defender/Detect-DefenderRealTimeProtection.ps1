<#
.SYNOPSIS
    Detection script for Intune Proactive Remediations: checks Defender
    real-time protection, Tamper Protection, and cloud protection state.

.DESCRIPTION
    Exit 0 = compliant. Exit 1 = non-compliant, triggers the remediation script.
    Read-only. Runs as SYSTEM.
#>

try {
    $Status = Get-MpComputerStatus -ErrorAction Stop

    $Failures = [System.Collections.Generic.List[string]]::new()

    if (-not $Status.RealTimeProtectionEnabled) { $Failures.Add("RealTimeProtectionEnabled=False") }
    if (-not $Status.IsTamperProtected)         { $Failures.Add("IsTamperProtected=False") }
    if (-not $Status.AMServiceEnabled)          { $Failures.Add("AMServiceEnabled=False") }

    if ($Failures.Count -eq 0) {
        Write-Output "Compliant: real-time protection, tamper protection, and AM service are all enabled."
        exit 0
    }

    Write-Output "Non-compliant: $($Failures -join '; ')"
    exit 1
}
catch {
    Write-Output "Non-compliant: unable to query Defender status - $($_.Exception.Message)"
    exit 1
}
