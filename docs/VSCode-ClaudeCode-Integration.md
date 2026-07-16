# Integrating Intune automation with VS Code / Claude Code

## The honest architecture

Neither VS Code nor Claude Code (nor me, in this chat) can hold or use your
tenant credentials. What they *can* do is be where the automation code lives,
gets edited, gets version-controlled, and gets run from — with an actual
authenticated PowerShell/Graph session doing the real work when you execute
it. There's no product that removes the "a human authenticates to the real
tenant" step, and there shouldn't be — that's the control that stops this
from being a supply-chain risk.

## VS Code setup

1. **PowerShell extension** (`ms-vscode.powershell`) — syntax highlighting,
   IntelliSense, and an integrated terminal that runs scripts with your local
   PowerShell session.
2. **Microsoft Graph PowerShell SDK**, installed once:
   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser
   ```
3. Clone this repo, open it in VS Code, and run scripts from the integrated
   terminal:
   ```powershell
   cd Scripts
   ./Connect-ZeroTrustTenant.ps1 -TenantId "yourtenant.onmicrosoft.com"
   ./Deploy-IntunePolicy.ps1 -PolicyPath ../Policies/L1/BitLocker-Baseline.json
   ```
   That's it — VS Code's role here is "good editor + terminal," nothing more
   exotic. The REST Client extension (`humao.rest-client`) is also useful if
   you want to hand-craft raw Graph calls against `.http` files instead of
   PowerShell.

## Claude Code

Claude Code is genuinely useful for the parts of this repo that are
judgment-heavy rather than credential-heavy:

- Reviewing/writing new remediation scripts against this repo's safety
  conventions (report-first for anything with user impact, exit codes,
  logging format)
- Adding new Settings Catalog policy JSON when Microsoft ships a new CSP —
  point it at Microsoft Learn's CSP reference and this repo's existing
  `_metadata` convention and have it draft the new policy file plus its
  `CIS-Mapping.md` row
- Generating Pester tests for new remediation scripts
- Drafting the change-management communication for the next control you
  promote from L1 to L2

It should **not** be given your Graph credentials or run `Deploy-IntunePolicy.ps1
-Confirm` unsupervised against production — treat it the way you'd treat a
skilled contractor: excellent at drafting and reviewing, but a human signs
off before anything touches the real tenant.

## CI/CD option (once you're comfortable with manual pushes)

If you want this fully pipeline-driven later: GitHub Actions can run
`Deploy-IntunePolicy.ps1` against a **non-production test tenant** using a
service principal (app registration with the same Graph scopes, client
secret or certificate stored in GitHub Secrets — never in the repo). Keep
production pushes manual and human-confirmed for the foreseeable future;
that's a deliberate choice given the "no impact" requirement, not a
limitation to fix immediately.
