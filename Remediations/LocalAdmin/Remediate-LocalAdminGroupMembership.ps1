<#
.SYNOPSIS
    Remediation script for local Administrators group drift — REPORT-ONLY
    by default, because auto-removing someone's admin rights is the single
    highest-risk-of-user-impact action in this whole repo.

.DESCRIPTION
    Runs when Detect-LocalAdminGroupMembership.ps1 exits 1. Runs as SYSTEM.

    By design this script does NOT remove anyone by default. Silently
    stripping local admin from a user or service account that has a
    legitimate (if undocumented) reason for it is exactly the kind of
    "function break" this whole project was asked to avoid. Instead it:

      1. Writes a structured finding to the Intune remediation output (visible
         in the Intune admin center per-device remediation results) and to a
         local event log entry, so IT sees exactly who was flagged and when.
      2. Only performs the actual removal if $AutoRemediate is explicitly set
         to $true below AND the account is on $ForceRemoveAllowList — i.e.
         you've deliberately decided this specific account should never be
         locally admin and want it enforced automatically.

    Recommended rollout: leave $AutoRemediate = $false for at least one full
    reporting cycle, review flagged accounts with the affected teams, THEN
    turn on auto-remediation only for accounts you've confirmed are safe to
    strip automatically (e.g. departed-employee leftover accounts, not
    active staff who might be using undocumented-but-legitimate access).
#>

# --- Configure for your environment ---
$AutoRemediate        = $false                 # set $true only after a review cycle
$ForceRemoveAllowList = @()                     # e.g. @('CONTOSO\jsmith') — accounts safe to auto-strip
$ApprovedGroups       = @('Domain Admins', 'AAD DC Administrators')
$ApprovedUserPatterns = @('*-LAPSAdmin')
# ---------------------------------------

$LogPrefix = "[ZeroTrust-LocalAdmin-Remediation]"

try {
    $AdminGroup = Get-LocalGroup -Name 'Administrators'
    $Members = Get-LocalGroupMember -Group $AdminGroup

    $Unexpected = foreach ($Member in $Members) {
        if ($Member.SID -like '*-500') { continue }
        if ($Member.ObjectClass -eq 'Group' -and $Member.Name -in $ApprovedGroups) { continue }
        $IsApprovedPattern = $false
        foreach ($Pattern in $ApprovedUserPatterns) {
            if ($Member.Name -like $Pattern) { $IsApprovedPattern = $true; break }
        }
        if ($IsApprovedPattern) { continue }
        $Member
    }

    if (-not $Unexpected) {
        Write-Output "$LogPrefix No unexpected members found at remediation time (may have changed since detection ran)."
        exit 0
    }

    foreach ($Member in $Unexpected) {
        $OnForceList = $Member.Name -in $ForceRemoveAllowList

        if ($AutoRemediate -and $OnForceList) {
            Remove-LocalGroupMember -Group $AdminGroup -Member $Member.Name
            Write-Output "$LogPrefix REMOVED '$($Member.Name)' from local Administrators (on ForceRemoveAllowList, AutoRemediate enabled)."
            Write-EventLog -LogName Application -Source "ZeroTrustRemediation" -EventId 9001 -EntryType Warning `
                -Message "Removed '$($Member.Name)' from local Administrators via automated Zero Trust remediation." -ErrorAction SilentlyContinue
        }
        else {
            Write-Output "$LogPrefix FLAGGED (not removed): '$($Member.Name)' is an unexpected local admin. Review with the account owner before adding to ForceRemoveAllowList."
        }
    }

    # Exit 0 even when flagging-only, so this doesn't show as a repeated
    # "failed remediation" in Intune — the finding is visible in the output
    # log either way, which is what drives the IT review, not a red X.
    exit 0
}
catch {
    Write-Output "$LogPrefix Remediation failed: $($_.Exception.Message)"
    exit 1
}
