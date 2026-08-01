# Open issues

Known gaps deferred rather than forgotten. Screen-level issues are also marked inline in the YAML
at the point they bite, using the same ID — grep the ID to find every place it shows up.

Opened 2026-07-31. Add new items at the bottom of their section; do not renumber.

---

## OI-APP-1 — three document slots cannot be delivered

**Where:** `build/screens/ApplicationScreen.yaml` step 5; surfaced on `DTDApplicationsScreen.yaml`
Documents tab.
**What:** SharePoint attachments are a single undifferentiated collection on the list item. The
requirement (RQ009, FR-006) asks for three named slots — resume, statement of interest, performance
appraisal — and there is no way to label or read them back individually, nor to list them read-only
on the DTD panel.
**Status:** the Documents tab says so honestly rather than pretending. Step 6's checklist shows
"Not checked" for documents for the same reason.
**Likely fix:** a document library keyed to the application instead of list attachments. That is a
schema addition, not a screen change.

---

## OI-APP-2 — a saved draft does not restore its program choices

**Where:** `build/screens/ApplicationScreen.yaml` step 2 — `drpProgram1AP`/`drpOption1AP` through
`3AP`.
**What:** none of the six dropdowns defines a `Default`, so an applicant who saves a draft and comes
back gets three empty pickers. Every other field on the form restores, because they are text inputs
bound to `locApp`; only the choices do not. The screen's OnVisible already builds `colRanked` for
exactly this purpose and nothing reads it — one reference, in a comment.

**Why it was not just fixed:** a draft may reference a program or option that has since been
**retired**. Since 2026-07-31 the pickers filter to `State = "Active"`, and a `Default` pointing at
something absent from `Items` does not display — so the picker would come back empty for precisely
the applicant most likely to be confused by it. `PROGRAM_OPTIONS.md` already states the principle:
*a retired option must never appear as a new choice, but must still display on applications that
already chose it.*

**Likely fix:** `Items` becomes the union of the active set and whatever this draft already chose,
and `colRanked` is reshaped to carry `ProgramID` — it is still built around the option being the
choice, which stopped being true on 2026-07-31.

---

## OI-DTD-1 — two options under one program show the same score — CLOSED 2026-07-31

Closed by removing the score from the Program choices tab entirely. It keyed on PROGRAM while those
rows are per (program, option), so HPP ranked twice showed one score against two rows. The gallery
column on the table above already reports scoring progress with a `Distinct(... ProgramID.Id)`
denominator; this tab is about what was chosen.

---

## OI-DATA-1 — `Status` and `RoutingStage` are dead columns

**Where:** `APPLICATIONS` list.
**What:** superseded by `ApplicationStatus` / `ReviewStage` / `PlacementOutcome` on 2026-07-31.
Nothing reads them. They still exist because the migration deliberately separated the rewrite from
the drop.
**Fix:** run `build/scripts/Update-LdpApplicationStatus.ps1 -RemoveOldColumns`. No code change.

---

## OI-A11Y-1 — accessibility sweep (T081)

**Where:** app-wide; two known specifics.
**What:**
1. The four sort headers on `DTDApplicationsScreen` have `FocusedBorderThickness: =0` and so no
   keyboard focus ring — the only controls in the app without one. The ring was removed because the
   36px header container clipped its top and bottom edges, leaving left and right verticals that
   read as brackets. The fix is to give the container enough height to show a ring, not to put the
   3px back.
2. `DangerText` on `DangerLight` measures 4.4:1 — under AA for the 9pt text it is used at. Every
   other badge pair passes.

---

## OI-REQ-1 — two date fields with no requirement behind them

**Where:** `APPLICATIONS.NCUAStartDate`, `APPLICATIONS.ServiceComputationDate`.
**What:** both appear only in `docs/LDP_Logical_Data_Model.md`, with self-referential descriptions
("the applicant's service computation date"). Neither appears in
`LDP_Functional_Requirements_Phase_I.md` or `LDP_Use_Cases.md` — no RQ number, no use case — and
nothing in the app reads either for any decision, consistent with the FR doc excluding eligibility
enforcement.

**The live defect:** both date pickers on the Application Screen default to `Today()`, so an
applicant who never touches the field submits today's date. It is never blank, so nothing flags it,
and DTD sees a plausible value that is certainly wrong. Most people do not know their SCD offhand —
it is on an SF-50 — so "didn't touch it" is the common case, not the edge case.

**Decision needed** from whoever owns the requirements: drop the fields, keep them and default to
blank, or write down the requirement that justifies collecting them. Defaulting to blank is worth
doing for `NCUAStartDate` either way. The DTD panel's own editor already defaults to blank rather
than today.

**Note:** the data model and the functional requirements disagree here. `docs/LDP_Flagged_Inconsistencies.md`
exists for exactly this and does not mention it.

---

## OI-DATA-2 — `PROGRAMS.State` is blank on existing rows

**Where:** `PROGRAMS` list.
**What:** `State` (Active / Retired) was added after the three programs existed, and no script has
ever backfilled it — `Add-LdpProgramOptions.ps1` backfills `PROGRAM_OPTIONS.State` but nothing does
the same for `PROGRAMS`. Those rows hold blank, which is neither Active nor Retired.

**What it broke:** `Filter(PROGRAMS, State.Value = "Active")` returns nothing, so every program
dropdown came back empty — on the DTD edit panel and, briefly, on the applicant's step 2.

**Current workaround:** every program picker tests `State.Value <> "Retired"` instead. Correct
whether the row is Active or blank, and still excludes Retired. Both PowerShell scripts already
test it this way.

**Fix:** backfill `PROGRAMS.State = 'Active'` on the blank rows, then tighten the four pickers to
`= "Active"` to match the rule stated in `PROGRAMS.md` and `PROGRAM_OPTIONS.md`. Same shape as the
`PROGRAM_OPTIONS` backfill:

    Get-PnPListItem -List PROGRAMS -PageSize 500 |
      Where-Object { -not [string]$_['State'] } |
      ForEach-Object { Set-PnPListItem -List PROGRAMS -Identity $_.Id -Values @{ State = 'Active' } }

**Note:** `PROGRAM_OPTIONS.State` pickers were NOT changed — that column is backfilled, so
`= "Active"` there is safe and correct.
