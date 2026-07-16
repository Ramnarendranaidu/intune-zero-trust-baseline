@{
    # Marketing persona — uses a wide variety of external SaaS tools (ad
    # platforms, social media schedulers, design/creative cloud apps, video
    # hosting), and regularly moves large media files. This is close to
    # Standard User in most respects, but network/content controls tuned
    # for Standard User (network protection blocking "uncategorized" sites,
    # aggressive removable-storage restriction for large file transfer) need
    # loosening here to avoid constant false-positive friction.
    PersonaName        = "Marketing"
    Description         = "Marketing/creative/social media staff. Frequent use of external SaaS tools and large media file transfers. Closest to Standard User, with specific network/storage carve-outs to avoid false-positive friction on legitimate marketing tooling."
    BaseArchetype       = "StandardUser"    # closest of the 3 core tiers — same conservative posture, different carve-outs
    EntraSecurityGroup  = "SG-ZeroTrust-Marketing"   # placeholder — replace with real Entra group Object ID
    UpdateRing          = "Broad"
    ComplianceTier      = "L1-Broad"

    Controls = @{
        RequireWindowsHelloForBusiness   = $true
        RequireLAPS                      = $false
        InactivityLockoutMinutes         = 15
        BitLockerRequired                = $true
        BitLockerStartupPinRequired      = $false
        DefenderRealTimeProtection       = $true
        DefenderTamperProtection         = $true
        ASRRulesMode                     = "Audit"    # same as Standard User — validate before Block, given diverse SaaS/plugin usage
        ControlledFolderAccess           = $false
        FirewallAllProfilesEnabled       = $true
        SMBv1Disabled                    = $true
        PowerShellScriptBlockLogging     = $true
        ConstrainedLanguageMode          = $false
        WDACEnforced                     = $false      # wide, changing SaaS/creative-tool set — allow-listing would need constant maintenance
        RemovableStorageBlocked          = $false       # legitimate need: large media file transfer to/from external vendors, printers, cameras
        RemovableMediaAutoRunDisabled    = $true
        NetworkProtectionCategoryException = $true      # carve-out for approved marketing SaaS/ad-platform domains — maintain an allow-list, don't disable network protection outright
    }
}
