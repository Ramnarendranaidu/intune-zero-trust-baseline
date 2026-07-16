# CIS → Zero Trust → Intune Control Mapping

This is the source of truth for the whole repo: every policy JSON, remediation
script, and persona assignment in this repo traces back to a row here.

**Important accuracy note:** CIS Benchmark section numbers shift between
benchmark versions (e.g. CIS Microsoft Windows 11 Enterprise Benchmark v3.0 vs
v4.0). The control *names* and *intent* below are stable; treat the numeric
section references as "approximate, verify against your licensed CIS-CAT
Pro benchmark version" rather than exact citations. Confirm against your
actual CIS-CAT scan output before treating any control as validated.

## Tier legend

- **L1** — CIS Level 1: safe for broad production rollout, minimal app-compat risk. Deployed to all rings.
- **L2** — CIS Level 2: stricter, higher security value, higher app-compat risk (can break legacy LOB apps, some peripherals, older auth flows). Deployed to Pilot/Test ring only until validated, per the ring model in the companion `windows-update-ring-intelligence` repo.

## Persona legend

- **SU** — Standard User (knowledge workers, no local admin)
- **PA** — Privileged/IT Admin (elevated devices, admin workstations)
- **KS** — Kiosk / Shared Device (single-purpose, multi-user, unattended)

---

## Identity & Authentication

| Control | Tier | CIS area (approx.) | SU | PA | KS | Intune policy vehicle |
|---|---|---|---|---|---|---|
| Enforce MFA via Conditional Access for all users | L1 | Account Policies / Entra CA | ✅ | ✅ | ✅ | Entra Conditional Access (not Intune config profile — noted in docs/Rollout-Strategy.md) |
| Block legacy authentication protocols | L1 | Account Policies | ✅ | ✅ | ✅ | Entra Conditional Access |
| Windows Hello for Business required | L1 | Account Policies | ✅ | ✅ | ❌ (shared device — see Autopilot self-deploying/kiosk mode instead) | Settings Catalog: `DeviceLock/WindowsHelloForBusiness` |
| Interactive logon: Machine inactivity limit (15 min) | L1 | Local Policies / Security Options | ✅ | ✅ | ✅ (5 min on KS) | Settings Catalog: `LocalPoliciesSecurityOptions/InteractiveLogon_MachineInactivityLimit` |
| Account lockout threshold (10 invalid attempts) | L1 | Account Policies / Lockout | ✅ | ✅ | ✅ | Settings Catalog: `AccountLockoutPolicy` |
| Local Administrator Password Solution (Windows LAPS) | L1 | Local Policies | ❌ | ✅ | ❌ | Endpoint Security: LAPS policy |
| Just-in-time local admin elevation (no standing local admin) | L2 | Local Policies | n/a | ✅ | n/a | Endpoint Security: LAPS + Entra PIM for Groups |
| Restrict remote logon rights to Domain Admins group | L2 | User Rights Assignment | ❌ | ✅ | ❌ | Settings Catalog: `UserRightsAssignment/DenyRemoteLogon` |

## Device Encryption

| Control | Tier | CIS area | SU | PA | KS | Intune policy vehicle |
|---|---|---|---|---|---|---|
| BitLocker OS drive encryption, XTS-AES 256 | L1 | BitLocker Drive Encryption | ✅ | ✅ | ✅ | Endpoint Security: Disk Encryption profile |
| BitLocker fixed data drive encryption | L1 | BitLocker Drive Encryption | ✅ | ✅ | ✅ | Endpoint Security: Disk Encryption profile |
| Require startup PIN (pre-boot authentication) | L2 | BitLocker Drive Encryption | ✅ | ✅ | ❌ (unattended boot required) | Settings Catalog: `BitLocker/SystemDrivesRequireStartupAuthentication` |
| Deny write access to removable drives not BitLocker-protected | L1 | BitLocker Drive Encryption | ✅ | ✅ | ✅ | Settings Catalog: `BitLocker/RemovableDrive_ConfigureBDE` |

## Endpoint Detection, Antivirus & Attack Surface Reduction

