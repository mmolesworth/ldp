# LDP Application — Logical Data Model

**Project:** NCUA OHR Leader Development Program Application (RITM0069731)
**Scope:** Phase I
**Backend:** SharePoint lists (Power Apps)

High-level metadata for the form and list fields is provided below. Choice field values (competencies, ECQs, statuses, and similar) are cataloged in the traceability matrix (Appendix B), not here.

## Conventions

- One SharePoint list per section. Field structure follows the accepted SRS sample: Field Name, Data Type, Required?, Description.
- Relationships use SharePoint Lookup columns (target list named in the Data Type), except append-only logs.
- `NOTIFICATIONS` and `CHANGE_HISTORY` store `ApplicationID` as a plain Number (not a Lookup) to preserve the log if parent data changes.
- Supporting documents (resume, statement of interest, performance rating) are native SharePoint attachments on the `APPLICATIONS` item.
- Committee scoring is hybrid: `FinalScore` is a queryable Number used for ranking; the per-criterion breakdown is stored as JSON in a memo field.
- Identity is M365/SharePoint (email as identity); there is no custom Users/Roles list in Phase I.
- **Three hierarchy layers.** Applicants select and rank **program options** (`APPLICATION_PROGRAM_CHOICES`); the committee pools, scores, and ranks at the **program** level (`RATING_SHEETS`, `COMMITTEE_SCORES`); DTD places into a **program option** (`PLACEMENTS`). An applicant who selects several options within one program appears once in that program's pool.

## Entity relationships

```mermaid
erDiagram
    CYCLES ||--o{ APPLICATIONS : "scopes"
    CYCLES ||--o{ RATING_SHEETS : "scopes"
    CYCLES ||--o{ PLACEMENTS : "scopes"
    PROGRAMS ||--o{ PROGRAM_OPTIONS : "groups"
    APPLICATIONS ||--o{ APPLICATION_PROGRAM_CHOICES : "has ranked"
    PROGRAM_OPTIONS ||--o{ APPLICATION_PROGRAM_CHOICES : "chosen in"
    APPLICATIONS ||--o{ SUPERVISOR_ENDORSEMENTS : "endorsed by"
    PROGRAMS ||--o{ RATING_SHEETS : "scored by"
    RATING_SHEETS ||--o{ RATING_CRITERIA : "contains"
    APPLICATIONS ||--o{ COMMITTEE_SCORES : "scored as"
    PROGRAMS ||--o{ COMMITTEE_SCORES : "pool for"
    RATING_SHEETS ||--o{ COMMITTEE_SCORES : "scored against"
    APPLICATIONS ||--o| PLACEMENTS : "placed via"
    PROGRAM_OPTIONS ||--o{ PLACEMENTS : "placed into"
    APPLICATIONS ||..o{ NOTIFICATIONS : "logged by ID"
    APPLICATIONS ||..o{ CHANGE_HISTORY : "audited by ID"
```

Solid lines are Lookup relationships; dashed lines are the append-only logs (related by ID value, not a Lookup). `||--o{` is one-to-many; `APPLICATIONS ||--o| PLACEMENTS` is one-to-zero-or-one (an applicant has at most one placement).

## Lists

| List | Purpose | Key relationships |
|---|---|---|
| CYCLES | An application cycle: its state and key dates. | Referenced by APPLICATIONS, RATING_SHEETS, PLACEMENTS |
| PROGRAMS | The three program groupings (NEXT, MDP, HPP). | Parent of PROGRAM_OPTIONS |
| PROGRAM_OPTIONS | The nine selectable options under programs. | Child of PROGRAMS; referenced widely |
| APPLICATIONS | The central application record. | Belongs to a CYCLE; parent of choices, endorsements, scores |
| APPLICATION_PROGRAM_CHOICES | An applicant's ranked program-option selections. | Joins APPLICATIONS and PROGRAM_OPTIONS (with rank) |
| SUPERVISOR_ENDORSEMENTS | Each supervisor's decision, statement, recommendations. | Child of APPLICATIONS |
| RATING_SHEETS | A committee rating sheet, versioned, per program per cycle. | Belongs to CYCLE and PROGRAM; parent of criteria |
| RATING_CRITERIA | The criteria within a rating sheet version. | Child of RATING_SHEETS |
| COMMITTEE_SCORES | An applicant's score for a program (hybrid). | Joins APPLICATION, PROGRAM, RATING_SHEET |
| PLACEMENTS | DTD's final placement of an applicant. | Joins APPLICATION and PROGRAM_OPTION within a CYCLE |
| NOTIFICATIONS | Append-only log of notifications sent. | References APPLICATIONS by ID value (not Lookup) |
| CHANGE_HISTORY | Append-only audit trail of consequential changes. | References APPLICATIONS by ID value (not Lookup) |

