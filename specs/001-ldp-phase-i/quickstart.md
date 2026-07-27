# Quickstart — Manual Validation Guide, LDP Application Phase I

> **`EMPLOYEE_DIRECTORY` withdrawn 2026-07-26.** Personnel and supervisor-chain data comes from an existing system of record (D-1). References to the interim list below are superseded; see `build/lists/EMPLOYEE_DIRECTORY.md`.

**Feature**: `001-ldp-phase-i` | **Date**: 2026-07-25

Nothing in this stack is machine-testable from the repository (Constitution IV). Validation is
**manual observation** by the maker against the spec's acceptance scenarios. This guide is the
walk-through for bringing work from *generated* → *verified*. A task closes at **verified**; formal
**acceptance** is DTD's at UAT (Constitution IV).

## Prerequisites

- A Power Apps environment on the NCUA M365 tenant (maker-managed; environment strategy is out of
  the agent's scope — Constitution).
- Permission to create SharePoint lists and a canvas app.
- The design artifacts in this folder: [`data-model.md`](./data-model.md),
  [`contracts/screens.md`](./contracts/screens.md), [`research.md`](./research.md).

## Definition of Done for each item (Constitution IV, V)

An item is **verified** when, in the dev environment:
1. Observed behavior matches the referenced acceptance scenario(s) in [`spec.md`](./spec.md).
2. The Power Apps **accessibility checker is clean** for the affected screen(s).
3. Screen names are plain language, spaced, ending in "Screen"; controls follow the naming
   convention (Constitution V; data-model/contracts).

> The agent does not mark anything verified or accepted — the maker does.

---

## Stage 1 — Create the SharePoint lists (data layer first)

Follow [`data-model.md`](./data-model.md). For each list #1–#15:

1. Create the list with the **exact `UPPER_SNAKE_CASE` name** (it becomes an unrenameable Power Fx
   identifier — Constitution v1.2.0).
2. Add columns in Pascal case with the specified types/required flags; enumerate the choice sets;
   leave competency/ECQ choices as placeholders pending Appendix B (D-2).
3. Mark the **indexed columns** listed in data-model.md (delegation — Constitution III).
4. Populate reference data via the admin screens once built (`PROGRAMS`, `PROGRAM_OPTIONS`,
   `CRITERION_CATALOG`); seed `EMPLOYEE_DIRECTORY` with a few test employees + supervisor chains,
   including one employee with **no** second-line supervisor (to exercise OI-6/FR-012a).

**Verify Stage 1:** every list exists with correct names/types/choices/indexes; a test query filtered
by `CycleID` returns without a delegation warning.

---

## Stage 2 — Build screens (component-first)

Follow [`contracts/screens.md`](./contracts/screens.md) in its stated build order. For each screen:

1. Discover suitable **PowerLibs** components (Constitution VIII); assemble from them, not primitives.
2. Bind galleries/forms to the lists; keep every gallery `CycleID`-scoped and delegable.
3. Rename each component to project convention on transcription.
4. Run the accessibility checker; resolve to clean.

### Representative validation walkthroughs (map to spec acceptance scenarios)

- **Admin setup (US6/US7/US8/US9):** create a cycle with valid dates → try invalid dates (blocked);
  open it → try opening a second cycle (blocked); add a program option missing a required attribute
  (blocked); define a criterion, publish (blocked until all four anchors present); build a rating
  sheet, publish, try unpublish after a score exists (blocked).
- **Submit (US1):** as a test applicant with an Open cycle, start an application → personnel fields
  populate from `EMPLOYEE_DIRECTORY` (or manual entry if absent); rank 1–3 options; enter 3 OPM + 3
  technical + 4 ECQ; attach resume/statement/appraisal (PDF/Word only) and a numeric latest rating;
  save Draft, reopen (data intact); submit → whole-application validation + confirmation; try a
  second application (blocked).
- **Endorse (US2):** submitted app appears in the first-line supervisor's queue view-only; record a
  decision without a statement (blocked); with a statement it advances to second line, showing the
  first decision; recommend alternative options (recorded, selections unchanged).
- **No-second-line (OI-6/FR-012a):** submit as the employee with no second-line supervisor → after
  the first-line decision it lands `Held For Alternate` on the DTD queue; DTD designates an alternate
  → it routes to that reviewer as a second-line endorsement.
- **Validate (US3):** after both decisions, DTD marks Complete (advances) or Incomplete (held, listed).
- **Score (US4):** with a Published sheet and the cycle In Review, score a pool using only 0/1/3/5
  (off-anchor rejected); scores persist across sessions; when the pool is fully scored it ranks and
  computes percent of possible.
- **Place (US5):** place a ranked applicant; place an already-placed applicant (transfers); finalize
  → placements lock, unplaced become not-selected.
- **Disposition (US11):** post-finalize, select all / individuals, send (writes `NOTIFICATIONS`;
  actual email is a deferred flow); sent/failed shown; resend warns first.

**Verify Stage 2:** each walkthrough behaves as the referenced scenario states; accessibility checker
clean on every screen touched.

---

## Deferred (not validated this pass — seams)

- **Personnel/hierarchy auto-load (D-1):** only manual entry + `EMPLOYEE_DIRECTORY` reads are
  exercised now; the loading mechanism is a later pass.
- **Notification & reminder flows (UC-5.1/5.2):** the app writing to `NOTIFICATIONS` is validated;
  sending/reminding (repeat-each-interval, OI-3) is a maker-built flow, later.
- **Committee/DTD/applicant access model (OI-7):** committee-scoring and change-history screens can
  be built and demoed but **MUST NOT be marked verified** until the SharePoint permission model
  enforces who sees which data (Constitution VI). Confirm confidentiality by testing what an account
  can *reach*, not what the interface shows.

## Traceability

Every screen and list cites its RQ/UC/FR anchors in `contracts/screens.md` and `data-model.md`
(Constitution I). Unsupported content, if any, must be marked **Proposed** and not transcribed until
DTD confirms.
