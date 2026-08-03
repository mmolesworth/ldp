# Build Conventions — LDP Application Phase I

**Feature:** `001-ldp-phase-i` | **Generated:** 2026-07-25
Sourced from `.specify/memory/constitution.md` (v1.2.0), `data-model.md`, and `build/theme/theme.md`.

## Technology envelope (Constitution II — NON-NEGOTIABLE)

- Power Apps **canvas** app; **classic controls only**. In YAML, interactive controls use the
  `Classic/*` types: `Classic/Button@2.2.0`, `Classic/DropDown@2.3.1`, `Classic/DatePicker@2.5.0`,
  `Classic/Toggle@2.1.0`, `Classic/Icon@2.5.0`. Shared containers/primitives:
  `GroupContainer@1.4.0` (AutoLayout/ManualLayout), `Label@2.5.1`, `Gallery@2.15.0`,
  `TextInput@0.0.54`, `Rectangle@2.3.0`, `Image@2.2.3`, `HtmlViewer@2.1.0`.
- **No modern controls.** Do not enable "Modern controls and themes"; do not use modern/Fluent v9
  controls or the Creator Kit theme.
- **SharePoint lists** are the only data store. **No premium connectors.** Flows are built manually
  by the maker.

## Naming

- **SharePoint list names:** `UPPER_SNAKE_CASE` (e.g., `APPLICATION_PROGRAM_CHOICES`) — unrenameable
  Power Fx identifiers; settle before creating. **Column names:** Pascal case (e.g., `ApplicantEmail`).
- **Controls:** camel case, 3-char type prefix, then purpose; unique app-wide. Prefixes:
  `lbl` label · `btn` button · `txt` text input · `drp` dropdown · `dtp` date picker · `gal` gallery
  · `con` group container · `rec` rectangle · `ico` icon · `img` image · `htm` HTML viewer
  · `cmp` reused component. Reused-across-screens controls take a short screen suffix
  (e.g., `galApplicationsDTD`).
- **Variables:** `gbl` global, `loc`/context via `UpdateContext`; **collections:** `col`.
- **Screens (Constitution V):** plain language, include spaces, **end with "Screen"** (screen
  readers announce them) — e.g., "Application Cycles Screen". Screen YAML file names drop spaces:
  `ApplicationCyclesScreen.yaml`.

## Theme (colour & type — Constitution V, VIII)

- Apply `Set(ColorPalette, …)` and `Set(Typography, …)` from `build/theme/theme.md` in `App.OnStart`.
- Reference `ColorPalette.*` / `Typography.*`; **never hardcode** a colour/font/size/weight.
- Status **text/icons** use `SuccessText`/`WarningText`/`DangerText`; base `Success`/`Warning`/`Danger`
  are fills/badge backgrounds only. `TextSecondary` = large text only; `TextHelp` = help/disabled
  labels; `TextMuted` = decorative placeholders only.
- **Font size — RECONCILED (2026-07-25):** `theme.md`'s type scale was derived from an HTML px
  reference; Power Apps canvas point sizes are smaller (PowerLibs guidance: headings ≤14, body ~9–12).
  The scale is now expressed directly in canvas points — title 14 / heading 14 / subtitle 12 /
  body 11 / label 11 / caption 9 — so `Typography.*` is used as-is with **no per-screen mapping**.
  Nothing exceeds 14; nothing meaningful drops below 9. Family is `Lato` (built in; `Open Sans` is
  the fallback swap).

## Components (Constitution VIII)

- Assemble screens from **PowerLibs** components (see `build/POWERLIBS_COMPONENTS.md`); prefer a
  library component over primitives; rename to project convention on transcription; justify any
  bespoke control. Reused library components remain subject to Constitution V (accessibility).

## Delegation (Constitution III)

- Every gallery/lookup filters by an **indexed, `CycleID`-scoped** predicate first; no screen loads
  an unfiltered list. Indexed columns are listed in `build/lists/_RELATIONSHIPS_AND_INDEXES.md`.

## YAML safety (from PowerLibs syntax guide)

