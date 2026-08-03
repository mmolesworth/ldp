# Data Definitions — LDP SharePoint Schema

**Purpose.** Every list, in the order they must be built. Consolidates the per-list specs in this
directory into one dependency-ordered view for provisioning, seeding and export. Column-level notes,
history, and rationale live in the per-list files; this file is the map.

**Companion docs.**
- `_RELATIONSHIPS_AND_INDEXES.md` — the lookup graph and Constitution-III indexes.
- `_CHOICES.md` — choice-column values and the `ApplicationStatus` / `ReviewStage` / `PlacementOutcome` split.

**Type shorthand.** `Text` = Single line of text · `Note` = Multiple lines of text (plain, not rich)
· `Date` = date only · `DateTime` = date + time · `Lookup(TARGET.ShowField)` = SharePoint lookup.

**Build order.** Create all lists in a tier before moving to the next. Within a tier, order does
not matter. Lookups (marked `→ TARGET`) reference the target list and can only be created after
the target exists — Tier 1 depends on Tier 0, and so on. `New-LdpSharePointLists.ps1` follows this
exact order and this file mirrors it.

**[PROPOSED]** items are gated behind `-IncludeProposed` in the provisioning script and must not
be transcribed until DTD confirms (Constitution I).

---

## Tier 0 — reference tables (no lookups; build first)

### CYCLES
Application cycles — state and key dates. Scopes applications, rating sheets, placements.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| CycleName | Text | Yes | e.g. "FY2026 LDP Cycle". |
| State | Choice | Yes | Scheduled, Open, Closed, In Review. |
| OpenDate | Date | Yes | |
| CloseDate | Date | Yes | |
| ExpectedDecisionDate | Date | Yes | Shown to applicants. |

### PROGRAMS
The three program groupings (NEXT, MDP, HPP). Parent of `PROGRAM_OPTIONS`; scored at this level.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. **Primary key** for `PROGRAM_OPTIONS.ProgramID`. |
| ProgramName | Text | Yes | NEXT, MDP, HPP. |
| Description | Note | No | |
| State | Choice | Yes | Active, Retired. |

### COMPETENCY_TYPES
Groupings of competency — OPM, ECQ, Technical. Parent of `COMPETENCIES`.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. **Primary key** for `COMPETENCIES.CompetencyTypeID`. |
| TypeName | Text | Yes | OPM, ECQ, Technical. |
| Description | Note | No | |
| SortOrder | Number | No | Display order. |
| SelectionCount | Number | No | **Maximum** selections of this type on one application. |
| State | Choice | Yes | Active, Retired. |

### CRITERION_CATALOG
Shared master set of scoring criteria. Reusable across programs and cycles. Published is immutable.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. **Primary key** for `CRITERION_ANCHORS.CatalogCriterionID` and `RATING_CRITERIA.CatalogCriterionID`. |
| CriterionName | Text | Yes | |
| Description | Note | Yes | What the rater evaluates. |
| State | Choice | Yes | Draft, Published, Retired. |
| StartDate | Date | No | Set on publish. |
| EndDate | Date | No | Null = still available. |

---

## Tier 1 — depend only on Tier 0

### PROGRAM_OPTIONS  → PROGRAMS
Selectable options under a program. Applicants rank; DTD places into one.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| ProgramID | Lookup(PROGRAMS.ProgramName) | Yes | Parent program. |
| OptionName | Text | Yes | |
| Description | Note | No | |
| Vendor | Text | No | |
| GradeLevel | Text | No | Descriptive; not enforced. |
| CourseLength | Text | No | |
| Competency | Note | No | |
| Requirements | Note | No | |
| Website | Text | No | URL. |
| State | Choice | Yes | Active, Retired. |

### COMPETENCIES  → COMPETENCY_TYPES
The competency catalogue applicants and reviewers select from.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| CompetencyTypeID | Lookup(COMPETENCY_TYPES.TypeName) | Yes | |
| CompetencyName | Text | Yes | |
| Description | Note | No | |
| State | Choice | Yes | Active, Retired. |

