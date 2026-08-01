# APPLICATIONS

**Purpose:** The central application record. Supporting documents (resume, statement of interest,
performance-rating appraisal) are **native SharePoint attachments** on this item.
**Anchors:** RQ001–014, RQ096–100; UC-1.x; data-model.md (ADD section).

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| CycleID | Lookup (CYCLES) | Yes | Owning cycle. |
| ApplicantEmail | Single line of text | Yes | Identity/owner. |
| ApplicantName | Single line of text | Yes | Manual entry until the D-1 personnel integration exists (`EMPLOYEE_DIRECTORY` withdrawn 2026-07-26). |
| Location | Single line of text | No | |
| Grade | Single line of text | No | |
| JobSeries | Single line of text | No | |
| JobTitle | Single line of text | No | |
| ListedOnIDP | Choice | No | Yes/No. |
| LatestPerformanceRating | Number | No | Numeric latest rating — **distinct** from the attached appraisal document (FR-006a / OI-8). |
| AttendedInfoSession | Choice | No | Yes/No. |
| InfoSessionDate | Date | No | |
| NCUAStartDate | Date | No | |
| ServiceComputationDate | Date | No | |
| ApplicationStatus | Choice | Yes | Draft, Submitted, Validated, Withdrawn. **The applicant's own progress, plus DTD's acceptance of it.** Linear: a later value implies the earlier ones. An edit to a validated application drops it back to Submitted. |
| PlacementOutcome | Choice | Yes | Decision Pending, Placed, Not Selected, Placement Declined. **Set on leaving `Pending Placement`.** |
| FirstLineSupervisorEmail | Single line of text | No | Snapshot at submission (R1/R5). |
| SecondLineSupervisorEmail | Single line of text | No | Snapshot; empty → routing `Held For Alternate`. |
| AlternateSecondLineEmail | Single line of text | No | **[PROPOSED — FR-012a]** set by DTD; do not transcribe until DTD confirms (Constitution I). |
| ReviewStage | Choice | No | Where the packet is (see `_CHOICES.md`). Blank while Draft. `Needs Supervisor Assigned` is **[PROPOSED — FR-012a]**. |

**Indexes:** `CycleID`, `ApplicantEmail`, `ApplicationStatus`, `ReviewStage`, `PlacementOutcome`.
**Competencies moved out 2026-07-31.** `OPMCompetencies`, `TechnicalCompetencies` and `ECQs` were
one text column per competency type, which cannot survive the type list being data-driven.
Selections now live in `APPLICATION_COMPETENCIES`; the per-type maximum lives in
`COMPETENCY_TYPES.SelectionCount`.
**Validation:** one application per applicant per cycle (FR-011 / R8); whole-application completeness
at submit (FR-009); Draft read-only when cycle Closed (FR-008); read-only when cycle In Review.
**Attachments:** resume, statement of interest, performance-rating appraisal (PDF/Word; size guard) — FR-006.

## Revised 2026-07-31 — `Status` and `RoutingStage` became three columns

`Status` was one column carrying three lifecycles with three different owners, so every advance
destroyed the previous answer. It is now:

| Column | Owner | Values |
|---|---|---|
| `ApplicationStatus` | the applicant | Draft, Submitted, Withdrawn |
| `ReviewStage` | the workflow | *(blank)*, Pending First-Line, Needs Supervisor Assigned, Pending Second-Line, Pending DTD Validation, Committee Review, Pending Placement, Pending Notification, Complete |
| `PlacementOutcome` | DTD, once | Decision Pending, Placed, Not Selected, Placement Declined |

`Complete` and `Incomplete` are **removed and not replaced** — they were the verdict of the
validation step, not states. DTD holds full control of decisions and placement, so neither a
completeness problem nor a supervisor disapproval diverts the packet; both are captured
(`SUPERVISOR_ENDORSEMENTS.Decision`) and the application continues down the same path.

Full rationale, the state machine and the invariants are in `_CHOICES.md`.

### Migration from the old `Status`

| Old value | ApplicationStatus | PlacementOutcome | ReviewStage |
|---|---|---|---|
| Draft | Draft | Decision Pending | blank |
| Submitted | Submitted | Pending | keep existing `RoutingStage` |
| Complete | Submitted | Pending | keep existing — it passed validation, and the stage already records where it got to |
| Incomplete | Submitted | Pending | keep existing — the packet continues; the finding is captured elsewhere |
| Placed | Submitted | Placed | Closed |
| Not Selected | Submitted | Not Selected | Closed |

`Complete` and `Incomplete` both map to `Submitted` because neither described the applicant's
progress, which is all `ApplicationStatus` now means.
