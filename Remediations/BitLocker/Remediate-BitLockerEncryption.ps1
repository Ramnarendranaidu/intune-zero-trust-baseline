<#
.SYNOPSIS
    Remediation script for Intune Proactive Remediations: enables BitLocker
    on the OS drive if it isn't already protected.

.DESCRIPTION
    Runs only when Detect-BitLockerEncryption.ps1 exits 1. Runs as SYSTEM.

    Safety design (matches the "no user/device impact" requirement):
      - Uses TPM-only protector by default — no user-facing PIN prompt, no
        interruption to the current session. (L2's startup-PIN control is a
        separate, deliberately user-visible change — see docs/CIS-Mapping.md.)
      - Encrypts in the background (-UsedSpaceOnly) — encrypts used blocks
        only, dramatically faster than full-disk, negligible I/O impact on
        modern SSDs, and is Microsoft's own recommended default for
        already-provisioned devices.
      - Does NOT force a reboot. TPM-protector BitLocker activates without one.
      - Recovery key is escrowed to Entra ID automatically when the device is
        Entra-joined/hybrid-joined, so IT can always recover the volume.
#>

$ErrorActionPreference = 'Stop'
$LogPrefix = "[ZeroTrust-BitLocker-Remediation]"

try {
    $Volume = Get-BitLockerVolume -MountPoint $env:SystemDrive

    if ($Volume.ProtectionStatus -eq 'On' -and $Volume.VolumeStatus -eq 'FullyEncrypted') {
        Write-Output "$LogPrefix Already compliant, nothing to do."
        exit 0
    }

    # Confirm a usable TPM is present before attempting to encrypt —
    # attempting BitLocker without TPM support on a device that needs a
    # startup key would be a user-impacting failure mode we want to avoid.
    $Tpm = Get-Tpm -ErrorAction SilentlyContinue
    if (-not $Tpm -or -not $Tpm.TpmPresent -or -not $Tpm.TpmReady) {
        Write-Output "$LogPrefix TPM not present/ready — skipping automatic remediation, flagging for manual review instead of forcing a degraded (password-based) protector."
        exit 1
    }

    if ($Volume.VolumeStatus -eq 'EncryptionInProgress') {
        Write-Output "$LogPrefix Encryption already in progress ($($Volume.EncryptionPercentage)% complete) — no action needed, will report compliant once finished."
        exit 0
    }

    Write-Output "$LogPrefix Enabling BitLocker with TPM protector, used-space-only encryption (no user prompt, no reboot required)."

    Enable-BitLocker -MountPoint $env:SystemDrive `
        -EncryptionMethod XtsAes256 `
        -TpmProtector `
        -UsedSpaceOnly `
        -SkipHardwareTest

    # Escrow the recovery key to Entra ID so IT can always recover the volume.
    $RecoveryProtector = (Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector |
        Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' } |
        Select-Object -First 1

    if ($RecoveryProtector) {
        BackupToAAD-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId $RecoveryProtector.KeyProtectorId
        Write-Output "$LogPrefix Recovery key escrowed to Entra ID."
    }

    Write-Output "$LogPrefix Remediation complete. Encryption will finish in the background."
    exit 0
}
catch {
    Write-Output "$LogPrefix Remediation failed: $($_.Exception.Message)"
    exit 1
}
