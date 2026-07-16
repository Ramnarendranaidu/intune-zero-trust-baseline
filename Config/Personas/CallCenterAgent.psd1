@{
    # Call Center Agent persona — CRM/softphone/browser-only workstations,
    # often hot-desked across shifts, frequently in PCI-DSS or similar
    # compliance scope (payment card handling, recorded calls with customer
    # data). Fixed, small, IT-curated app set makes strict allow-listing
    # low-risk here — similar reasoning to Kiosk/Shared, but with individual
    # user identity (agents log in as themselves, not a shared kiosk account).
    PersonaName        = "CallCenterAgent"
    Description         = "CRM/softphone/browser workstations, often hot-desked, frequently PCI-DSS/compliance-scoped. Fixed known app set — safe to lock down tightly. Individual identity per agent, unlike Kiosk."
    BaseArchetype       = "KioskSharedDevice"   # closest of the 3 core tiers for lockdown posture, but keeps per-user identity
    EntraSecurityGroup  = "SG-ZeroTrust-CallCenterAgent"   # placeholder — replace with real Entra group Object ID
    UpdateRing          = "Fast"                # faster patch cadence given compliance scope (PCI-DSS environments expect prompt patching)
    ComplianceTier      = "L1-Broad+SelectedL2"

    Controls = @{
        RequireWindowsHelloForBusiness   = $true    # individual identity even on hot-desked hardware
        RequireLAPS                      = $false
        InactivityLockoutMinutes         = 5        # short — compliance requirement in most call center environments
        BitLockerRequired                = $true
        BitLockerStartupPinRequired      = $false   # hot-desk devices need fast agent handoff between shifts
        DefenderRealTimeProtection       = $true
        DefenderTamperProtection         = $true
        ASRRulesMode                     = "Block"  # narrow known app set — low compat risk, safe to enforce
        ControlledFolderAccess           = $true
        FirewallAllProfilesEnabled       = $true
        SMBv1Disabled                    = $true
        LLMNRNetBIOSDisabled             = $true
        PowerShellScriptBlockLogging     = $true
        ConstrainedLanguageMode          = $true
        WDACEnforced                     = $true    # tight allow-list: CRM, softphone, approved browser + sites only
        RemovableStorageBlocked          = $true    # data exfiltration control — standard requirement in card-data environments
        RemovableMediaAutoRunDisabled    = $true
        ClipboardRestrictionRecommended  = $true    # flagged for DLP layer — see docs/Personas-Extended.md, out of this repo's direct scope
    }
}
