<#
.SYNOPSIS
    Remediation script for Intune Proactive Remediations: re-enables any
    disabled Windows Defender Firewall profile.

.DESCRIPTION
    Runs only when Detect-WindowsFirewallEnabled.ps1 exits 1. Runs as SYSTEM.

    Safety design: only flips the Enabled state back on. Does NOT touch
    existing inbound/outbound rules, so any app-specific exceptions already
    configured (VPN clients, collaboration tools, LOB apps) are preserved —
    this remediation cannot silently break an app that depends on a custom
    firewall rule, because it never modifies rules, only the profile toggle.
    No reboot required; firewall re-enables immediately.
#>

$LogPrefix = "[ZeroTrust-Firewall-Remediation]"

try {
    $Profiles = Get-NetFirewallProfile
    $Disabled = $Profiles | Where-Object { -not $_.Enabled }

    if ($Disabled.Count -eq 0) {
        Write-Output "$LogPrefix Already compliant, nothing to do."
        exit 0
    }

    foreach ($Profile in $Disabled) {
        Set-NetFirewallProfile -Name $Profile.Name -Enabled True
        Write-Output "$LogPrefix Re-enabled firewall profile: $($Profile.Name)"
    }

    exit 0
}
catch {
    Write-Output "$LogPrefix Remediation failed: $($_.Exception.Message)"
    exit 1
}
