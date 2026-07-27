# Provisioning runbook — SharePoint lists

Creates the 14 lists in `build/lists/` on your SharePoint site.
Script: [`New-LdpSharePointLists.ps1`](New-LdpSharePointLists.ps1)

## This environment

| | |
|---|---|
| Tenant | `markmolesworth.onmicrosoft.com` |
| Cloud | Commercial (`.sharepoint.com`) — **no `-AzureEnvironment` flag needed** |
| Target site | `https://markmolesworth.sharepoint.com/sites/leadership-development-program` |
| SharePoint admin | `https://markmolesworth-admin.sharepoint.com` |
| Client ID | _fill in after step 3_ |

The target site already exists. Everything below is provisioned **into** it — the
script never creates a site, so the URL above must be exact.

**Time:** ~20 min first run (most of it one-time setup in steps 1–3), ~2 min thereafter.
**You need:** Site Owner (or Site Collection Admin) on the target site, and the ability
to consent to an Entra ID app registration — on this single-owner tenant that is you.

---

## Step 1 — Install PowerShell 7

PnP.PowerShell 2.0+ does not run on Windows PowerShell 5.1. Check what you have:

```powershell
$PSVersionTable.PSVersion      # need 7.2 or later
```

If it prints 5.x, install PowerShell 7 (`winget install --id Microsoft.PowerShell`)
and re-open a terminal as **pwsh**, not the blue Windows PowerShell window.

## Step 2 — Install the PnP module

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
```

Answer `Y` to the untrusted-repository prompt. Verify:

```powershell
Get-Module -ListAvailable PnP.PowerShell | Select-Object Version
```

## Step 3 — Register an Entra ID app (one time per tenant)

PnP.PowerShell 2.0 removed the shared multi-tenant client ID that older guides
rely on, so **there is no way to sign in without your own app registration**.
Do this once for the tenant.

On a single-owner tenant like this one you are the Global Administrator, so consent
grants itself and no one else has to be involved. (In a managed org tenant this is
the step that stalls: consent is usually locked down, and duplicate PnP app
registrations are a governance headache — you would ask whether one already exists.)

Check the parameter names first — this cmdlet's surface has changed across PnP
releases, and the docs you find online are often for a different version:

```powershell
Get-Command Register-PnPEntraIDAppForInteractiveLogin -Syntax
```

Then:

```powershell
Register-PnPEntraIDAppForInteractiveLogin `
    -ApplicationName "PnP-LDP-Provisioning" `
    -Tenant markmolesworth.onmicrosoft.com
```

> There is **no `-Interactive` parameter** here. That switch belongs to
> `Connect-PnPOnline` (steps 5–6), and passing it to this cmdlet fails with
> *"A parameter cannot be found that matches parameter name 'Interactive'."*
> Sign-in is interactive by default — a browser opens on its own.
>
> If no browser appears, add `-DeviceLogin` for a code-based flow instead.

Registration runs for a minute or two — it creates the app, then waits for the
permission grants to propagate. When it finishes it prints a **client ID (GUID)** —
save it into the table at the top of this file, every run needs it.

Capture the result rather than trusting console rendering:

```powershell
$app = Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP-LDP-Provisioning" -Tenant markmolesworth.onmicrosoft.com
$app | Format-List *
```

### No GUID appeared?

Look in Entra → **Applications** → **App registrations** → **All applications** →
search `PnP-LDP`.

- **App is listed** — the GUID is **Application (client) ID** on its Overview page.
  Also open **API permissions** and press **Grant admin consent** if it is lit up;
  skipping that produces `AADSTS65001` at step 5, far from its cause.
- **App is not listed** — nothing was created. Re-run the command above.

### Fallback: register it by hand

The cmdlet is only a convenience wrapper. Equivalent manual setup:

1. Entra → **App registrations** → **New registration**
2. Name `PnP-LDP-Provisioning`; *Accounts in this organizational directory only*
3. **Redirect URI**: platform **Public client/native (mobile & desktop)**, value
   `http://localhost` — interactive sign-in fails without this
