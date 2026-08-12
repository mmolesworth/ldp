# Open issues

Known gaps deferred rather than forgotten. Screen-level issues are also marked inline in the YAML
at the point they bite, using the same ID — grep the ID to find every place it shows up.

Opened 2026-07-31. Add new items at the bottom of their section; do not renumber.

---

## OI-APP-1 — supporting documents have no per-slot identity

**Where:** `build/screens/ApplicationScreen.yaml` step 5; surfaced on `DTDApplicationsScreen.yaml`
and `SupervisorEndorsementScreen.yaml` Documents tabs.
**What:** step 5 uses SharePoint's native item-attachment collection on the APPLICATIONS row.
Applicants can add multiple files, but they are one undifferentiated set — nothing distinguishes a
resume from a statement of interest from a performance appraisal. DTD cannot report which of the
three required documents (RQ009, FR-006) is missing; step 6's completeness checklist shows "Not
checked" for documents for the same reason.
**Status:** accepted 2026-08-11. The prior three-row `APPLICATION_DOCUMENTS` design solved this but
was replaced with the native collection to keep the applicant experience simple. Downstream screens
list attachments by file name.
**Likely fix (if reopened):** a document library keyed to the application, or reintroduce a
join list with a `DocumentType` slot.

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

---

## OI-APP-3 — step 2 dropdowns auto-select, so choices nobody made get written

**Where:** `build/screens/ApplicationScreen.yaml` step 2 — all six of
`drpProgram1AP`/`drpOption1AP` through `3AP`.
**What:** none sets `AllowEmptySelection: =true`. A `Classic/DropDown` with no matching `Default`
selects its **first item**, so second and third program choices arrive pre-filled with programs the
applicant never picked, and Submit writes them as real rows.

It also disables the submit gate: that test is `IsBlank(drpProgram1AP.Selected.ID)`, which can never
be true when the control always has a selection, so "at least one program choice is required" never
fires.

**Fix:** `AllowEmptySelection: =true` on all six. Same defect and same fix as the DTD panel's edit
dropdowns (2026-07-31).

---

## OI-APP-4 — step 3 writes to columns that no longer exist

**Where:** `build/screens/ApplicationScreen.yaml` step 3.
**What:** ten dropdowns — 3 OPM, 3 technical, 4 ECQ — with `Items: =Table()`, so they render empty.
They were built against `APPLICATIONS.OPMCompetencies` / `TechnicalCompetencies` / `ECQs`, which
were replaced by the `APPLICATION_COMPETENCIES` join list on 2026-07-31. The submit Patch never
wrote them either, so nothing is lost — but **an applicant still cannot record competencies at all**.

The counts are hardcoded 3/3/4 in the control layout, which contradicts the data-driven design:
types come from `COMPETENCY_TYPES` and the per-type ceiling from `SelectionCount`.

**D-2 IS RESOLVED.** The blocker was the missing vocabulary — "Appendix B". The 85-row catalogue
loaded into `COMPETENCIES` (OPM 17, ECQ 20, Technical 48) *is* that vocabulary. The header comment
in `ApplicationScreen.yaml` still says both blockers are open and is stale.

**Fix:** rebuild step 3 the way the DTD Competencies tab now works — a section per active type, a
picker capped at that type's `SelectionCount`, writing rows to `APPLICATION_COMPETENCIES`.

---

## OI-APP-5 — nothing enforces one application per applicant per cycle

**Where:** `build/screens/ApplicationScreen.yaml` — OnVisible lookup and both write paths.
**What:** `APPLICATIONS.md` states the rule (FR-011 / R8). Grep finds **zero** references to FR-011
or R8 in the screen, and nothing implements it. The two mechanics combine badly:

    OnVisible : locApp: LookUp(APPLICATIONS, And(CycleID.Id = ..., ApplicantEmail = User().Email))
    Save      : Patch(APPLICATIONS, If(IsBlank(locApp), Defaults(APPLICATIONS), locApp), ...)

