# Extended personas

The original three (`StandardUser`, `PrivilegedAdmin`, `KioskSharedDevice`)
are the three *archetypes* — every additional persona below is a variant of
one of them, not a fourth independent control model. Each extended persona's
`.psd1` declares a `BaseArchetype` field naming which one it's closest to,
so `docs/CIS-Mapping.md`'s three-column table still applies: read a new
persona's row as "mostly like its base archetype, except where noted here."

**"General Users" = `StandardUser`.** No separate file — that's exactly
what the original persona already models (knowledge workers, no local
admin, Broad ring). Adding a duplicate would just be two names for the
same thing.

## Developer (`Config/Personas/Developer.psd1`) — base: PrivilegedAdmin

The trap with developer personas is treating them like Standard Users
"because they don't need infrastructure access." They don't need
infrastructure access, but their local tooling (containers, WSL, package
managers, debuggers attaching to processes) trips almost every aggressive
app-control and ASR rule that exists. This persona compensates with strong
identity controls (JIT elevation, MFA, logging) instead of app lockdown —
WDAC stays in Audit mode indefinitely here unless your org is willing to
maintain a dev-tooling allow-list, which most aren't.

**Action item before deploying:** populate `DefenderDevToolExclusions` with
your actual WSL vEthernet adapter range, container runtime paths, and IDE
debugger port ranges. This repo doesn't hardcode them since they vary by
team's stack (Docker Desktop vs Podman vs native WSL2, VS Code vs Visual
Studio vs JetBrains debug ports, etc.).

## Call Center Agent (`Config/Personas/CallCenterAgent.psd1`) — base: KioskSharedDevice

Fixed CRM/softphone/browser app set, often PCI-DSS or similar
compliance-scoped, frequently hot-desked across shifts. Locks down like
Kiosk/Shared (WDAC enforced, removable storage blocked) but keeps
per-agent Windows Hello identity rather than a shared kiosk account,
since call recording/CRM audit trails need to trace to an individual.

**Flagged, not implemented:** `ClipboardRestrictionRecommended` — clipboard
and screen-capture DLP controls for card-data environments are a Purview/
DLP-policy concern, outside this repo's Intune-config-profile scope. Don't
skip it, just don't expect it here.

## Service Desk (`Config/Personas/ServiceDesk.psd1`) — base: PrivilegedAdmin

Distinct from `PrivilegedAdmin` on purpose: Tier 1/2 help desk staff need
enough elevation to run remote-assistance and password-reset tooling, not
the standing infrastructure access a sysadmin/infra engineer has. The
`JITElevationScope: "HelpdeskToolsOnly"` field is a marker for whatever your
PIM/JIT tooling calls a scoped role — wire it to an actual scoped elevation
policy rather than the same broad admin role PrivilegedAdmin gets.

## Finance (`Config/Personas/Finance.psd1`) — base: PrivilegedAdmin

The one persona that deliberately breaks the "L2 = Privileged/IT Admin pilot
ring only" rule from `docs/Rollout-Strategy.md`. Finance has a predictable,
narrow app set (ERP, Excel, banking portals) — low compat risk — combined
with high fraud-targeting value (BEC, invoice fraud, wire transfer access) —
high stakes. That combination justifies adopting L2 controls (startup PIN,
WDAC enforced, ASR Block) ahead of the general fleet, even though Finance
staff aren't a technical/admin population. Still validate in Audit mode
first per the standard rollout discipline — "adopts L2 sooner" doesn't mean
"skips the audit-before-block step," just means the timeline is compressed
relative to Standard User.

## Marketing (`Config/Personas/Marketing.psd1`) — base: StandardUser

Closest persona to Standard User of the five — same conservative default
posture, but with specific carve-outs for the friction points marketing
teams hit hardest: broad external SaaS/social/ad-platform usage (network
protection needs an allow-list, not a blanket block) and frequent large
media file transfers (removable storage stays open, unlike Finance/Call
Center). `NetworkProtectionCategoryException` is a marker to maintain an
actual approved-domains list — leaving network protection wide open
instead defeats the point of having it.

## Adding more

Same pattern: pick the closest of the three core archetypes as
`BaseArchetype`, override only what's genuinely different, and document
*why* in a comment next to the override — the "why" is what keeps this
model auditable as it grows, not just the "what."