| Control | Tier | CIS area | SU | PA | KS | Intune policy vehicle |
|---|---|---|---|---|---|---|
| Microsoft Defender Antivirus real-time protection | L1 | Windows Defender Antivirus | ✅ | ✅ | ✅ | Endpoint Security: Antivirus policy |
| Cloud-delivered protection + automatic sample submission | L1 | Windows Defender Antivirus | ✅ | ✅ | ✅ | Endpoint Security: Antivirus policy |
| PUA (Potentially Unwanted App) protection = Block | L1 | Windows Defender Antivirus | ✅ | ✅ | ✅ | Endpoint Security: Antivirus policy |
| Attack Surface Reduction rules (block Office macro/script abuse, credential theft from LSASS, etc.) — Audit mode first | L1 (audit) → L2 (block) | Defender ASR | ✅ | ✅ | ✅ | Endpoint Security: ASR policy |
| Controlled Folder Access (ransomware protection) | L2 | Defender Exploit Guard | ✅ | ✅ | ✅ | Endpoint Security: ASR policy |
| Network protection (block malicious domains at network layer) | L1 | Defender Exploit Guard | ✅ | ✅ | ✅ | Endpoint Security: ASR policy |
| Tamper Protection enabled | L1 | Windows Defender Antivirus | ✅ | ✅ | ✅ | Endpoint Security: Antivirus policy |

## Firewall & Network

| Control | Tier | CIS area | SU | PA | KS | Intune policy vehicle |
|---|---|---|---|---|---|---|
| Windows Defender Firewall enabled, all profiles (Domain/Private/Public) | L1 | Windows Firewall with Advanced Security | ✅ | ✅ | ✅ | Endpoint Security: Firewall policy |
| Default inbound = block, outbound = allow (with app exceptions) | L1 | Windows Firewall | ✅ | ✅ | ✅ | Endpoint Security: Firewall policy |
| Disable SMBv1 | L1 | Network / SMB | ✅ | ✅ | ✅ | Settings Catalog: custom OMA-URI / Defender for Endpoint recommendation |
| LLMNR and NetBIOS name resolution disabled | L2 | Network | ✅ | ✅ | ✅ | Settings Catalog: `DNSClient` / `NetBIOS` |

## Application & Script Control

| Control | Tier | CIS area | SU | PA | KS | Intune policy vehicle |
|---|---|---|---|---|---|---|
| PowerShell Script Block Logging + Module Logging | L1 | PowerShell | ✅ | ✅ | ✅ | Settings Catalog: `AdmxWindowsPowerShell` |
| PowerShell Constrained Language Mode for standard users | L2 | PowerShell / App Control | ✅ | ❌ (admins need Full) | ✅ | App Control for Business (WDAC) policy |
| Windows Defender Application Control (WDAC) — allow-list LOB + Microsoft-signed | L2 | Device Guard | ✅ | ❌ (broader allow-list) | ✅ (tightest allow-list) | App Control for Business policy |
| Block untrusted/unsigned removable media execution (AutoRun/AutoPlay off) | L1 | Removable Storage Access | ✅ | ✅ | ✅ | Settings Catalog: `RemovableStorage` |
| Disable removable storage entirely | L2 | Removable Storage Access | ❌ (business need) | ❌ | ✅ | Settings Catalog: `RemovableStorage` |

## Audit & Logging

| Control | Tier | CIS area | SU | PA | KS | Intune policy vehicle |
|---|---|---|---|---|---|---|
| Audit Credential Validation (success & failure) | L1 | Advanced Audit Policy | ✅ | ✅ | ✅ | Settings Catalog: `Audit` |
| Audit Process Creation with command-line auditing | L1 | Advanced Audit Policy | ✅ | ✅ | ✅ | Settings Catalog: `Audit` + `AdmxAuditProcessCreation` |
| Forward security event logs to SIEM (Defender for Endpoint / Sentinel) | L1 | Event Log | ✅ | ✅ | ✅ | Defender for Endpoint onboarding profile |
| PowerShell transcription enabled | L1 | PowerShell | ✅ | ✅ | ✅ | Settings Catalog: `AdmxWindowsPowerShell` |

## Update & Servicing

Covered by the companion **`windows-update-ring-intelligence`** repo (feature/
quality/driver deferral rings). This repo's personas map to those rings:
Kiosk/Shared and Standard User → Broad/Fast rings; Privileged/IT Admin →
Test/First ring (dogfeeds changes before they hit the fleet).