If the lookup misses, `locApp` is blank and the save **creates a second application** instead of
updating the first. `LookUp` then returns whichever row SharePoint hands back first, silently.

**Made reachable on 2026-08-01** by making the email field editable: change the address, save,
return — the lookup no longer matches `User().Email`, and the next save mints a duplicate.

**Options, in preference order:**
1. Constrain the email to `User().Email` — block submit or revert on save. Keeps the field visible
   for confirmation without letting it diverge from the identity key.
2. Detect on save — if `locApp` is blank but an application already exists for this applicant and
   cycle, adopt it rather than creating one.
3. Add a `ContactEmail` column, leaving `ApplicantEmail` as the immutable key.

---

## OI-DATA-3 — join-table lookups display an ambiguous column

**Where:** `APPLICATION_PROGRAM_CHOICES.ApplicationID`, `APPLICATION_COMPETENCIES.ApplicationID`,
`SUPERVISOR_ENDORSEMENTS.ApplicationID` — all provisioned with `ShowField = 'ApplicantEmail'`.

**What:** NOT a data defect. A SharePoint lookup stores an integer `LookupId`; `ShowField` only
chooses what the list view renders. An applicant who applies in two cycles produces join rows that
all *display* the same email while storing different keys, and every app query uses
`ApplicationID.Id`, so nothing collides.

**The cost is readability.** Reading these lists in SharePoint, there is no way to tell which cycle
a row belongs to.

**Fix if wanted:** populate the unused `Title` column on APPLICATIONS on write — e.g.
`"sarah.chen@ncua.gov — Fall 2026"` — and repoint each lookup's `ShowField` at `Title`. Script
change plus one `Set-PnPField` per lookup. Purely cosmetic; no app formula changes.

---

## OI-ARCH-1 — no archive or retention design exists, and the constitution requires one

**Where:** whole application. Not a screen defect — a missing design.

**Constitutional standing.** This is not optional work:

- **Principle VII, Records Retention (NON-NEGOTIABLE)** — records MUST be retained and retrievable
  for **seven years**; retention covers supporting documents as well as list items; archiving MUST
  NOT delete records inside the retention period; access to archived records MUST satisfy
  Principle VI, with committee access scoped to the cycle being evaluated and NOT extending to
  prior cohorts.
- **Principle III** — every implementation plan MUST state how the design behaves as cycles
  accumulate and MUST include a retention or archive approach for closed cycles. *No design may
  assume the data set stays at the size of a single cycle.*

**Nothing addresses either today.** There is no archive process, no purge, no cold storage, and no
access scoping beyond the DTD screen's cycle filter — which is a convenience filter, not a
permission boundary.

**Volume over the retention period**, at 100 applications x 2 cycles = 200/year:

| List | 7-year rows |
|---|---|
| APPLICATIONS | 1,400 |
| APPLICATION_PROGRAM_CHOICES | 4,200 |
| APPLICATION_COMPETENCIES | 14,000 |
| COMMITTEE_SCORES | 4,200 |
| Supporting documents | 4,200 files, ~8 GB at 2 MB average |

**Query performance is NOT the driver.** Every one of those lists is indexed on `ApplicationID`
and every query filters on it, so they delegate and return single-digit row counts at any size.
SharePoint holds 30,000,000 items per list. The 5,000 figure is the threshold for *unindexed*
operations only.

**The real drivers are storage and records handling:**
- SharePoint list attachments cannot carry retention labels, cannot be versioned, and cannot be
  tiered. Principle VII requires the archive to preserve them, and attachments give no mechanism
  to satisfy a records schedule.
- ~8 GB of PII-bearing files accumulating in one site collection.
- Principle VI scoping is unimplemented: a committee member with access to the app today can reach
  any cycle's data through the data source, regardless of what the UI shows.

**Hard constraint to respect now, not later:** index `ApplicationID` on any new child list **at
creation**. Adding an index to a list already past 5,000 items is painful and sometimes requires
emptying it. Every existing join table already does this.