- Every expression starts with `=`; space after the colon (`Fill: =…`).
- Any expression containing `{ }`, `Table(`, colons in strings, or concatenation uses the `|-`
  pipe-strip block form (prevents parser error PA1001).
- `OnSelect` (not OnClick); `Launch()` for links (no href); semicolons separate statements.
- `Classic/Button` is text-only (no Icon prop) — icon buttons = `Classic/Icon` + transparent
  `Classic/Button` overlay. `TextInput` has no HintText/Default/Size — labels are separate.

## Shared paste blocks (`build/screens/_*.yaml`)

Files whose name starts with `_` are **not screens**. They are chrome pasted into
several screens, one copy per screen:

| File | What | Paste |
|---|---|---|
| `_UtilityBar.yaml` | App name · signed-in user · the two role links | **first**, on applicant screens |
| `_AdminShell.yaml` | Collapsible sidebar + `conMainArea` | **first**, on administration screens; paste screen content **inside `conMainArea`** |
| `_NavBar.yaml` | Mega-menu navigation | not in use — see LANDING_DESIGN.md |

The two shells are mutually exclusive: `_UtilityBar` for applicant-facing screens
(Landing, Application), `_AdminShell` for DTD screens. Never both on one screen.

Rules:
- Paste a shared block **before** the screen's own controls, so it sits at the top.
- Studio auto-suffixes duplicate names on the second and later screens
  (`conUtilityBar_1`, `_2` …). **Leave the suffixes alone** — nothing references
  these controls by name, and renaming them by hand only creates drift.
- Never reference a control inside a shared block from screen-specific YAML. The
  suffixes make such a reference resolve on one screen and fail on the next.
- Change the shared file, then **re-paste every screen that uses it**. There is no
  live link. Converting these to real canvas components is T083.

## Studio-verified corrections (supersede the PowerLibs guide where they conflict)

Learned from real paste failures; PowerLibs does not document these. Check here before debugging.

- **`Classic/Button` has no `AccessibleLabel`** (PA2108). A button's accessible name **is** its
  `Text`. For a button that must be visually text-free (gallery row overlays, icon-button overlays),
  put the name in `Text` and set `Color` + `HoverColor` + `PressedColor` to `RGBA(0, 0, 0, 0)` —
  announced by screen readers, invisible on screen. Never ship a `Text: =""` button.
- **Control versions in this environment** are ahead of PowerLibs' output. Bump on transcription:
  `GroupContainer@1.5.0` (guide says 1.4.0) · `Classic/DatePicker@2.6.0` (guide says 2.5.0).
  A stale version is a PA2105 *warning*, not an error — Studio substitutes the current one — but
  "may produce errors," so declare the real version.
- **PnP and Power Fx read columns in mirror-image ways.** In PnP.PowerShell a **Choice** column
  comes back as a plain string, and a **Lookup** comes back as an object (`.LookupId` /
  `.LookupValue`). In Power Fx it is the reverse shape that trips you: a choice needs `.Value` and a
  lookup needs `.Id`. So a predicate copied from a screen into a script fails with
  *"The property 'Value' cannot be found on this object"*:

  | | PnP.PowerShell | Power Fx |
  |---|---|---|
  | Choice | `[string]$_['State']` | `ThisItem.State.Value` |
  | Lookup | `$_['CycleID'].LookupId` | `ThisItem.CycleID.Id` |
  | Lookup label | `$_['CycleID'].LookupValue` | `ThisItem.CycleID.Value` |

  Cast choices with `[string]` rather than comparing directly — it also survives a null.
- **`Add-PnPViewField` does not exist in PnP.PowerShell.** It was a cmdlet in the retired
  SharePointPnPPowerShellOnline module and still appears in most search results. The replacement is
  `Set-PnPView -Fields`, which **replaces** the view's column list rather than appending — so read
  `$view.ViewFields` first, add to it, and write the whole set back. If that read returns empty,
  do nothing: writing a one-element list wipes every other column off the default view.
  A lookup created by `Add-PnPFieldFromXml` needs this, or it exists and is queryable but is
  invisible in the SharePoint UI.
