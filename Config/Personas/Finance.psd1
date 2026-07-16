@{
    # Finance Team persona — handles payroll, banking, financial reporting,
    # and often has wire-transfer/payment authority. High-value fraud target
    # (business email compromise, invoice fraud), so this persona adopts L2
    # controls FASTER than the general fleet despite having a fairly normal,
    # predictable app set (ERP, Excel, banking portals) — the driver here is
    # data sensitivity and fraud targeting, not app-compat risk.
    PersonaName        = "Finance"
    Description         = "Payroll/banking/financial reporting staff. High-value target for BEC and invoice fraud. Adopts L2 controls ahead of the general fleet — predictable app set makes stricter posture low-risk, and data sensitivity makes it high-value."
    BaseArchetype       = "PrivilegedAdmin"    # closest of the 3 core tiers for control strictness, despite not being an elevated-access technical role
    EntraSecurityGroup  = "SG-ZeroTrust-Finance"   # placeholder — replace with real Entra group Object ID
    UpdateRing          = "Fast"                # faster than Broad given fraud-targeting risk, without being IT's own dogfood ring
    ComplianceTier      = "L1-Broad+AcceleratedL2"

    Controls = @{
        RequireWindowsHelloForBusiness   = $true
        RequireLAPS                      = $false
        InactivityLockoutMinutes         = 10        # shorter than Standard User given sensitive data exposure
        BitLockerRequired                = $true
        BitLockerStartupPinRequired      = $true      # L2 control adopted early here — deliberate exception to "PA pilot only," see docs/Personas-Extended.md
        DefenderRealTimeProtection       = $true
        DefenderTamperProtection         = $true
        ASRRulesMode                     = "Block"    # promoted ahead of general fleet — predictable app set (ERP/Excel/banking portal), low compat risk
        ControlledFolderAccess           = $true       # ransomware targeting of finance shares/exports is a common real-world pattern
        FirewallAllProfilesEnabled       = $true
        SMBv1Disabled                    = $true
        LLMNRNetBIOSDisabled             = $true
        PowerShellScriptBlockLogging     = $true
        ConstrainedLanguageMode          = $true
        WDACEnforced                     = $true       # narrow, known app set: ERP client, Office, approved banking portals via browser
        RemovableStorageBlocked          = $true        # standard control for teams handling financial/PII exports
        RemovableMediaAutoRunDisabled    = $true
        RequireCompliantDeviceForFinanceApps = $true    # Conditional Access pairing — enforce via CA, not this repo's Settings Catalog scope directly
    }
}
