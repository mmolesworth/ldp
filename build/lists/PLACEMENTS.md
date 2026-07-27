# PLACEMENTS

**Purpose:** DTD's placement of an applicant into a program option within a cycle. At most one active
placement per applicant at any time.
**Anchors:** RQ046–054; UC-3.2.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| ApplicationID | Lookup (APPLICATIONS) | Yes | Applicant placed. |
| ProgramOptionID | Lookup (PROGRAM_OPTIONS) | Yes | Option placed into. |
| CycleID | Lookup (CYCLES) | Yes | Owning cycle. |
| PlacedBy | Single line of text | Yes | DTD user. |
| PlacedDate | Date | Yes | When recorded. |
| IsFinalized | Choice | Yes | Yes/No — locked at cohort finalize. |

**Indexes:** `ApplicationID`, `ProgramOptionID`, `CycleID`.
**Validation:** one active placement per applicant, incl. mid-revision (FR-028); placing an
already-placed applicant transfers (remove prior); finalize locks and marks unplaced Not Selected (FR-030).