---

## CYCLES

An application cycle: its state and key dates.

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the application cycle. |
| CycleName | Single line of text | Yes | The name of the cycle (e.g., "FY2026 LDP Cycle"). |
| State | Choice | Yes | The cycle's current state: Scheduled, Open, Closed, or In Review. |
| OpenDate | Date | Yes | The date applications are intended to open. |
| CloseDate | Date | Yes | The date applications are intended to close. |
| ExpectedDecisionDate | Date | Yes | The date by which a decision is expected; shown to applicants. |

## PROGRAMS

The three program groupings (NEXT, MDP, HPP).

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the program. |
| ProgramName | Single line of text | Yes | The name of the program (NEXT, MDP, HPP). |
| ProgramCode | Single line of text | Yes | The short code for the program (NEXT, MDP, HPP). |
| Description | Multiple lines of text | No | A description of the program. |

## PROGRAM_OPTIONS

The nine selectable options under programs.

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the program option. |
| ProgramID | Lookup (PROGRAMS) | Yes | The parent program this option belongs to. |
| OptionName | Single line of text | Yes | The name of the program option (e.g., "Mini MBA: Management & Leadership"). |
| Description | Multiple lines of text | No | A description of the program option. |
| Vendor | Single line of text | No | The vendor delivering the program option. |
| GradeLevel | Single line of text | No | The grade band(s) the option targets (e.g., "CU-12, CU-11"). Descriptive only; eligibility is not system-enforced. |
| CourseLength | Single line of text | No | The duration of the program option. |
| Competency | Multiple lines of text | No | The competencies the option addresses. |
| Requirements | Multiple lines of text | No | The requirements or prerequisites for the option. |
| Website | Single line of text | No | The URL for more information about the option. |

## APPLICATIONS

The central application record. Supporting documents (resume, statement of interest, performance rating) are stored as native SharePoint attachments on this item.

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the application. |
| CycleID | Lookup (CYCLES) | Yes | The cycle this application belongs to. |
| ApplicantEmail | Single line of text | Yes | The email of the applicant (identity/owner). |
| ApplicantName | Single line of text | Yes | The applicant's name (from HR Links or manual entry). |
| Location | Single line of text | No | The applicant's location (from HR Links or manual entry). |
| Grade | Single line of text | No | The applicant's grade. |
| JobSeries | Single line of text | No | The applicant's job series. |
| JobTitle | Single line of text | No | The applicant's job title. |
| OPMCompetencies | Multiple lines of text | No | The three selected OPM competencies (values in the traceability matrix). |
| TechnicalCompetencies | Multiple lines of text | No | The three selected technical competencies. |
| ECQs | Multiple lines of text | No | The four selected Executive Core Qualifications. |
| ListedOnIDP | Choice | No | Whether the request was listed on the applicant's IDP (Yes/No). |
| LatestPerformanceRating | Number | No | The applicant's latest performance rating. |
| AttendedInfoSession | Choice | No | Whether the applicant attended an informational session (Yes/No). |
| InfoSessionDate | Date | No | The date of the informational session attended, if any. |
| NCUAStartDate | Date | No | The applicant's NCUA start date. |
| ServiceComputationDate | Date | No | The applicant's service computation date. |
| Status | Choice | Yes | The application's state: Draft, Submitted, Complete, Incomplete, Placed, Not Selected. |

## APPLICATION_PROGRAM_CHOICES

An applicant's ranked program-option selections (join of APPLICATIONS and PROGRAM_OPTIONS).

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the program choice. |
| ApplicationID | Lookup (APPLICATIONS) | Yes | The application this choice belongs to. |
| ProgramOptionID | Lookup (PROGRAM_OPTIONS) | Yes | The program option the applicant selected. |
| Rank | Number | Yes | The applicant's ranking of this choice (1 = highest, up to 3). |

## SUPERVISOR_ENDORSEMENTS

