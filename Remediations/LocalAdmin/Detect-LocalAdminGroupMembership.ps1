<#
.SYNOPSIS
    Detection script for Intune Proactive Remediations: flags local
    Administrators group membership that isn't on an approved allow-list.

.DESCRIPTION
    Exit 0 = compliant (only allow-listed accounts are local admins).
    Exit 1 = non-compliant (an unexpected account has local admin rights).
    Read-only. Runs as SYSTEM.

    The allow-list always includes the built-in Administrator account (SID
    ending in -500) and any LAPS-managed local account, since those are
    expected and required for device recovery — this script does NOT flag
    them, and the paired remediation script will never remove them.

    Edit $ApprovedGroups / $ApprovedUsers below to match your environment
    (e.g. your Entra ID device-admins group, an approved break-glass account).
#>

# --- Configure for your environment ---
$ApprovedGroups = @('Domain Admins', 'AAD DC Administrators')  # groups whose members are OK to be local admin
$ApprovedUserPatterns = @('*-LAPSAdmin')                        # wildcard patterns for individually-approved local accounts
# ---------------------------------------

try {
    $AdminGroup = Get-LocalGroup -Name 'Administrators' -ErrorAction Stop
    $Members = Get-LocalGroupMember -Group $AdminGroup -ErrorAction Stop

    $Unexpected = foreach ($Member in $Members) {
        # Always allow the built-in Administrator account (RID 500).
        if ($Member.SID -like '*-500') { continue }

        # Allow approved domain/Entra groups.
        if ($Member.ObjectClass -eq 'Group' -and $Member.Name -in $ApprovedGroups) { continue }

        # Allow approved local account name patterns (e.g. LAPS-managed).
        $IsApprovedPattern = $false
        foreach ($Pattern in $ApprovedUserPatterns) {
            if ($Member.Name -like $Pattern) { $IsApprovedPattern = $true; break }
        }
        if ($IsApprovedPattern) { continue }

        $Member
    }

    if (-not $Unexpected) {
        Write-Output "Compliant: local Administrators group membership matches the approved allow-list."
        exit 0
    }

    Write-Output "Non-compliant: unexpected local admin member(s): $($Unexpected.Name -join ', ')"
    exit 1
}
catch {
    Write-Output "Non-compliant: unable to enumerate local Administrators group - $($_.Exception.Message)"
    exit 1
}
