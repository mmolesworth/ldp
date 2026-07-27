# RATING_SHEETS

**Purpose:** A committee rating sheet — immutably versioned, per program per cycle. Versions are rows (R3).
**Anchors:** RQ082–092; UC-4.3.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier (one row = one version). |
| CycleID | Lookup (CYCLES) | Yes | Owning cycle. |
| ProgramID | Lookup (PROGRAMS) | Yes | Program this sheet scores. |
| SheetVersion | Number | Yes | Version number. Named SheetVersion, not Version — SharePoint has a built-in field whose display name is "Version" (_UIVersionString) and Power Apps binds by display name. |
| State | Choice | Yes | Draft, Published. |
| IsCurrent | Choice | Yes | Yes/No — latest version flag. |
| CreatedBy | Single line of text | Yes | DTD author. |
| CreatedDate | Date | Yes | When saved. |

**Indexes:** `CycleID`, `ProgramID`, `IsCurrent`.
**Validation (R3):** each save inserts a new row (`SheetVersion` n+1) and flips `IsCurrent`; prior rows
never edited except the flag; `Published` frozen; unpublish allowed only when zero `COMMITTEE_SCORES`
reference the version (FR-044); ≥1 selected criterion to save (FR-042); no publish with a passed-
end-date criterion (FR-045).
