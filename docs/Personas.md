# Personas

Three personas, matching the three real populations a Zero Trust baseline
has to treat differently — same OS, genuinely different risk/impact tradeoffs.

## Standard User (`Config/Personas/StandardUser.psd1`)

Knowledge workers, no local admin. Broadest population — L1 controls apply
fleet-wide; L2 controls only after they've been validated in the
Privileged/IT Admin pilot ring. This persona's tolerance for friction is
lowest (largest population, most diverse app usage), so it's the most
conservative persona by design.

## Privileged/IT Admin (`Config/Personas/PrivilegedAdmin.psd1`)

Elevated-access workstations — help desk, sysadmins, infra engineers. This
persona **is** the L2 pilot ring: it gets the strictest controls first,
because (a) compromise of one of these devices has the highest blast radius,
and (b) the app set on these machines is small and IT-curated, so stricter
controls carry genuinely lower compat risk here than on the general fleet —
the opposite of what you might assume ("give admins the loosest policy"
is backwards for Zero Trust).

## Kiosk/Shared Device (`Config/Personas/KioskSharedDevice.psd1`)

Single-purpose or multi-user unattended devices. No persistent user
identity, so identity controls (Hello for Business, LAPS) don't apply the
same way — but this persona gets the tightest *device*-level lockdown
(WDAC allow-list, Constrained Language Mode, removable storage blocked)
because the legitimate app set is fixed and known in advance, making strict
allow-listing low-risk rather than high-friction.

## Adding a fourth persona later

Copy an existing `.psd1`, adjust `Controls`, set a real `EntraSecurityGroup`
Object ID, and add a row set to `docs/CIS-Mapping.md`. Executive/VIP and
Remote/BYOD are the two most common next additions — Executive/VIP typically
narrows further (even stricter Conditional Access, no local admin ever) while
Remote/BYOD usually needs an App Protection Policy layer this repo doesn't
currently cover (MAM, not just MDM).