4. Register → copy **Application (client) ID**
5. **API permissions** → Add → **SharePoint** → **Delegated** → `AllSites.FullControl`
6. **Grant admin consent for markmolesworth**

### Confirm auth before step 4

```powershell
Connect-PnPOnline -Url https://markmolesworth.sharepoint.com/sites/leadership-development-program -Interactive -ClientId <guid>
Get-PnPWeb
```

If `Get-PnPWeb` returns the site title, authentication is sorted.

## Step 4 — Dry run

### If the repo lives in WSL

PowerShell treats `\\wsl$\...` as the internet zone, so running the script in place
trips the signing check. Copy it to a local path instead, and re-copy after every
edit — the Windows copy does not track the repo:

```powershell
cd C:\Users\mmole\projects\leadership
copy \\wsl$\Ubuntu\home\mark\projects\leadership-development\build\scripts\New-LdpSharePointLists.ps1 .
Unblock-File .\New-LdpSharePointLists.ps1
```

### Execution policy

An unsigned script needs the policy relaxed once. Least-invasive first:

```powershell
Get-ExecutionPolicy -List          # which scope is blocking?
Unblock-File .\New-LdpSharePointLists.ps1
```

If a scope shows `AllSigned` or `Restricted`, also run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

`CurrentUser` needs no admin rights and leaves machine policy alone. `RemoteSigned`
still blocks unsigned scripts that came from the internet.

### The dry run

Nothing is written. Confirm the plan is what you expect:

```powershell
./New-LdpSharePointLists.ps1 `
    -SiteUrl https://markmolesworth.sharepoint.com/sites/leadership-development-program `
    -ClientId <your-client-id> `
    -WhatIf
```

You should see `What if:` lines for 14 lists, ~90 columns, 16 lookups, and 22 indexes.
It still signs you in — `-WhatIf` suppresses the writes, not the connection.

## Step 5 — Run it

Same command without `-WhatIf`:

```powershell
./New-LdpSharePointLists.ps1 `
    -SiteUrl https://markmolesworth.sharepoint.com/sites/leadership-development-program `
    -ClientId <your-client-id>
```

Output is four passes, colour-coded: green `+` created, grey `=` already existed,
yellow `~` deliberately skipped. It ends with a summary and a to-do list.

**`ListsCreated 14` in the summary is the proof it worked.** A `-WhatIf` run prints
the same four passes but every line reads `What if:` and the summary is all zeroes —
which is easy to mistake for success.

The lists do **not** appear in the left-hand navigation: they are a backing store for
the app, not pages to browse. Find them under **Settings (gear) → Site contents**, or
pass `-ShowInNavigation` to put them in the left nav.

If it fails partway, **just run it again** — the script is idempotent. It checks for
each list and column before creating it, so a re-run picks up where it stopped.

## Step 6 — Verify

```powershell
Connect-PnPOnline -Url https://markmolesworth.sharepoint.com/sites/leadership-development-program -Interactive -ClientId <guid>

# 15 lists?
Get-PnPList | Where-Object { $_.Title -cmatch '^[A-Z_]+$' } | Select-Object Title, ItemCount

# Lookups wired to the right targets?
Get-PnPField -List APPLICATIONS | Where-Object TypeAsString -eq 'Lookup' |
    Select-Object InternalName, LookupList, LookupField