**When to design it:** before the second production cycle closes. The first cycle can run without
it; the migration cost rises with every cycle that accumulates, and retrofitting a document library
at 4,000 files is a project rather than a script.

---

## OI-APP-6 — the review step promises post-submission editing the app does not allow

**Where:** `build/screens/ApplicationScreen.yaml` — step 6 `lblS6WhatAP`, and 26 `DisplayMode`
gates across steps 1–5.

**What:** step 6 now tells the applicant *"You can still edit it until the committee begins its
review."* The application locks completely the moment it is submitted, so that sentence is
currently false. Copy was changed ahead of behaviour deliberately, on 2026-08-01, so the intent is
recorded — but it must not reach an applicant in this state.

**Three code changes make it true:**

1. **The 26 gates.** Every input on steps 1–5 tests
   `locApp.ApplicationStatus.Value <> "Draft"`. That must become a STAGE test — locked once
   `ReviewStage` reaches `Committee Review`, `Pending Placement`, `Pending Notification` or
   `Complete`, and always locked when `ApplicationStatus` is `Withdrawn`. All 26 share one
   expression, so it is a single substitution.
2. **Save draft would un-submit the application.** It writes
   `ApplicationStatus: { Value: "Draft" }` unconditionally. An applicant editing a submitted
   application and saving would drop it back to Draft and pull it out of the supervisor's queue.
   It must preserve the current status.
3. **An edit after submission must reset validation.** `Validated -> Submitted`, the rule already
   implemented on the DTD side and described in that screen's Clear validation modal. Without it,
   DTD's validation silently survives a change DTD never saw.

## OI-REQ-2 — does a supervisor endorsement survive a later applicant edit?

**Where:** requirements, not code. Raised by OI-APP-6.

**What:** RQ018–RQ021 cover the endorsement flow — supervisor records approve or disapprove, the
application advances regardless. Nothing states what happens if the applicant **edits the
application after an endorsement has been recorded**.

Allowing edits until committee review means a first-line supervisor can endorse a packet that then
changes underneath them. Three possible answers, none of them derivable from the source documents:

- the endorsement stands, and the change is simply visible to later reviewers;
- the endorsement is voided and the packet re-routes to that supervisor;
- edits are blocked once any endorsement exists, which narrows the window from "before committee
  review" to "before first-line endorsement".

**To confirm with the customer.** The third would change the copy in OI-APP-6 as well as the gates.

## OI-STAT-1 — may an applicant see their supervisor's endorsement decision?

**Where:** requirements, not code. Raised while building the Application Status screen, 2026-08-02.

**What:** `SUPERVISOR_ENDORSEMENTS` holds `Decision` (Approve / Disapprove) and a mandatory
`DispositionStatement` (FR-013) for each level. Steps 2 and 3 of the applicant's timeline are
exactly where someone would look for them, and the data is one `LookUp` away.

Nothing in RQ018–RQ025 says whether the applicant may see either. The decision is a policy one with
consequences the app cannot weigh: a written disapproval shown verbatim to the person it is about
changes what supervisors are willing to write, which is the opposite of what FR-013 is for.

**Built as:** stage only. The timeline says where the packet is and never what anyone said, and no
endorsement data is read by `ApplicationStatusScreen.yaml` at all.

**Three answers to put to DTD:** show nothing (current); show the decision but not the statement;
show both. The middle one is the likely compromise and is the cheapest to add — one label per step.

## OI-STAT-2 — no stage-transition dates

**Where:** `APPLICATIONS`, and the timeline on `ApplicationStatusScreen.yaml`.

**What:** `SubmittedDate` (added 2026-08-02) is the only timestamp an application carries. Nothing
records WHEN `ReviewStage` changed, so step 1 of the applicant's timeline can be dated and steps
2–6 cannot. The screen shows a bare state word instead — accurate, but noticeably thinner than a
dated history, and "how long has it been sitting with my supervisor" is the obvious next question.

