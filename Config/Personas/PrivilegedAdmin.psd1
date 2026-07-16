@{
    # Privileged/IT Admin persona — elevated access devices (help desk, sysadmins,
    # cloud/infra engineers). Highest control set since compromise here is highest-blast-radius.
    # Assigned to the Test/First update ring — dogfeeds changes before Standard User fleet.
    PersonaName        = "PrivilegedAdmin"
    Description         = "IT admin / elevated-access workstations. Highest security posture; app set is curated and known, so stricter controls carry lower compat risk than the general fleet."
    EntraSecurityGroup  = "SG-ZeroTrust-PrivilegedAdmin"  # placeholder — replace with your real group Object ID
    UpdateRing          = "Test"                          # dogfeeds updates before Standard User rings
    ComplianceTier      = "L1+L2-Pilot"                   # this persona IS the L2 pilot ring

    Controls = @{
        RequireWindowsHelloForBusiness   = $true
        RequireLAPS                      = $true
        JITLocalAdminElevation           = $true    # no standing local admin — PIM-gated elevation only
        DenyRemoteLogonExceptAdmins      = $true
        InactivityLockoutMinutes         = 15
        BitLockerRequired                = $true
        BitLockerStartupPinRequired      = $true
        DefenderRealTimeProtection       = $true
        DefenderTamperProtection         = $true
        ASRRulesMode                     = "Block"   # admins are the pilot ring — already validated
        ControlledFolderAccess           = $true
        FirewallAllProfilesEnabled       = $true
        SMBv1Disabled                    = $true
        LLMNRNetBIOSDisabled             = $true
        PowerShellScriptBlockLogging     = $true
        ConstrainedLanguageMode          = $false   # admins need Full Language Mode for legitimate tooling
        WDACEnforced                     = $false   # broader allow-list for admin tooling; audit mode only
        RemovableStorageBlocked          = $false
        RemovableMediaAutoRunDisabled    = $true
    }
}
