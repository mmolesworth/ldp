# Relationships & Indexes — LDP Application Phase I

**Generated:** 2026-07-25. Apply after all target lists exist (lookups reference other lists).

## Lookup columns (create after target lists exist)

| List | Column | → Target list |
|---|---|---|
| PROGRAM_OPTIONS | ProgramID | PROGRAMS |
| APPLICATIONS | CycleID | CYCLES |
| APPLICATION_PROGRAM_CHOICES | ApplicationID | APPLICATIONS |
| APPLICATION_PROGRAM_CHOICES | ProgramOptionID | PROGRAM_OPTIONS |
| SUPERVISOR_ENDORSEMENTS | ApplicationID | APPLICATIONS |
| RATING_SHEETS | CycleID | CYCLES |
| RATING_SHEETS | ProgramID | PROGRAMS |
| RATING_CRITERIA | RatingSheetID | RATING_SHEETS |
| RATING_CRITERIA | CatalogCriterionID | CRITERION_CATALOG |
| CRITERION_ANCHORS | CatalogCriterionID | CRITERION_CATALOG |
| COMMITTEE_SCORES | ApplicationID | APPLICATIONS |
| COMMITTEE_SCORES | ProgramID | PROGRAMS |
| COMMITTEE_SCORES | RatingSheetID | RATING_SHEETS |
| PLACEMENTS | ApplicationID | APPLICATIONS |
| PLACEMENTS | ProgramOptionID | PROGRAM_OPTIONS |
| PLACEMENTS | CycleID | CYCLES |

**Append-only logs (NOT lookups):** `NOTIFICATIONS.ApplicationID` and `CHANGE_HISTORY.ApplicationID`
are plain **Number** columns (store the ID value) so the log survives parent changes.

## Indexed columns (Constitution III — delegation)

> `EMPLOYEE_DIRECTORY` withdrawn 2026-07-26 — see that file.

| List | Indexed columns |
|---|---|
| APPLICATIONS | CycleID, ApplicantEmail, Status, RoutingStage |
| APPLICATION_PROGRAM_CHOICES | ApplicationID, ProgramOptionID |
| SUPERVISOR_ENDORSEMENTS | ApplicationID |
| RATING_SHEETS | CycleID, ProgramID, IsCurrent |
| RATING_CRITERIA | RatingSheetID |
| CRITERION_CATALOG | State |
| CRITERION_ANCHORS | CatalogCriterionID |
| COMMITTEE_SCORES | ApplicationID, ProgramID, RatingSheetID |
| PLACEMENTS | ApplicationID, ProgramOptionID, CycleID |
| NOTIFICATIONS | ApplicationID |
| CHANGE_HISTORY | ApplicationID |
| CYCLES | State |
| PROGRAM_OPTIONS | ProgramID |

**Rule:** every gallery/lookup filters by an indexed, `CycleID`-scoped predicate first; no screen
loads an unfiltered list (R2).
