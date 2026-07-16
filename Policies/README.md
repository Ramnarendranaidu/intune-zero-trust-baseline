# Policy payloads

These are **Settings Catalog** / **Endpoint Security** policy templates in
Microsoft Graph JSON shape, meant to be created via
`POST /deviceManagement/configurationPolicies` (Settings Catalog) or the
relevant Endpoint Security endpoint.

## Before you push any of these to a real tenant

Graph's Settings Catalog schema (setting definition IDs, especially) changes
as Microsoft adds new CSPs and updates existing ones. **Validate every
`settingDefinitionId` against your tenant's current catalog before deploying**:

```powershell
# List current setting definitions matching a keyword, e.g. "BitLocker"
Get-MgDeviceManagementConfigurationSettingDefinition -Filter "contains(displayName,'BitLocker')"
```

Or browse interactively in the Intune admin center: **Devices > Configuration
> Create > Settings catalog**, search for the control by name, and confirm the
setting ID matches what's in these JSON files before importing.

`Scripts/Deploy-IntunePolicy.ps1` does a dry-run schema check against your
tenant before creating anything, for exactly this reason — don't skip it.

## Folder structure

- **`L1/`** — CIS Level 1 controls. Safe for broad production rollout;
  deploy to all rings/personas per `docs/CIS-Mapping.md`.
- **`L2/`** — CIS Level 2 controls. Higher app-compat risk. Deploy to the
  Privileged/IT Admin persona (Test/Pilot ring) first; only widen to other
  personas after a validation window with no compatibility regressions.

## Each file's `_metadata` block

Every policy JSON here carries a `_metadata` object (stripped before the
actual Graph POST — see the deploy script) documenting:
- which CIS-Mapping.md row(s) it implements
- which personas it applies to
- rollback guidance if it causes an issue
