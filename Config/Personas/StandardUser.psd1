@{
    # Standard User persona — knowledge workers, no local admin rights.
    # Broadest ring: gets L1 controls fleet-wide, L2 only after Pilot validation.
    PersonaName        = "StandardUser"
    Description         = "Knowledge worker devices. No local admin. Full productivity app compatibility required."
    EntraSecurityGroup  = "SG-ZeroTrust-StandardUser"   # placeholder — replace with your real group Object ID
    UpdateRing          = "Broad"                        # maps to windows-update-ring-intelligence ring model
    ComplianceTier      = "L1-Broad"                     # L1 fleet-wide; L2 gated to Pilot ring only

    Controls = @{
        RequireWindowsHelloForBusiness   = $true
        RequireLAPS                      = $false
        InactivityLockoutMinutes         = 15
        BitLockerRequired                = $true
        BitLockerStartupPinRequired      = $false   # L2 — pilot only, see ZeroTrust-L2 profile
        DefenderRealTimeProtection       = $true
        DefenderTamperProtection         = $true
        ASRRulesMode                     = "Audit"   # graduates to "Block" after pilot validation window
        ControlledFolderAccess           = $false   # L2 — pilot only
        FirewallAllProfilesEnabled       = $true
        SMBv1Disabled                    = $true
        PowerShellScriptBlockLogging     = $true
        ConstrainedLanguageMode          = $false   # L2 — would break some LOB scripts, pilot first
        WDACEnforced                     = $false   # L2 — allow-list needs app inventory pass first
        RemovableStorageBlocked          = $false   # business need — audit only, not blocked
        RemovableMediaAutoRunDisabled    = $true
    }
}