`CHANGE_HISTORY` is the natural home: it already exists, already keys on the application, and
`ChangeType` would take a `Stage Advanced` value. The cost is a write on every transition and a
`Filter` per step on this screen.

**Not built.** Worth raising with DTD alongside OI-STAT-1, since both are about how much of the
review the applicant gets to see.

## OI-STAT-3 — the timeline now exists twice

**Where:** `conTimelineLD` (Landing Screen) and `conTimelineAS` (Application Status Screen).

**What:** both are the PowerLibs `timeline-progress` component over the same six-step model, and
both derive `locTimeStep` from an identical `Switch` in their screen's `OnVisible`. The duplication
is deliberate for now — the card is the glance, the screen is the detail — but the two must be kept
in step BY HAND. The `Needs Supervisor Assigned` defect fixed on 2026-08-02 is exactly the class of
bug this invites: it sat in the landing Switch unnoticed because nothing else exercised that map.

T083 (shared blocks become canvas components) is the real fix; the step map would move into one
component property. Until then, a change to either Switch is a change to both.

## OI-STAT-4 — withdrawal is now possible, but its rules are undefined

**Where:** `conDangerAS` / `conWdConfirmAS` on `ApplicationStatusScreen.yaml`, added 2026-08-02.

**What:** `APPLICATIONS.ApplicationStatus` has always carried a `Withdrawn` value and the status
screen has always rendered that state, but **nothing in the app could set it** — the value was
reachable only by editing the SharePoint list directly, which policy forbids. An applicant could
therefore be shown "This application was withdrawn" by a state no one could legitimately produce.

That gap is now closed. What is NOT settled, and was not derivable from the requirements:

1. **How late may an applicant withdraw?** Built as: while the application is live and
   `PlacementOutcome` is still `Decision Pending`. That boundary comes from the data model — once
   an outcome exists the applicant's action is `Placement Declined`, a value DTD owns. But an
   earlier cut-off is plausible: withdrawing part-way through `Committee Review` wastes panel time
   that has already been spent, and DTD may want the packet frozen once scoring starts.
2. **Is it reversible, and can they reapply?** THIS IS THE SHARP ONE, and the confirm copy now
   commits us to an answer. As of 2026-08-02 the dialog reads *"If you withdraw by mistake, contact
   the Division of Talent Development to reapply."* Nothing in the app makes that true:

   - **DTD cannot reverse it.** No control on any DTD screen sets `ApplicationStatus` back to
     `Submitted`. The Validate/Clear-validation pair moves between `Submitted` and `Validated`
     only.
   - **The applicant cannot start again.** FR-011 / R8 allows one application per applicant per
     cycle, and the Application Screen resolves the row by `(CycleID, ApplicantEmail)` — so a
     returning applicant loads the WITHDRAWN row, not a blank one. All 26 inputs on that screen gate
     on `ApplicationStatus <> "Draft"`, so the row opens read-only. There is no path to a second
     application and no path to editing the first.

   **Resolved in the copy, not in the design.** The "to reapply" sentence was removed the same day;
   the dialog now ends at *"This action can't be undone."*, which is the only claim the app can
   stand behind. That closes the false promise but leaves the underlying fact: **withdrawal is
   final within a cycle, and neither the applicant nor DTD can undo it.**

   Whether that is the intended policy is DTD's call. If it is not, the cheapest fix is a Reopen
   control on the DTD detail header, mirroring Clear validation — one button, one Patch, and the
   dialog copy can then say so.
3. **Is a reason captured?** No column exists and none is written. DTD may want one, in which case
   it is a new `APPLICATIONS` column and a field in the confirm dialog.
4. **Is anyone told?** No `NOTIFICATIONS` row is written. A supervisor sitting on an endorsement
   request for a withdrawn application will keep chasing it.
5. **Is it audited?** No `CHANGE_HISTORY` row. `ChangeType` has no value that fits and inventing one
   is Constitution I. `Post-Submission Modification` is the closest but means something else.