### CRITERION_ANCHORS  → CRITERION_CATALOG
The four scoring anchors (0/1/3/5) for a catalog criterion. Four rows per criterion.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| CatalogCriterionID | Lookup(CRITERION_CATALOG.CriterionName) | Yes | Owning criterion. |
| Score | Number | Yes | 0, 1, 3, or 5. |
| AnchorText | Note | Yes | |
| ExampleText | Note | No | |

---

## Tier 2 — depend on Tier 0/1

### APPLICATIONS  → CYCLES
The central application record. Supporting documents live on `APPLICATION_DOCUMENTS`.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| CycleID | Lookup(CYCLES.CycleName) | Yes | Owning cycle. |
| ApplicantEmail | Text | Yes | Identity/owner. |
| ApplicantName | Text | Yes | Manual entry pending D-1. |
| Location | Text | No | |
| Grade | Text | No | |
| JobSeries | Text | No | |
| JobTitle | Text | No | |
| ListedOnIDP | Choice | No | Yes, No. |
| LatestPerformanceRating | Number | No | Numeric rating, distinct from the attached appraisal. |
| AttendedInfoSession | Choice | No | Yes, No. |
| InfoSessionDate | Date | No | |
| NCUAStartDate | Date | No | |
| ServiceComputationDate | Date | No | |
| ApplicationStatus | Choice | Yes | Draft, Submitted, Validated, Withdrawn. Owned by applicant + DTD acceptance. |
| PlacementOutcome | Choice | Yes | Decision Pending, Placed, Not Selected, Placement Declined. |
| FirstLineSupervisorEmail | Text | No | Snapshot at submission. |
| SecondLineSupervisorEmail | Text | No | Snapshot; empty → `Needs Supervisor Assigned`. |
| AlternateSecondLineEmail | Text | No | **[PROPOSED — FR-012a]** |
| SubmittedDate | Date | No | Written once on Submit; blank while Draft. |
| ReviewStage | Choice | No | Where the packet is (see `_CHOICES.md`). `Needs Supervisor Assigned` is **[PROPOSED — FR-012a]**. |

### RATING_SHEETS  → PROGRAMS
Committee rating sheets — versioned per program. Reused across cycles until replaced.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number (one row = one version). |
| ProgramID | Lookup(PROGRAMS.ProgramName) | Yes | |
| SheetVersion | Number | Yes | Named `SheetVersion` (not `Version`) — SharePoint owns that display name. |
| State | Choice | Yes | Draft, Published, Superseded. At most one Published per program. |
| CreatedBy | Text | Yes | |
| CreatedDate | Date | Yes | |

---

## Tier 3 — depend on Tier 2

### APPLICATION_DOCUMENTS  → APPLICATIONS
One row per required supporting document. Each row holds the file as its own attachment.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| ApplicationID | Lookup(APPLICATIONS.ApplicantEmail) | Yes | Owning application. **Index at creation.** |
| DocumentType | Choice | Yes | Resume, Statement of Interest, Performance Appraisal. |
| *(Attachments)* | built-in | No | One file per row by convention. |

### APPLICATION_COMPETENCIES  → APPLICATIONS, COMPETENCIES
An application's selected competencies (join). The competency's TYPE is deliberately not stored here.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| ApplicationID | Lookup(APPLICATIONS.ApplicantEmail) | Yes | |
| CompetencyID | Lookup(COMPETENCIES.CompetencyName) | Yes | |

### APPLICATION_PROGRAM_CHOICES  → APPLICATIONS, PROGRAMS, PROGRAM_OPTIONS
Ranked program selections. The PROGRAM is the choice; option is populated only where the program has any.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| ApplicationID | Lookup(APPLICATIONS.ApplicantEmail) | Yes | |
| ProgramID | Lookup(PROGRAMS.ProgramName) | Yes | The choice. |
| ProgramOptionID | Lookup(PROGRAM_OPTIONS.OptionName) | No | HPP today; blank for MDP and NEXT. |
| Rank | Number | Yes | 1 = highest, up to 3. |

