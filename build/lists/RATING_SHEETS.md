# RATING_SHEETS

**Purpose:** A committee rating sheet — immutably versioned, **per program**. Reused across cycles
until DTD publishes a replacement. Versions are rows (R3).
**Anchors:** RQ082–092; UC-4.3.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier (one row = one version). |
| ProgramID | Lookup (PROGRAMS) | Yes | Program this sheet scores. |
| SheetVersion | Number | Yes | Version number. Named SheetVersion, not Version — SharePoint has a built-in field whose display name is "Version" (_UIVersionString) and Power Apps binds by display name. |
| State | Choice | Yes | Draft, Published, Superseded. **At most one Published per program** — that is the sheet in use. |
| CreatedBy | Single line of text | Yes | DTD author. |
| CreatedDate | Date | Yes | When saved. |

**Indexes:** `ProgramID`, `State`.
**Validation (R3):** each save inserts a new row (`SheetVersion` n+1); prior rows never edited except
to move `Published` → `Superseded`; `Published` frozen; unpublish allowed only when zero
`COMMITTEE_SCORES` reference the version (FR-044); ≥1 selected criterion to save (FR-042); no publish
with a passed-end-date criterion (FR-045).

**Committee scoring is blocked until the program has a Published sheet** — there is nothing to score
against otherwise.

## Revised 2026-07-28 — a sheet is per PROGRAM, not per program per cycle

`CycleID` **removed.** A sheet is defined once for a program and reused across every cycle until DTD
publishes a replacement. Publishing is the event worth recording, which is what versions are for.

**The audit trail survives this.** `COMMITTEE_SCORES` never carried `CycleID` — it references
`RatingSheetID` (the exact version scored against) and `ApplicationID`, and an application knows its
own cycle. "Which sheet version scored this applicant, in which cycle" is still answerable; it is
answered through the application now rather than through the sheet.

`IsCurrent` **removed**, folded into `State`. Two columns expressing one lifecycle can disagree — a
row could be `Draft` with `IsCurrent = Yes`. `Superseded` says the same thing and cannot.