Each supervisor's endorsement decision, statement, and program recommendations.

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the endorsement. |
| ApplicationID | Lookup (APPLICATIONS) | Yes | The application being endorsed. |
| SupervisorEmail | Single line of text | Yes | The email of the supervisor recording the decision. |
| SupervisorLevel | Choice | Yes | Which supervisor: First Line or Second Line. |
| Decision | Choice | Yes | The endorsement decision: Approve or Disapprove. |
| DispositionStatement | Multiple lines of text | Yes | The supervisor's justification for the decision. |
| RecommendedOptions | Multiple lines of text | No | Alternative program options the supervisor recommends (advisory; does not alter the applicant's selections). |
| DecisionDate | Date | Yes | The date the decision was recorded. |

## RATING_SHEETS

A committee rating sheet, immutably versioned, per program per cycle.

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the rating sheet version. |
| CycleID | Lookup (CYCLES) | Yes | The cycle this rating sheet belongs to. |
| ProgramID | Lookup (PROGRAMS) | Yes | The program this sheet scores. |
| Version | Number | Yes | The version number of this sheet. |
| State | Choice | Yes | The sheet's state: Draft or Published. |
| IsCurrent | Choice | Yes | Whether this is the current (latest) version (Yes/No). |
| CreatedBy | Single line of text | Yes | The DTD user who created this version. |
| CreatedDate | Date | Yes | The date this version was saved. |

## RATING_CRITERIA

The criteria within a rating sheet version.

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the criterion. |
| RatingSheetID | Lookup (RATING_SHEETS) | Yes | The rating sheet version this criterion belongs to. |
| CriterionName | Single line of text | Yes | The name of the scoring criterion. |
| CriterionType | Choice | Yes | The type: Committee-Scored or Predefined. |
| MinPoints | Number | No | The minimum points for a committee-scored criterion. |
| MaxPoints | Number | No | The maximum points for a committee-scored criterion. |
| FixedPoints | Number | No | The fixed point value for a predefined criterion. |

## COMMITTEE_SCORES

An applicant's score for a program. Hybrid: `FinalScore` is queryable; the per-criterion breakdown is JSON.

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the score record. |
| ApplicationID | Lookup (APPLICATIONS) | Yes | The applicant being scored. |
| ProgramID | Lookup (PROGRAMS) | Yes | The program pool this score is for. |
| RatingSheetID | Lookup (RATING_SHEETS) | Yes | The published rating sheet version scored against. |
| FinalScore | Number | Yes | The summed total score (queryable; used for ranking). |
| CriterionScores | Multiple lines of text | No | Per-criterion breakdown stored as JSON (criterion name, type, points). |
| Rank | Number | No | The applicant's rank within this program pool. |
| ScoredBy | Single line of text | No | The committee recorder who entered the score. |
| ScoredDate | Date | No | The date scoring was completed for this applicant. |

## PLACEMENTS

DTD's final placement of an applicant into a program option within a cycle.

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the placement. |
| ApplicationID | Lookup (APPLICATIONS) | Yes | The applicant being placed. |
| ProgramOptionID | Lookup (PROGRAM_OPTIONS) | Yes | The program option the applicant is placed into. |
| CycleID | Lookup (CYCLES) | Yes | The cycle this placement belongs to. |
| PlacedBy | Single line of text | Yes | The DTD user who recorded the placement. |
| PlacedDate | Date | Yes | The date the placement was recorded. |
| IsFinalized | Choice | Yes | Whether the placement has been finalized/locked (Yes/No). |

## NOTIFICATIONS

Append-only log of notifications sent. `ApplicationID` is a plain Number to preserve the log.

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the notification record. |
| ApplicationID | Number | Yes | The application the notification concerns (stored as ID value, not Lookup). |
| RecipientEmail | Single line of text | Yes | The email of the notification recipient. |
| NotificationType | Choice | Yes | The type: Pending Action, Advance, Reminder, Disposition. |
| SendOutcome | Choice | Yes | The outcome: Sent or Failed. |
| SentDate | Date | Yes | The date and time the notification was sent. |

## CHANGE_HISTORY

Append-only audit trail. `ApplicationID` is a plain Number to preserve the trail.

| Field Name | Data Type | Required? | Description |
|---|---|---|---|
| ID | Number | Yes | The unique identifier of the history entry. |
| ApplicationID | Number | Yes | The application the change concerns (stored as ID value, not Lookup). |
| ChangeType | Choice | Yes | The kind of change: Program Recommendation, Completeness Determination, Notification Sent, Placement. |
| ChangedBy | Single line of text | Yes | The user who made the change. |
| ChangedDate | Date | Yes | The date and time the change occurred. |
| Details | Multiple lines of text | No | A description or JSON payload of what changed. |

---

## Notes

- **APPLICATIONS.Status values are inferred from the use cases** (Draft, Submitted, Complete, Incomplete, Placed, Not Selected), not read from a source field spec. Validate against how the application implements state.
- **Choice field values are deferred to the traceability matrix** (Appendix B), matching the accepted SRS sample.
