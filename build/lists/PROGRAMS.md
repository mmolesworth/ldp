# PROGRAMS

**Purpose:** The three program groupings (NEXT, MDP, HPP). Parent of `PROGRAM_OPTIONS`; scored at this level.
**Anchors:** data-model.md; UC-4.1.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | SharePoint auto-number (Counter). **The primary key** — `PROGRAM_OPTIONS.ProgramID` is a Lookup that stores this value. |
| ProgramName | Single line of text | Yes | NEXT, MDP, HPP. |
| Description | Multiple lines of text | No | |
| State | Choice | Yes | Active, Retired. New programs default to Active. |

**Indexes:** `State`.
**Seed:** DTD-populated (fixed set of three) via Program Options Screen.
**ProgramCode removed 2026-07-26.** It played no part in the parent/child relationship
— that runs on the auto-number `ID` — nothing read it, and it duplicated `ProgramName`
in the seeded data. Dropping the column deletes its values; they were redundant.
**Retire, do not delete** (same rule as PROGRAM_OPTIONS). A retired program keeps its
options, rating sheets and committee scores resolvable while disappearing from
applicant-facing pickers. Anything offering programs to an applicant MUST filter
`State = "Active"`.
**CRUD:** **[PROPOSED — FR-038a]** DTD create/edit/delete of programs themselves. Every current
requirement treats NEXT/MDP/HPP as a closed set; adding a fourth is a scope addition. Generate the
UI, but do not transcribe until DTD confirms (Constitution I).
**Delete guard (FR-038b):** a program is deletable only when nothing references it —
`PROGRAM_OPTIONS.ProgramID`, `RATING_SHEETS.ProgramID`, `COMMITTEE_SCORES.ProgramID` (all indexed).
Test with `IsEmpty(Filter(…))`, never `CountRows` — `CountRows` does not delegate to SharePoint.
