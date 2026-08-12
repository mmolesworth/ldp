# Data Model — LDP Application Phase I (SharePoint build spec)

> **`EMPLOYEE_DIRECTORY` withdrawn 2026-07-26.** Personnel and supervisor-chain data comes from an existing system of record (D-1). References to the interim list below are superseded; see `build/lists/EMPLOYEE_DIRECTORY.md`.
>
> **`COMMITTEE_SCORES` retired 2026-08-07.** Aggregate moved onto `APPLICATION_PROGRAM_CHOICES`; per-criterion detail on `COMMITTEE_CRITERION_SCORES`. **`PLACEMENTS` retired 2026-08-11** — final placement is `APPLICATIONS.PlacementProgramID` / `PlacementOptionID`. `build/lists/` is the source of truth.

**Feature**: `001-ldp-phase-i` | **Date**: 2026-07-25

This is the **buildable** list roster for the maker to create in SharePoint. It finalizes names and
key columns and layers the Phase-I decisions (clarifications + research) onto the logical model in
[`docs/LDP_Logical_Data_Model.md`](../../docs/LDP_Logical_Data_Model.md), which remains the
authoritative source for full field tables. **Where this file and the logical model differ, the
callouts here (ADD/CHANGE) win** because they carry spec clarifications.

**Naming (Constitution v1.2.0):** list names `UPPER_SNAKE_CASE`; column names Pascal case. List
names become unrenameable Power Fx identifiers — create them exactly as written.

---

## List roster

| # | List (UPPER_SNAKE) | Create now? | Purpose | Base table |
|---|---|---|---|---|
| 1 | `CYCLES` | Yes | Application cycle: state + key dates | docs §CYCLES |
| 2 | `PROGRAMS` | Yes | NEXT / MDP / HPP | docs §PROGRAMS |
| 3 | `PROGRAM_OPTIONS` | Yes | Selectable options under programs | docs §PROGRAM_OPTIONS |
| 4 | `APPLICATIONS` | Yes | Central application record (+ routing fields, ADD) | docs §APPLICATIONS |
| 5 | `APPLICATION_PROGRAM_CHOICES` | Yes | Ranked program-option selections | docs |
| 6 | `SUPERVISOR_ENDORSEMENTS` | Yes | Per-supervisor decision/statement/recommendation | docs |
| 7 | `RATING_SHEETS` | Yes | Per-program, per-cycle immutable versioned sheet | docs |
| 8 | `RATING_CRITERIA` | Yes | Criteria selected onto a sheet version | docs |
| 9 | `CRITERION_CATALOG` | Yes | Shared master criteria | docs |
| 10 | `CRITERION_ANCHORS` | Yes | Four 0/1/3/5 anchors per criterion | docs |
| 11 | `COMMITTEE_SCORES` | Yes | Per-program score (hybrid) | docs |
| 12 | `PLACEMENTS` | Yes | DTD placement into a program option | docs |
| 13 | `NOTIFICATIONS` | Yes | Append-only send log (written by app; flows send) | docs |
| 14 | `CHANGE_HISTORY` | Yes | Append-only audit trail | docs |
| 15 | `EMPLOYEE_DIRECTORY` | Yes (build-support, **ADD**) | Personnel + supervisor chain source (R1) | new |
| — | `APPLICATIONS_ARCHIVE` (+ child archives) | **Deferred build** (R7) | Closed-cycle retention out of hot path | new |

Create #1–#15 in this pass. Reference data (`PROGRAMS`, `PROGRAM_OPTIONS`, `CRITERION_CATALOG`) is
populated by DTD via admin screens; `EMPLOYEE_DIRECTORY` is loaded by the maker (mechanism deferred).

---

## Changes & additions layered onto the logical model

### `APPLICATIONS` — ADD routing/assignment fields

Beyond the docs field set, add:

| Column (Pascal) | Type | Required | Notes |
|---|---|---|---|
| `FirstLineSupervisorEmail` | Single line of text | No | Snapshot at submission from `EMPLOYEE_DIRECTORY` (R1/R5). |
| `SecondLineSupervisorEmail` | Single line of text | No | Snapshot at submission; empty → routing goes `Held For Alternate`. |
| `AlternateSecondLineEmail` | Single line of text | No | Set by DTD when designating an alternate (FR-012a). **[PROPOSED]** pending DTD confirmation (Constitution I). |
| `RoutingStage` | Choice | No | Endorsement/workflow stage (see choice sets). Separate from `Status` (R5). |
| `RevalidationFlag` | Choice (Yes/No) | No | Set when applicant modifies after submission (FR-050 / RQ098). |

- **CHANGE (OI-8 confirmed):** keep both the **attached** performance-rating appraisal (native
  attachment) and the numeric `LatestPerformanceRating` (existing column). They are distinct
  (FR-006 / FR-006a).
- **CHANGE (FR-005):** the form captures **3 OPM + 3 technical + 4 ECQ** — `OPMCompetencies`,
  `TechnicalCompetencies`, `ECQs` all retained (resolves OI-1).

### `SUPERVISOR_ENDORSEMENTS` — CHANGE

- `SupervisorLevel` choice gains **`Alternate Second Line`** alongside `First Line` / `Second Line`
  (supports FR-012a). An alternate's decision is recorded and treated as the second-line decision.
  **[PROPOSED]** — the `Alternate Second Line` value is Proposed with FR-012a; do not transcribe
  until DTD confirms (Constitution I).

### `EMPLOYEE_DIRECTORY` — ADD (build-support list, R1)

