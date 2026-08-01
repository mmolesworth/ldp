# PLACEMENTS

**Purpose:** DTD's placement of an applicant into a program option within a cycle. At most one active
placement per applicant at any time.
**Anchors:** RQ046–054; UC-3.2.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| ApplicationID | Lookup (APPLICATIONS) | Yes | Applicant placed. |
| ProgramID | Lookup (PROGRAMS) | Yes | **Program placed into.** Stores `PROGRAMS.ID`. |
| ProgramOptionID | Lookup (PROGRAM_OPTIONS) | No | Option placed into, where the program has any. Blank for MDP and NEXT. |
| CycleID | Lookup (CYCLES) | Yes | Owning cycle. |
| PlacedBy | Single line of text | Yes | DTD user. |
| PlacedDate | Date | Yes | When recorded. |
| IsFinalized | Choice | Yes | Yes/No — locked at cohort finalize. |

**Indexes:** `ApplicationID`, `ProgramID`, `ProgramOptionID`, `CycleID`.
**Revised 2026-07-31.** `ProgramOptionID` was Required, so a placement into MDP or NEXT could not be
recorded without a fabricated option. Same defect and same fix as
`APPLICATION_PROGRAM_CHOICES` — see that file for the reasoning.
**Validation:** one active placement per applicant, incl. mid-revision (FR-028); placing an
already-placed applicant transfers (remove prior); finalize locks and marks unplaced Not Selected (FR-030).
