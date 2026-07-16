# Reporting options: what "best reporting" actually means here

There isn't one universal answer — it depends on your audience and update
cadence. Here's the honest tradeoff table.

| Option | Best for | Update frequency | Effort to stand up |
|---|---|---|---|
| **Intune built-in reports** (Devices > Monitor > Compliance / Endpoint Security reports) | Quick daily checks, no build required | Near real-time | Zero — already exists |
| **Get-ZeroTrustComplianceReport.ps1 → CSV/JSON → Power BI** | Exec/leadership dashboards, trend-over-time, persona-level rollups | Scheduled (e.g. daily via Task Scheduler/Azure Automation) | Low-medium — this repo's script + a Power BI dataset refresh |
| **Log Analytics workspace + Azure Monitor Workbook** | SOC/security team, correlating with Defender for Endpoint alerts, Sentinel incidents | Near real-time if devices forward logs directly | Medium — needs a Log Analytics workspace and either the Azure Monitor Agent or Graph-to-LA pipeline |
| **CIS-CAT Pro scan output (your licensed tool)** | Formal compliance attestation against a specific CIS Benchmark version | Point-in-time, run on demand or scheduled scan | Depends entirely on your CIS-CAT Pro deployment — this repo doesn't run it, only aligns policy intent to it |

## Recommended combination

1. **Intune's own compliance/Endpoint Security reports** for day-to-day
   operational monitoring — no reason to rebuild what already exists.
2. **This repo's `Get-ZeroTrustComplianceReport.ps1`**, scheduled weekly,
   feeding a simple Power BI report for persona-level trend lines (what
   Intune's UI doesn't give you natively: "is the Kiosk persona's compliance
   % trending up or down over the last quarter").
3. **CIS-CAT Pro**, run against a representative sample per persona
   (not literally every device — that's what the persona model is for)
   before and after promoting any control from L1 to L2, as the actual
   attestation evidence for audit purposes.

## What this repo deliberately does NOT claim

- It does not run CIS-CAT for you — that's your licensed tool against a real
  scan target.
- It does not guarantee a specific CIS-CAT score — policy alignment and
  benchmark scan results can differ due to benchmark version, OS build, and
  scan scope nuances outside this repo's control.
- `Get-ZeroTrustComplianceReport.ps1`'s `Persona` field is a placeholder —
  wire it to your actual Entra group membership (same pattern as
  `Get-IntuneDeviceInventory` in the companion ring-intelligence repo) before
  relying on persona-level rollups.