| Column | Type | Required | Notes |
|---|---|---|---|
| `ID` | Number | Yes | Identifier. |
| `Email` | Single line of text | Yes | Identity key; **indexed**. |
| `EmployeeName` | Single line of text | Yes | → `ApplicantName`. |
| `Location` | Single line of text | No | |
| `Grade` | Single line of text | No | |
| `JobSeries` | Single line of text | No | |
| `JobTitle` | Single line of text | No | |
| `FirstLineSupervisorEmail` | Single line of text | No | |
| `SecondLineSupervisorEmail` | Single line of text | No | Empty → no second line (OI-6 path). |

Loaded/refreshed by the maker outside the app (no premium connector). The app reads it by delegable
lookup on `Email`. Manual entry remains the fallback when a record is absent (RQ003).

### `APPLICATIONS_ARCHIVE` family — DEFERRED build (R7)

Parallel archive lists mirroring `APPLICATIONS` and its child lists, for closed-cycle records moved
out of the hot path. Never deleted inside the seven-year window; attachments travel with the item.
Defined here; **built after a cycle can close.**

---

## Choice sets (enumerate at creation)

| List.Column | Values | Source |
|---|---|---|
| `CYCLES.State` | Scheduled, Open, Closed, In Review | RQ076 |
| `APPLICATIONS.Status` | Draft, Submitted, Complete, Incomplete, Placed, Not Selected | docs (inferred) |
| `APPLICATIONS.RoutingStage` | Pending First Line, Pending Second Line, Held For Alternate, Pending Validation, In Committee, Closed | R5 (`Held For Alternate` is **[PROPOSED]** with FR-012a) |
| `APPLICATIONS.RevalidationFlag` | Yes, No | FR-050 |
| `APPLICATIONS.ListedOnIDP` / `AttendedInfoSession` | Yes, No | docs |
| `SUPERVISOR_ENDORSEMENTS.SupervisorLevel` | First Line, Second Line, Alternate Second Line | docs + FR-012a |
| `SUPERVISOR_ENDORSEMENTS.Decision` | Approve, Disapprove | RQ018 |
| `RATING_SHEETS.State` / `IsCurrent` | Draft, Published / Yes, No | docs |
| `CRITERION_CATALOG.State` | Draft, Published | RQ112 |
| `CRITERION_ANCHORS.Score` | 0, 1, 3, 5 (fixed; no criterion-specific scale) | RQ110 |
| `NOTIFICATIONS.NotificationType` | Pending Action, Advance, Reminder, Disposition | docs |
| `NOTIFICATIONS.SendOutcome` | Sent, Failed | docs |
| `CHANGE_HISTORY.ChangeType` | Program Recommendation, Completeness Determination, Notification Sent, Placement, Post-Submission Modification, Alternate Designation | docs + FR-012a/FR-050 |
| `APPLICATIONS.OPMCompetencies` / `TechnicalCompetencies` / `ECQs` | **TBD — Appendix B (D-2)** | deferred |

Competency/ECQ enumerations are blocked on Appendix B (D-2). Model these as multi-value choice or
text pending the appendix; do not invent values (Constitution I).

---

## Indexed columns (Constitution III — delegation)

- `APPLICATIONS`: `CycleID`, `ApplicantEmail`, `Status`, `RoutingStage`.
- `APPLICATION_PROGRAM_CHOICES`: `ApplicationID`, `ProgramOptionID`.
- `SUPERVISOR_ENDORSEMENTS`: `ApplicationID`.
- `COMMITTEE_SCORES`: `ApplicationID`, `ProgramID`, `RatingSheetID`.
- `RATING_SHEETS`: `CycleID`, `ProgramID`, `IsCurrent`.
- `RATING_CRITERIA`: `RatingSheetID`.
- `CRITERION_CATALOG`: `State`.
- `PLACEMENTS`: `ApplicationID`, `ProgramOptionID`, `CycleID`.
- `NOTIFICATIONS`/`CHANGE_HISTORY`: `ApplicationID` (plain Number, not Lookup — preserve log).
- `EMPLOYEE_DIRECTORY`: `Email`.

Every gallery filters by an indexed, `CycleID`-scoped predicate first (R2).

---

## State transitions

**Application `Status`:** `Draft → Submitted → (Complete | Incomplete)`; `Complete → Placed | Not
Selected` (at finalize). `Incomplete → Complete` (re-validation). A submitted app modified before
In Review sets `RevalidationFlag = Yes` and returns to DTD (Status stays `Submitted`/`Complete` per
determination; UC-2.2 ext 2b).

**`RoutingStage`:** `Pending First Line → Pending Second Line → Pending Validation → In Committee →
Closed`. No-second-line branch: after first-line decision → `Held For Alternate` → (DTD designates)
→ `Pending Second Line` (R5, FR-012a).

**`CYCLES.State`:** `Scheduled → Open → Closed → In Review` (DTD transitions; one Open at a time — R6).

**`RATING_SHEETS`:** `Draft (v1 → v2 → …) → Published`; `Published → Draft` only if zero
`COMMITTEE_SCORES` reference the version (R3).

**`CRITERION_CATALOG`:** `Draft → Published` (frozen); retirement via `EndDate` (RQ114–116).

---

## Validation rules (mapped to FRs)

- One application per applicant per cycle (FR-011 / R8); one active `PLACEMENTS` row per applicant
  (FR-028); transfer removes the prior (FR-028).
- Submission requires all required fields + three documents, validated as a whole (FR-009).
- Endorsement decision requires a disposition statement on approve and disapprove (FR-013).
- Rating sheet: ≥1 selected criterion to save (FR-042); no publish with a passed-end-date criterion
  (FR-045); no unpublish once scores exist (FR-044).
- Criterion: all four anchors present before publish (FR-046); no edit once Published (FR-047).
- Committee score: only 0/1/3/5 accepted (FR-022) — enforced by a fixed-choice input (R4).
- Cycle: reject inconsistent dates; one Open at a time (FR-040/041 / R6).
