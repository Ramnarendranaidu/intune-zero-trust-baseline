# Intune Zero Trust Baseline

A CIS-aligned, persona-based Zero Trust security baseline for Intune-managed
Windows 10/11 and Windows Server (2016/2019/2022) endpoints — built from
Microsoft's Group Policy Settings Reference, mapped to modern Intune Settings
Catalog / Endpoint Security policy, with proactive remediation, fleet-wide
compliance reporting, and a rollout strategy designed to avoid breaking
anything on the way to "compliant."

## What this actually is (and isn't)

**Is:** a curated set of ~30 high-value Zero Trust controls, each traced to a
CIS Benchmark control area, split into safe-for-everyone (L1) and
stricter-but-riskier (L2) tiers, assigned per persona, deployable via a
validated Graph API script, monitored via proactive remediation and a
compliance report.

**Isn't:** a line-by-line implementation of every setting in the uploaded
Group Policy Settings Reference spreadsheet (that's thousands of legacy
ADMX settings, most irrelevant to a modern cloud-managed fleet), and isn't a
substitute for running your own licensed CIS-CAT Pro scan for formal
attestation — see `docs/Reporting-Options.md` for exactly where this repo's
scope ends and your compliance tooling's scope begins.

## Structure

```
docs/
  CIS-Mapping.md              — the source of truth: every control, its CIS area, tier, and persona
  Personas.md                 — why these three personas, and how to add a fourth
  Rollout-Strategy.md          — how to deploy this without breaking anything
  Reporting-Options.md         — Intune reports vs Power BI vs Log Analytics vs CIS-CAT, honestly compared
  VSCode-ClaudeCode-Integration.md — how to actually run this from your dev environment

Config/Personas/
  StandardUser.psd1            — knowledge workers, no local admin, Broad ring
  PrivilegedAdmin.psd1          — elevated access, Test ring, IS the L2 pilot
  KioskSharedDevice.psd1        — shared/unattended, Fast ring, tightest device lockdown

Policies/
  L1/                          — safe for fleet-wide rollout
  L2/                          — pilot-ring only until validated

Remediations/
  BitLocker/, Defender/, Firewall/, LocalAdmin/, ASR/
    Detect-*.ps1 / Remediate-*.ps1  — Intune Proactive Remediation pairs

Scripts/
  Connect-ZeroTrustTenant.ps1   — Graph auth helper
  Deploy-IntunePolicy.ps1       — validates schema, dry-runs by default, creates (unassigned) with -Confirm
  New-PersonaAssignment.ps1     — separate, deliberate assignment step

Reporting/
  Get-ZeroTrustComplianceReport.ps1 — fleet-wide compliance rollup from live Graph data

Tests/
  ZeroTrustBaseline.Tests.ps1   — Pester: JSON validity, safety conventions, persona consistency
```

## Quick start

```powershell
git clone https://github.com/Ramnarendranaidu/intune-zero-trust-baseline.git
cd intune-zero-trust-baseline

# 1. Authenticate
./Scripts/Connect-ZeroTrustTenant.ps1 -TenantId "yourtenant.onmicrosoft.com"

# 2. Dry-run a policy (validates schema, creates nothing)
./Scripts/Deploy-IntunePolicy.ps1 -PolicyPath ./Policies/L1/DefenderAV-Baseline.json

# 3. Actually create it (still unassigned)
./Scripts/Deploy-IntunePolicy.ps1 -PolicyPath ./Policies/L1/DefenderAV-Baseline.json -Confirm

# 4. Assign to a persona, explicitly
./Scripts/New-PersonaAssignment.ps1 -PolicyId "<id-from-step-3>" -PersonaName StandardUser
```

Before step 4 for real: edit `Config/Personas/*.psd1` and replace the
placeholder `EntraSecurityGroup` values with your actual group Object IDs.

## Deploy proactive remediations

In the Intune admin center: **Devices > Scripts and remediations >
Proactive remediations > Create**. Pair each `Detect-*.ps1` with its matching
`Remediate-*.ps1` from the same `Remediations/<Category>/` folder. Run on a
schedule (daily is reasonable for most of these).

**Read `Remediations/LocalAdmin/Remediate-LocalAdminGroupMembership.ps1`'s
header comment before enabling it** — it's report-only by default on purpose.

## Track compliance

```powershell
./Reporting/Get-ZeroTrustComplianceReport.ps1 -OutputPath ./reports/latest.json
```

See `docs/Reporting-Options.md` for how to turn this into a scheduled Power
BI dataset or a Log Analytics workbook, and where CIS-CAT Pro fits alongside
it rather than being replaced by it.

## Rollout order (don't skip this)

1. L1 controls → all personas, all rings.
2. ASR rules run in **Audit** mode first (`Policies/L1/ASR-AuditMode.json`).
   Run `Remediations/ASR/Get-ASRAuditHits.ps1` fleet-wide for 2-4 weeks.
3. Zero audit hits → promote to `Policies/L2/ASR-BlockMode.json`, starting
   with the PrivilegedAdmin persona (Test ring) only.
4. Repeat the same audit-before-block discipline for any other L2 control
   before widening its persona list.

Full reasoning in `docs/Rollout-Strategy.md`.

## Companion repo

Pairs with **`windows-update-ring-intelligence`** — same persona/ring model
extends naturally to Windows Update feature/quality/driver deferral, so a
device's security posture and update cadence move together instead of being
managed as two disconnected systems.

## Testing

```powershell
Invoke-Pester -Path ./Tests
```

## License

MIT — see [LICENSE](LICENSE).
