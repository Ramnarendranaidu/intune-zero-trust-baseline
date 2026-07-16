@{
    # Kiosk / Shared Device persona — single-purpose or multi-user unattended
    # devices (lobby kiosks, shared floor terminals, shift-shared workstations).
    # No individual user identity persists on the device, so identity controls
    # differ (no Hello for Business, no personal profile), but device-level
    # lockdown is the strictest of the three personas.
    PersonaName        = "KioskSharedDevice"
    Description         = "Single-purpose or multi-user shared/unattended devices. Strictest app and storage lockdown; no persistent user identity."
    EntraSecurityGroup  = "SG-ZeroTrust-KioskSharedDevice"  # placeholder — replace with your real group Object ID
    UpdateRing          = "Fast"                            # faster than Broad, slower than Test — limited blast radius if something breaks
    ComplianceTier      = "L1-Broad+SelectedL2"

    Controls = @{
        RequireWindowsHelloForBusiness   = $false   # shared device — use Autopilot self-deploying / kiosk mode instead
        RequireLAPS                      = $false
        InactivityLockoutMinutes         = 5        # shorter than SU/PA — shared physical space
        BitLockerRequired                = $true
        BitLockerStartupPinRequired      = $false   # unattended boot required — no pre-boot PIN prompt
        DefenderRealTimeProtection       = $true
        DefenderTamperProtection         = $true
        ASRRulesMode                     = "Block"  # narrow, known app set — low compat risk, safe to enforce
        ControlledFolderAccess           = $true
        FirewallAllProfilesEnabled       = $true
        SMBv1Disabled                    = $true
        LLMNRNetBIOSDisabled             = $true
        PowerShellScriptBlockLogging     = $true
        ConstrainedLanguageMode          = $true    # narrow app set tolerates this well
        WDACEnforced                     = $true    # tightest allow-list — kiosk app set is fixed and known
        RemovableStorageBlocked          = $true    # no legitimate business need on shared/kiosk hardware
        RemovableMediaAutoRunDisabled    = $true
        AssignedAccessKioskMode          = $true    # single-app or multi-app kiosk shell where applicable
    }
}
