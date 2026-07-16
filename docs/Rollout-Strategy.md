# Rollout strategy: how to deploy this without breaking anything

The explicit requirement was "no user or device impacted due to function
break or performance." No security baseline can promise that with zero risk
— but the design choices below are specifically aimed at minimizing it.

## 1. L1 before L2, always

Every L1 control in `docs/CIS-Mapping.md` was chosen because it has low or
no realistic app-compat impact (real-time AV, firewall-on, BitLocker with
TPM-only protector, audit-mode logging). Deploy L1 fleet-wide first. L2
controls (startup PIN, WDAC enforcement, Constrained Language Mode) carry
real friction or compat risk and are gated to the Privileged/IT Admin persona
until proven safe.

## 2. Audit mode before Block mode, for anything that can silently break an app

Attack Surface Reduction rules ship in this repo as **Audit** (L1) first.
Audit mode logs what *would* have been blocked without blocking it — this is
the single most important safety mechanism in the whole repo. Run
`Remediations/ASR/Get-ASRAuditHits.ps1` across the fleet for 2-4 weeks,
confirm zero legitimate-workflow hits, *then* promote to
`Policies/L2/ASR-BlockMode.json` — starting with the Privileged/IT Admin
persona, not the whole fleet at once.

## 3. Ring-gated rollout (reuse the existing ring model)

Persona → update ring mapping (from `Config/Personas/*.psd1`):

| Persona | Update ring | Why |
|---|---|---|
| PrivilegedAdmin | Test/First | IT dogfeeds every change — both OS updates and this baseline's L2 controls — before anyone else sees it |
| KioskSharedDevice | Fast | Narrow, known app set — low blast radius if something breaks, but not the very first ring |
| StandardUser | Broad | Widest population — only receives L2 controls after Pilot/Fast validation |

Use the same Entra security groups that back your Windows Update rings
(from the companion `windows-update-ring-intelligence` repo) as the
assignment target for these Zero Trust policies too — one group per
persona/ring, not per individual control, so a device's "trust posture" and
"update cadence" move together and stay easy to reason about.

## 4. Never auto-remediate anything with direct user-facing impact

Compare the two remediation scripts:

- `Remediations/Firewall/Remediate-WindowsFirewallEnabled.ps1` — safe to
  auto-remediate. Toggling firewall back on has no user-visible effect and
  doesn't touch existing app-specific rules.
- `Remediations/LocalAdmin/Remediate-LocalAdminGroupMembership.ps1` —
  **deliberately report-only by default.** Silently removing someone's local
  admin rights is exactly the kind of "break" this project was asked to
  avoid. It flags for human review instead of acting automatically, unless
  you explicitly opt an account into auto-removal after reviewing it.

Apply this same judgment before writing any new remediation: "would flipping
this automatically, on every device, right now, ever stop someone from doing
their job?" If yes, it reports; it doesn't act.

## 5. Communicate the one unavoidably-visible control

`Policies/L2/BitLocker-StartupPIN.json` is the one control in this repo that
is impossible to make invisible — it adds a PIN prompt to every cold boot.
Don't silently enable it. Pair it with a change-management notice before
widening beyond the Privileged/IT Admin pilot ring.

## 6. Pre-flight validation before every policy push

`Scripts/Deploy-IntunePolicy.ps1` validates every setting ID against your
tenant's live Settings Catalog before creating anything, and defaults to a
dry run. A stale setting ID (Microsoft renames/versions these over time)
fails loudly in validation, not silently in production.

## 7. Rollback path documented per policy

Every policy JSON's `_metadata.rollback` field describes exactly how to
undo that specific control — see e.g. why BitLocker's rollback guidance
explicitly says *don't* bulk-decrypt as your "undo" (`Policies/L1/BitLocker-Baseline.json`).
