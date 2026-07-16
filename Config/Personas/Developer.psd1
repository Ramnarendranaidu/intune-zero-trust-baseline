@{
    # Developer persona — engineers running Docker/WSL/local dev servers,
    # package managers, IDEs with debuggers, build tooling. The single
    # biggest risk in this repo is treating developers like Standard Users:
    # WDAC enforcement or aggressive ASR blocking WILL break legitimate dev
    # workflows (npm/pip installing scripts, debugger process injection,
    # WSL networking), so this persona trades some app-control strictness
    # for tighter identity/elevation controls instead.
    PersonaName        = "Developer"
    Description         = "Software/infra engineers. Local dev tooling (containers, WSL, package managers, debuggers) needs flexibility that WDAC enforcement and ASR Block mode would break. Compensate with JIT elevation and strong audit logging instead of app lockdown."
    BaseArchetype       = "PrivilegedAdmin"   # closest of the 3 core tiers — elevated identity controls, not device lockdown
    EntraSecurityGroup  = "SG-ZeroTrust-Developer"   # placeholder — replace with real Entra group Object ID
    UpdateRing          = "Fast"              # early enough to catch issues, not bleeding-edge Test ring
    ComplianceTier      = "L1-Broad+SelectiveL2"

    Controls = @{
        RequireWindowsHelloForBusiness   = $true
        RequireLAPS                      = $true
        JITLocalAdminElevation           = $true    # time-boxed elevation for installs/container runtime, not standing admin
        InactivityLockoutMinutes         = 15
        BitLockerRequired                = $true
        BitLockerStartupPinRequired      = $false   # dev laptops reboot often (VM/container work) — high friction cost here
        DefenderRealTimeProtection       = $true
        DefenderTamperProtection         = $true
        DefenderDevToolExclusions        = $true    # WSL vEthernet, local container runtime, common IDE debugger ports — see docs/Personas-Extended.md
        ASRRulesMode                     = "Audit"   # stays in Audit indefinitely for this persona unless proven safe — build tooling trips several ASR rules legitimately
        ControlledFolderAccess           = $false   # blocks compilers/build tools writing to protected folders otherwise
        FirewallAllProfilesEnabled       = $true
        SMBv1Disabled                    = $true
        PowerShellScriptBlockLogging     = $true
        ConstrainedLanguageMode          = $false   # Full Language Mode required for legitimate dev scripting
        WDACEnforced                     = $false   # Audit-only, permanently, unless the org invests in a maintained dev-tooling allow-list
        RemovableStorageBlocked          = $false
        RemovableMediaAutoRunDisabled    = $true
    }
}
