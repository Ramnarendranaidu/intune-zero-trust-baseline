<#
.SYNOPSIS
    Detection script for Intune Proactive Remediations: checks that Windows
    Defender Firewall is enabled on all three profiles.

.DESCRIPTION
    Exit 0 = compliant. Exit 1 = non-compliant, triggers remediation.
    Read-only. Runs as SYSTEM.
#>

try {
    $Profiles = Get-NetFirewallProfile -ErrorAction Stop
    $Disabled = $Profiles | Where-Object { -not $_.Enabled }

    if ($Disabled.Count -eq 0) {
        Write-Output "Compliant: Domain, Private, and Public firewall profiles are all enabled."
        exit 0
    }

    Write-Output "Non-compliant: disabled profile(s): $($Disabled.Name -join ', ')"
    exit 1
}
catch {
    Write-Output "Non-compliant: unable to query firewall profiles - $($_.Exception.Message)"
    exit 1
}
