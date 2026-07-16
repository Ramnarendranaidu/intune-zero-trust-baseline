<#
.SYNOPSIS
    Detection script for Intune Proactive Remediations: checks whether the
    OS drive is BitLocker-protected and encryption is complete.

.DESCRIPTION
    Exit 0  = compliant (protection on, encryption 100% complete) — no remediation runs.
    Exit 1  = non-compliant (protection off, or encryption in progress/incomplete) — triggers Remediate-BitLockerEncryption.ps1.

    Runs as SYSTEM via Intune Proactive Remediations. Read-only — makes no changes.
#>

try {
    $Volume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop

    if ($Volume.ProtectionStatus -eq 'On' -and $Volume.VolumeStatus -eq 'FullyEncrypted') {
        Write-Output "Compliant: $($env:SystemDrive) is BitLocker-protected and fully encrypted."
        exit 0
    }

    Write-Output "Non-compliant: ProtectionStatus=$($Volume.ProtectionStatus), VolumeStatus=$($Volume.VolumeStatus)"
    exit 1
}
catch {
    Write-Output "Non-compliant: unable to query BitLocker status - $($_.Exception.Message)"
    exit 1
}