**What it writes today:** `ApplicationStatus` only. `ReviewStage` is deliberately left where it was
so the record still shows how far the packet reached; `PlacementOutcome` stays `Decision Pending`
because no decision was made.

**To confirm with the customer.** Item 4 bites first now that the copy is honest — an irreversible
action with no notification is how a supervisor ends up chasing a packet that no longer exists.
Item 2 is no longer a correctness bug, but "a withdrawal cannot be undone by anyone, ever" is a
policy DTD should agree to rather than inherit from an implementation gap.

## OI-SUP-1 — RQ018 still says "approve or disapprove"

**Where:** `docs/LDP_Functional_Requirements_Phase_I.md`, RQ018. Raised 2026-08-02.

**What:** `SUPERVISOR_ENDORSEMENTS.Decision` was renamed from `Approve` / `Disapprove` to
`Recommend` / `Not Recommend` (see `_CHOICES.md`). RQ018 still reads *"The system shall allow a
supervisor to record an endorsement decision of approve or disapprove."*

The requirement text is the customer's document, not ours, so it has not been edited. But the app
and the requirement now use different words for the same field, and whoever traces one against the
other will stop and check.

**The argument for the rename, to put to DTD:** a supervisor cannot grant a place in the programme —
DTD and the committee decide. RQ021 already says the packet advances regardless of the supervisor's
answer, so "disapprove" never blocked anything. The column always held an opinion.

**Ask DTD to reword RQ018**, or to reject the rename, in which case
`Update-LdpEndorsementDecision.ps1` reverses cleanly by swapping the map — nothing else reads the
column yet.

## OI-SUP-2 — three compromises in the Supervisor Endorsement screen

**Where:** `build/screens/SupervisorEndorsementScreen.yaml`, built 2026-08-02.

**1. The decision is two buttons, not a radio group.** `btnRecSE` / `btnNotRecSE` toggle a
`locDecisionSE` context variable and style themselves from it. A `Classic/Radio` would be the
semantically correct control and would announce "1 of 2" to a screen reader; two buttons announce
only their own labels, so the mutual exclusivity is visual rather than programmatic (WCAG 1.3.1).
It was built this way because no screen in the app uses `Classic/Radio` yet and guessing a control
version costs a failed paste (PA2107). Swapping it is a contained change — two controls and the
`locDecisionSE` reads — and is worth doing before the app goes near a 508 review.

**2. `RecommendedOptions` is newline-delimited text, not a relationship.** RQ025 wants the
recommended options captured with who and when. Who and when are columns; WHAT is a
`Multiple lines of text` field, so the screen writes `Concat(colSuggestSE, Label, Char(10))` —
strings like `HPP — Credit`. The picker is structured at entry (it reads `PROGRAM_OPTIONS`), but
what lands in SharePoint is prose.

That means DTD's placement screen cannot join a supervisor recommendation to a `PROGRAM_OPTIONS`
row, and renaming an option silently orphans every recommendation naming it. The fix is a
`SUPERVISOR_RECOMMENDED_OPTIONS` join list keyed on the endorsement and the option — the same shape
as `APPLICATION_COMPETENCIES`, for the same reason. Not built, because the column exists and the
requirement does not say the recommendation must be machine-readable.

**3. Nothing is notified.** UC-2.1 step 5 says the system advances the application AND notifies the
next reviewer, calling UC-5.1. `btnSubmitSE` does the first half only: it advances `ReviewStage` and
writes nothing to `NOTIFICATIONS`. Phase I has no flow, and this is the same gap as OI-STAT-4 item 4
— a second-line supervisor is never told a packet is waiting for them, so the only way they find
out is the landing reviewer strip.

**Also worth confirming:** the "not yet your turn" gate is an interpretation. UC-2.1 preconditions
allow the second line to act once a first-line disposition is recorded; the screen therefore blocks
the second line while `ReviewStage` is still `Pending First-Line`, showing the application but not
the form. Nothing states whether a second-line supervisor may record ahead of the first.

