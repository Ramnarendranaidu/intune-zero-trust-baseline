@{
    # Service Desk / Help Desk (Tier 1/2 IT support) persona — needs enough
    # elevation to run remote-assistance and password-reset tools, but is
    # NOT the same trust tier as PrivilegedAdmin (sysadmins/infra engineers
    # with standing infrastructure access). Treat as a lighter-weight,
    # narrower version of JIT elevation: scoped to specific support tools,
    # not general local admin.
    PersonaName        = "ServiceDesk"
    Description         = "Tier 1/2 IT support. Needs JIT elevation scoped to remote-assistance and reset tooling, not general admin rights. Dogfeeds ahead of the general fleet since they're IT staff, but is a narrower trust tier than PrivilegedAdmin."
    BaseArchetype       = "PrivilegedAdmin"    # closest of the 3 core tiers, but with narrower elevation scope — see Controls below
    EntraSecurityGroup  = "SG-ZeroTrust-ServiceDesk"   # placeholder — replace with real Entra group Object ID
    UpdateRing          = "First"               # dogfeeds ahead of general fleet, but after the PrivilegedAdmin/Test ring proper
    ComplianceTier      = "L1-Broad+SelectiveL2"

    Controls = @{
        RequireWindowsHelloForBusiness   = $true
        RequireLAPS                      = $true
        JITLocalAdminElevation           = $true    # scoped to helpdesk tooling (remote assistance, password reset consoles), not blanket admin
        JITElevationScope                = "HelpdeskToolsOnly"
        InactivityLockoutMinutes         = 15
        BitLockerRequired                = $true
        BitLockerStartupPinRequired      = $false
        DefenderRealTimeProtection       = $true
        DefenderTamperProtection         = $true
        DefenderRemoteToolExclusions     = $true    # remote assistance / RMM tooling needs specific ASR/AV exclusions — see docs/Personas-Extended.md
        ASRRulesMode                     = "Audit"   # remote support tools often trip credential-theft-pattern ASR rules legitimately; validate before Block
        ControlledFolderAccess           = $false
        FirewallAllProfilesEnabled       = $true
        SMBv1Disabled                    = $true
        LLMNRNetBIOSDisabled             = $false   # some legacy network troubleshooting workflows still rely on this — revisit after tooling audit
        PowerShellScriptBlockLogging     = $true
        ConstrainedLanguageMode          = $false   # needs Full Language Mode for support/diagnostic scripting
        WDACEnforced                     = $false
        RemovableStorageBlocked          = $false
        RemovableMediaAutoRunDisabled    = $true
    }
}