### SUPERVISOR_ENDORSEMENTS  → APPLICATIONS
Each supervisor's endorsement decision, statement and advisory program recommendations.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| ApplicationID | Lookup(APPLICATIONS.ApplicantEmail) | Yes | |
| SupervisorEmail | Text | Yes | |
| SupervisorLevel | Choice | Yes | First Line, Second Line, Alternate Second Line **[PROPOSED — FR-012a]**. |
| Decision | Choice | Yes | Recommend, Not Recommend. |
| DispositionStatement | Note | Yes | Required on both values. |
| RecommendedOptions | Note | No | Advisory. |
| DecisionDate | Date | Yes | |

### RATING_CRITERIA  → RATING_SHEETS, CRITERION_CATALOG
Criteria selected onto a rating-sheet version. Criterion text lives on `CRITERION_CATALOG`.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| RatingSheetID | Lookup(RATING_SHEETS.ID) | Yes | |
| CatalogCriterionID | Lookup(CRITERION_CATALOG.CriterionName) | Yes | Only Published, in-window criteria may be selected. |
| DisplayOrder | Number | No | |

### COMMITTEE_SCORES  → APPLICATIONS, PROGRAMS, RATING_SHEETS
An applicant's score for a program. Numbers are queryable; per-criterion breakdown is JSON.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| ApplicationID | Lookup(APPLICATIONS.ApplicantEmail) | Yes | |
| ProgramID | Lookup(PROGRAMS.ProgramName) | Yes | |
| RatingSheetID | Lookup(RATING_SHEETS.ID) | Yes | Exact version scored against. |
| FinalScore | Number | Yes | Sum of anchors. |
| PercentOfPossible | Number | No | FinalScore ÷ (5 × criteria count). |
| CriterionScores | Note | No | JSON payload (plain text). |
| Rank | Number | No | Rank within the program pool. |
| ScoredBy | Text | No | |
| ScoredDate | Date | No | |

### PLACEMENTS  → APPLICATIONS, PROGRAMS, PROGRAM_OPTIONS, CYCLES
DTD's placement of an applicant into a program option within a cycle.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| ApplicationID | Lookup(APPLICATIONS.ApplicantEmail) | Yes | |
| ProgramID | Lookup(PROGRAMS.ProgramName) | Yes | Program placed into. |
| ProgramOptionID | Lookup(PROGRAM_OPTIONS.OptionName) | No | Blank for MDP and NEXT. |
| CycleID | Lookup(CYCLES.CycleName) | Yes | |
| PlacedBy | Text | Yes | |
| PlacedDate | Date | Yes | |
| IsFinalized | Choice | Yes | Yes, No. Locked at cohort finalize. |

---

## Tier 4 — append-only logs

`ApplicationID` is a plain **Number**, not a Lookup, so the log survives if parent data changes.
Semantic dependency on `APPLICATIONS` — the ID must exist before a row can be meaningfully written.

### NOTIFICATIONS
App writes rows; **flows send** (deferred, T076).

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| ApplicationID | Number | Yes | Application concerned (ID value, not a Lookup). |
| RecipientEmail | Text | Yes | |
| NotificationType | Choice | Yes | Pending Action, Advance, Reminder, Disposition. |
| SendOutcome | Choice | Yes | Sent, Failed. |
| SentDate | DateTime | Yes | |

### CHANGE_HISTORY
Append-only audit trail. Shown to reviewers; withheld from applicants at the permission layer.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Auto-number. |
| ApplicationID | Number | Yes | Application concerned (ID value, not a Lookup). |
| ChangeType | Choice | Yes | Program Recommendation, Completeness Determination, Notification Sent, Placement, Post-Submission Modification, Alternate Designation **[PROPOSED]**. |
| ChangedBy | Text | Yes | |
| ChangedDate | DateTime | Yes | |
| Details | Note | No | Description or JSON payload. |