---

## OI-SUP-3 — Studio bakes formula-based Y and Height into fixed numbers on paste

**Where:** `build/screens/SupervisorEndorsementScreen.yaml` (and `.paste.yaml`) — every top-level
container that participates in the queue-accordion push chain.
**What:** Power Apps Studio, on paste and on some subsequent interactions (drag/nudge in the
canvas, coming back from a preview session, certain reorder ops), silently rewrites
formula-based `Y` and `Height` properties into snapshot numeric literals. Once baked, the property
no longer reacts to `locQueueOpen`, so expanding the queue accordion pushes some controls down but
leaves others in place, breaking the layout.

**Repro pattern:** paste the screen YAML → each Y is initially a formula → toggle the queue
accordion in preview → return to design view → open `conAppSE.Y` (or any downstream container's Y)
in the properties pane → it is now a fixed number.

**Workaround required every paste:** manually re-paste each of the six formulas below on the
container's `Y` (or `Height`) property. There is no source-side fix; the file on disk is correct,
Studio's app tree is the divergent copy.

| Control | Property | Formula |
| --- | --- | --- |
| `conQueueSE` | `Height` | `=If(locQueueOpen, 64 + Min(4, CountRows(colSupAppsSE)) * 64, 48)` |
| `conHeaderSE` | `Y` | `=132 + If(locQueueOpen, 16 + Min(4, CountRows(colSupAppsSE)) * 64, 0)` |
| `conAppSE` | `Y` | `=240 + If(locQueueOpen, 16 + Min(4, CountRows(colSupAppsSE)) * 64, 0)` |
| `conDecisionSE` | `Y` | `=240 + If(locQueueOpen, 16 + Min(4, CountRows(colSupAppsSE)) * 64, 0)` |
| `conNoneSE` | `Y` | `=240 + If(locQueueOpen, 16 + Min(4, CountRows(colSupAppsSE)) * 64, 0)` |
| `conPriorSE` | `Y` | `=656 + If(locQueueOpen, 16 + Min(4, CountRows(colSupAppsSE)) * 64, 0)` |

Formulas are already "inlined" — each depends only on `locQueueOpen` (context variable) and
`CountRows(colSupAppsSE)` (collection function), never on another control's Y/Height. This is
the pattern that survives baking longest, because there is no cached cross-control snapshot for
Studio to fall back on. Even so, some Studio versions still bake them after preview sessions.

**Constants embedded in the formulas:**
- `132` = `conQueueSE.Y` (72) + `conQueueSE.Height` closed (48) + gap (12).
- `240` = `conHeaderSE.Y` closed (132) + `conHeaderSE.Height` (88) + gap (20).
- `656` = `conAppSE.Y` closed (240) + `conAppSE.Height` (400) + gap (16).
- Row height inside the queue gallery is `64`, hence `* 64` throughout.

If any of `conAppSE.Height`, `conHeaderSE.Height`, or `galQueueSE.TemplateSize` changes, all six
formulas need to be recomputed.

**Other places manual paste has been required after Studio baked values:**
- `galQueueSE.Y`, `recQueueDividerSE.Y`, `icoQueueChevronSE.Y` — the inner children of `conQueueSE`.
  These use `lblQueueHeaderSE.Y + lblQueueHeaderSE.Height` (+ offsets); when Studio bakes them,
  the gallery renders on top of the header title.
- `conSuggestBlockSE.Y` in the recommendation rail — same shape (`=lblSuggestTitleSE.Y +
  lblSuggestTitleSE.Height`).

**Longer-term fix:** convert the reactive Y/Height chain to App-level Named Formulas (App →
Formulas). Named Formulas are the only Power Fx surface that cannot be baked to a literal by
Studio, because they live at the app scope rather than the control scope. Not adopted because it
would require the whole team to opt into Named Formulas as the project's positional convention
and refactor the other screens that use control-to-control references. Filed for the day the
constant re-pasting stops being tolerable.
