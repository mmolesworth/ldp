# COMMITTEES

**Purpose:** A committee formed to score applicants for a specific program in a specific cycle.
Aggregate score data lives on `APPLICATION_PROGRAM_CHOICES`; per-criterion detail on
`COMMITTEE_CRITERION_SCORES`. The committee is the scoping entity that ties them together and
pins the rubric version being scored against.
**Anchors:** UC-3.1; added 2026-08-07.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| CommitteeName | Single line of text | Yes | Display name, e.g. "NEXT · Fall 2026". |
| ProgramID | Lookup (PROGRAMS) | Yes | The program the committee scores. |
| CycleID | Lookup (CYCLES) | Yes | The cycle in scope. |
| RatingSheetID | Lookup (RATING_SHEETS) | Yes | Published rubric version, frozen at formation. |
| State | Choice | Yes | `Active` (accepting scores) / `Ranked` (all scored, rank derived). |
| FormedDate | Date | Yes | When DTD created the committee. |

**Indexes:** `ProgramID`, `CycleID`, `State`.
**Uniqueness:** (`ProgramID`, `CycleID`) — one committee per program per cycle.
**Provisioning:** DTD writes rows directly for Phase I. A Committees admin screen under
`_AdminShell` is deferred; nothing in the Committee Queue / Score screens depends on it.
**Rubric pinning:** `RatingSheetID` is captured at formation so mid-cycle republishes of a
program's rubric do not affect an in-flight committee. Every score row inherits the version via
the committee — no need to store it on scores.
**Committees do not rank.** Rank is derived at query time from `APPLICATION_PROGRAM_CHOICES.FinalScore`
descending within the pool (`CountIf(pool, FinalScore > Self.FinalScore) + 1`). `State` flips to
`Ranked` once every applicant in the pool has a score row, but the ranking itself is a computed
view — no `Rank` column anywhere.
