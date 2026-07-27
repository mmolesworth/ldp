# Implementation Plan: LDP Application — Phase I

> **`EMPLOYEE_DIRECTORY` withdrawn 2026-07-26.** Personnel and supervisor-chain data comes from an existing system of record (D-1). References to the interim list below are superseded; see `build/lists/EMPLOYEE_DIRECTORY.md`.

**Branch**: `001-ldp-phase-i` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-ldp-phase-i/spec.md`

**Planning directive (this run):** Focus first on **defining the SharePoint lists** and **building the
screens**. Power Automate flows, HR Links / org-hierarchy integration (D-1), and the committee
access model (OI-7) are scoped as **deferred** work here — designed enough not to block the data
layer and screens, but not built in this pass.

## Summary

Phase I delivers a Power Apps **canvas** application over **SharePoint lists** that carries an LDP
application through Submit → Endorse → Validate → Score → Place → Notify, plus DTD administration
(programs, cycles, rating sheets, criterion catalog). This plan establishes the **data layer**
(the SharePoint list roster, finalized names and columns, choice sets, delegation and retention
posture) and the **screen inventory** (a component-first canvas UI assembled from the PowerLibs
library), so the maker can create lists and transcribe screens next. Integration surfaces
(personnel/hierarchy loading, notification/reminder flows) are designed as seams and deferred.

The application source is authored as **YAML** and transcribed manually by the maker; **flows are
built manually** by the maker from agent-produced instructions (Constitution II, IV).

## Technical Context

**Language/Version**: Power Fx (Power Apps canvas app); application source authored as **YAML**
(Constitution II). No general-purpose programming language.

**Primary Dependencies**: Power Apps **classic controls only**; **PowerLibs** component library
(via the PowerLibs MCP) as the source of pre-designed components (Constitution VIII); Microsoft 365
identity (email as identity). **Theme:** NCUA palette at `docs/design/color-palette.html` → derived
tokens at `build/theme/theme.md`, applied as the classic `ColorPalette` variable in `App.OnStart`
(modern/Creator Kit theme paths excluded per Constitution II).

**Storage**: **SharePoint lists** (Constitution II). Supporting documents are native SharePoint
attachments on the `APPLICATIONS` item. No Dataverse.

**Testing**: No machine-testable surface exists in this stack (Constitution IV). Validation is
**manual acceptance** against observable behavior; the Power Apps **accessibility checker** must be
clean before any feature reaches *verified* (Constitution V). See `quickstart.md`.

**Target Platform**: Power Apps canvas app (browser + Power Apps mobile), Microsoft 365 tenant.

**Project Type**: Low-code line-of-business application (canvas over SharePoint).

**Performance Goals**: Screens remain responsive against multi-cycle data volumes; all gallery/
query operations delegable, or explicitly bounded (Constitution III — see Delegation & Volume).

**Constraints**: **No premium connectors** (Constitution II); WCAG 2.1 AA / Section 508
(Constitution V); confidentiality enforced at the SharePoint permission layer (Constitution VI);
**seven-year** records + attachment retention (Constitution VII).

**Scale/Scope**: One Open cycle at a time; a cycle pools ~3 programs / ~9 program options; ~7
years of accumulated cycles must remain queryable and retrievable. ~18–20 screens; 15 SharePoint
lists (13 from the data model + 2 build-support lists — see `data-model.md`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Gate for this plan | Status |
|---|---|---|---|
| I | Grounding in Source Requirements | Every screen and list traces to RQ/UC/FR anchors; no invented behavior. | ✅ Pass — contracts/data-model cite anchors. |
| II | Fixed Technology Envelope (NON-NEG) | Canvas, classic controls, SharePoint, no premium connectors, YAML, manual flows. | ✅ Pass — no alternative proposed; D-1 solved without a premium connector (research). |
| III | Performance at Volume | Plan states delegation posture and a retention/archive approach for closed cycles. | ✅ Pass — see Delegation & Volume and Retention below. |
| IV | Definition of Done | Plan produces generated artifacts only; acceptance is manual; agent marks nothing verified. | ✅ Pass — quickstart is a manual guide. |
| V | Accessibility (NON-NEG) | Screen naming + accessible labels + checker-clean gate defined. | ✅ Pass — encoded in contracts/screens.md. |
| VI | Confidentiality at Data Layer (NON-NEG) | Restrictions named at the permission layer, not the interface. | ⚠ Conditional — committee/DTD/applicant visibility rests on the access model (OI-7), **deferred**. Committee-scoring and change-history screens MUST NOT be marked verified until the SharePoint permission model is defined. Recorded, not violated. |
| VII | Records Retention (NON-NEG) | 7-year retention incl. attachments; archive never deletes in-window. | ✅ Pass — see Retention & Archive. |
| VIII | Component Reuse | Screens assembled from PowerLibs components; classic; renamed to convention. | ✅ Pass — encoded in contracts/screens.md. |

**Result:** Gate passes. The only conditional is Constitution VI, which is a **deferred detail
(OI-7)**, not a design that enforces confidentiality in the interface. It is tracked as a
verification gate on the committee and change-history screens, not a violation. See Complexity
Tracking.

## Delegation & Volume (Constitution III)

- **Data grows without bound across cycles.** Every gallery and lookup MUST filter by the active
  `CycleID` first and MUST be delegable. Delegable building blocks: filter/lookup on indexed
  columns (`CycleID`, `ApplicantEmail`, `ProgramID`, `Status`), `StartsWith`, `=`.
- **Known non-delegable risks** (resolved in `research.md`): ranking a pool by `FinalScore` (sort
  over a filtered set), "every applicant in the pool is scored" completeness checks, and cross-pool
  percent-of-possible comparisons. Each is bounded to a **single program pool within one cycle**
  (tens, not thousands, of rows), which is safe under the 500/2000-row operised limit. Any such
  operation is called out per screen in `contracts/screens.md`.
- **No screen may load an unfiltered list.** Galleries page from a `CycleID`-scoped, indexed query.
- **Indexed columns** are specified per list in `data-model.md`.

## Retention & Archive (Constitution VII)

- Application records **and their attachments** (resume, statement of interest, performance-rating
  appraisal) are retained **seven years** from cycle close.
- **Archive is a performance measure, not deletion.** Closed-cycle data is moved out of the hot
  query path (see `research.md` for the pattern) but never deleted inside the retention window, and
  archived records remain retrievable and still satisfy Constitution VI.
- This plan **defines** the retention/archive posture; building the archive mechanism is sequenced
  after lists + core screens (it depends on a closed cycle existing).

## Project Structure

### Documentation (this feature)

```text
specs/001-ldp-phase-i/
├── plan.md              # This file (/speckit-plan output)
├── research.md          # Phase 0 — plan-level decisions (delegation, D-1 seam, versioning, archive)
├── data-model.md        # Phase 1 — SharePoint list roster: final names, columns, choices, indexes
├── quickstart.md        # Phase 1 — manual validation guide (list creation + screen walkthroughs)
├── contracts/
│   └── screens.md       # Phase 1 — screen inventory + per-screen UI contract (the "interface contract")
└── tasks.md             # Phase 2 — /speckit-tasks (NOT created here)
```

### Build output (repository root) — where generated artifacts land for the maker

```text
build/
├── lists/               # One SharePoint list definition spec per list (for manual creation)
└── screens/             # One canvas screen YAML per screen (for manual transcription)
```

**Structure Decision**: This is a low-code canvas app, not a compiled codebase, so there is no
`src/` tree. Design artifacts live under `specs/001-ldp-phase-i/`; the **generated, transcribable
output** (list definitions and screen YAML) lands under a top-level `build/` directory, split
`lists/` and `screens/` to mirror the two things the maker creates by hand. `/speckit-tasks` will
populate `build/` file-by-file.

## Work Sequencing (this plan's phasing of the build)

Per the directive, the build is ordered lists → screens → integration:

1. **Data layer first.** Create the 15 SharePoint lists from `data-model.md` (final `UPPER_SNAKE`
   names, Pascal columns, choice sets, indexed columns, relationships). This unblocks everything.
2. **Screens second.** Assemble screens from PowerLibs components (Constitution VIII), bound to the
   lists, in value-stream order matching the spec's P1 stories, then P2. Read/enter data directly
   against lists; stub the seams below.
3. **Deferred (designed as seams, not built this pass):**
   - **D-1 — personnel/hierarchy loading** and **supervisor snapshot** (research records the
     non-premium seam: a maker-maintained `EMPLOYEE_DIRECTORY` list; manual entry fallback).
   - **Notification & reminder flows** (Power Automate, built manually by the maker from later
     agent-produced instructions).
   - **OI-7 — committee/DTD/applicant access model** (SharePoint permissions + M365 groups),
     required before committee-scoring and change-history screens can be *verified*.

## Complexity Tracking

No Constitution **violations** requiring justification. Two items tracked as design notes:

| Item | Why it exists | Handling |
|------|---------------|----------|
| New DTD "designate alternate second-line reviewer" capability (FR-012a) | Resolves OI-6 (no second-line supervisor) — behavior not in the original RITM. | Adds a routing sub-state + assigned-reviewer fields on `APPLICATIONS` (data-model.md); a DTD action on the validation/queue screen. Grounded via Clarifications 2026-07-25. |
| Interim personnel/hierarchy source (`EMPLOYEE_DIRECTORY` staging list) | HR Links retrieval must avoid premium connectors (Constitution II); final mechanism deferred (D-1). | Build-support list defined now so screens have data to bind; the loading mechanism is deferred, manual entry remains the fallback (RQ003). |