- **PowerLibs `calendar-1` ships three defects.** Found 2026-07-26 building the Application Cycles
  Screen; fix all three on transcription:
  1. It emits a `Screens:` wrapper, which Studio cannot paste at all. Strip it.
  2. Its month-nav buttons read and write `_minDate` / `_maxDate`, **which the component never
     defines** — leftovers from a date-range variant. They silently create junk globals. Delete
     both lines.
  3. `Variant: WeekdayGallery` / `MonthDayGallery` are built-in calendar-template variant names,
     not documented gallery variants. Use `Variant: Vertical` with `WrapCount: =7`.

  It also drives a single date through **shared** variables, so two instances on one screen fight
  over month state and selection. For multiple date fields use ONE instance as a popover plus a
  target variable naming the field being set (see `ApplicationCyclesScreen.yaml`).
- **Patching a SharePoint Lookup needs the OData type annotation.** `{ Id: …, Value: … }` alone is
  **silently dropped** — the row saves with an empty lookup, no error. Always:
  ```
  ColumnID: {
    '@odata.type': "#Microsoft.Azure.Connectors.SharePoint.SPListExpandedReference",
    Id: <parent record>.ID,
    Value: <parent record>.<the lookup's ShowField>
  }
  ```
  `Value` must match the lookup's **ShowField** (see `_RELATIONSHIPS_AND_INDEXES.md`), not an
  arbitrary column. This produced orphaned `CRITERION_ANCHORS` rows before it was caught.
- **Never name a column after a built-in SharePoint field.** SharePoint ships hidden system fields
  with human display names, and Power Apps binds by display name. A collision is **silent**: the
  provisioning script's existence check finds the built-in, reports the column as already present,
  and never creates it — the failure surfaces much later as an unresolvable field in Power Fx.
  Avoid: `Version` (built-in `_UIVersionString`), `Created`, `Modified`, `Created By`, `Modified By`,
  `Title`, `Attachments`, `Content Type`, `Edit`, `Type`. `RATING_SHEETS.Version` hit this and is
  now `SheetVersion`. Audit with the script's `-WhatIf`, which lists genuinely missing columns.
- **`Classic/DropDown.Value` is an OUTPUT, not an input.** It reports the selected value; it cannot
  be set from YAML to choose which column displays. Bind `Items` to the table, set the display
  column in Studio's property panel, and read `drp….Selected.<field>` in formulas — `Selected`
  returns the whole record regardless of what is displayed. `Items: =Choices(LIST.Column)` needs
  no display column at all (single-column table).
- **Screens are not pasteable.** Studio's paste target takes a list of root controls only; a
  `Screens:` node or a screen name with spaces fails. Create + rename the screen by hand, set its
  `Fill`/`OnVisible` in the property panel, then paste the controls. Screen YAML files therefore
  carry a transcription header, not a `Screens:` wrapper.

## Control versions — one per type, app-wide (PA2107)

Power Apps refuses a paste when two instances of the same control type name different versions:

    error PA2107 : Another instance of control type 'Classic/DatePicker' has already been
    referenced using a different version '2.5.0'.

This is **app-wide, not per screen** — a version pasted from one screen constrains every other
screen pasted into the same app. Copying a control block from one screen to another carries its
version with it, which is exactly how it happens.

Studio also warns separately when a pinned version is behind the current one (PA2105) and silently
uses the current one instead, so a stale pin is worth fixing rather than keeping.

Check before pasting:

    grep -rho "Control: [A-Za-z/]*@[0-9][0-9.]*" build/screens/*.yaml | sort -u | \
      sed 's/@.*//' | sort | uniq -d

Any output names a type pinned at two versions. Bump all of them to the newest.

**Current pins (2026-08-01):** Circle 2.3.0 · Classic/Button 2.2.0 · Classic/DatePicker 2.6.0 ·
Classic/DropDown 2.3.1 · Classic/Icon 2.5.0 · Classic/TextInput 2.3.2 · Classic/Toggle 2.1.0 ·
Gallery 2.15.0 · GroupContainer 1.5.0 · Image 2.2.3 · Label 2.5.1 · Rectangle 2.3.0