# Indexes actually applied?
Get-PnPField -List APPLICATIONS | Where-Object Indexed | Select-Object InternalName
```

Then open the site and confirm `APPLICATIONS` shows `CycleID`, `Status`, `RoutingStage`.

---

## What the script deliberately does NOT do

| Not done | Why |
|---|---|
| `AlternateSecondLineEmail` column, `Held For Alternate`, `Alternate Second Line`, `Alternate Designation` | All `[PROPOSED]`. Constitution I forbids transcribing them until DTD confirms. Re-run with `-IncludeProposed` after sign-off. |
| Seed `PROGRAMS` with NEXT / MDP / HPP | `PROGRAMS.md` says DTD populates these via the Program Options Screen. |
| `EMPLOYEE_DIRECTORY` | **Removed 2026-07-26.** Personnel data comes from an existing system (D-1); the interim list is not part of the design. The script no longer creates or manages it. If it already exists in SharePoint, removing it from the script does **not** delete it — see below. |
| Permissions on `CHANGE_HISTORY` | Must be a SharePoint permission, not a hidden control (Constitution VI / OI-7). Deferred. |
| Validation rules | Every rule in the list specs (one application per applicant per cycle, one Open cycle, four anchors before publish) is enforced in the **app layer**, not by SharePoint. |

## Decisions baked into the script

- **Yes/No columns are `Choice`, not SharePoint's native Yes/No.** The Power Fx
  already written reads `.Value` (e.g. `locSelected.State.Value`); a boolean column
  returns a bare true/false and every one of those formulas would need rewriting.
- **`ID` columns are never created.** SharePoint supplies `ID` automatically. The
  specs list it for completeness.
- **`Title` is set to not-required** on every list. None of these lists use it, and
  leaving it required makes Power Fx `Patch()` calls fail on a column the app never
  fills. It stays visible — hiding it outright causes odd behaviour in some views.
- **Multi-line columns are plain text, not rich text.** `CriterionScores` and
  `Details` hold JSON; rich text would wrap it in markup the app has to strip.
- **`NOTIFICATIONS.ApplicationID` and `CHANGE_HISTORY.ApplicationID` are Numbers,**
  not lookups — per `_RELATIONSHIPS_AND_INDEXES.md`, so the append-only logs survive
  parent-record changes.
- **Lookup `ShowField` is the readable column** of the target (e.g. `CycleID` shows
  `CycleName`). Power Fx still reads the key as `.Id`, so this costs nothing and makes
  the SharePoint UI usable.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `cannot be loaded. The file ... is not digitally signed` | Execution policy. Run `Unblock-File .\New-LdpSharePointLists.ps1`; if that is not enough, `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`. Recurs every time you re-copy the file from WSL. |
| `The term 'Connect-PnPOnline' is not recognized` | Step 2 skipped, or you are in Windows PowerShell 5.1 instead of `pwsh`. |
| `AADSTS65001: The user or administrator has not consented` | Step 3 not completed, or the client ID belongs to a different tenant. |
| `A parameter cannot be found that matches parameter name 'Interactive'` | You passed `-Interactive` to `Register-PnPEntraIDAppForInteractiveLogin`. It belongs to `Connect-PnPOnline` only. Drop it — see step 3. |
| Step 3 hangs with no browser | Re-run with `-DeviceLogin` and complete the code flow in any browser. |
| `Column limit exceeded` | The site already has lists of the same names from an earlier attempt with different schemas. Delete them (and empty the recycle bin) before re-running. |
| `Lookup target list 'X' does not exist` | Pass 1 partially failed. Re-run — pass 3 will not start until the target lists are there. |
| Lists created but no indexes | Re-run without `-SkipIndexes`. Indexing is idempotent and safe to reapply. |
| Everything says `= (exists)` | Already provisioned. That is the expected output of a second run. |

## Rollback

There is no undo. To start over:

```powershell
Connect-PnPOnline -Url https://markmolesworth.sharepoint.com/sites/leadership-development-program -Interactive -ClientId <guid>
'CHANGE_HISTORY','NOTIFICATIONS','PLACEMENTS','COMMITTEE_SCORES','RATING_CRITERIA',
'RATING_SHEETS','CRITERION_ANCHORS','CRITERION_CATALOG','SUPERVISOR_ENDORSEMENTS',
'APPLICATION_PROGRAM_CHOICES','APPLICATIONS','PROGRAM_OPTIONS',
'PROGRAMS','CYCLES' | ForEach-Object { Remove-PnPList -Identity $_ -Force }
```

The order matters — lists that are lookup *targets* cannot be deleted while a lookup
points at them, so this deletes children before parents. **This destroys all data in
those lists.** Only do it on a site you are certain is disposable.
