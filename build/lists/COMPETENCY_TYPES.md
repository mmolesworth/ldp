# COMPETENCY_TYPES

**Purpose:** Groupings of competency — OPM, ECQ, Technical. Parent of `COMPETENCIES`.
**Anchors:** docs/competencies.xlsx; D-2 / Appendix B.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | SharePoint auto-number (Counter). **The primary key** — `COMPETENCIES.CompetencyTypeID` is a Lookup that stores this value. |
| TypeName | Single line of text | Yes | OPM, ECQ, Technical. |
| Description | Multiple lines of text | No | Not supplied by the source workbook; DTD may fill in. |
| SortOrder | Number | No | Display order. Seeded 10/20/30 in workbook order. |
| SelectionCount | Number | No | **Maximum** selections of this type on one application — OPM 3, Technical 3, ECQ 4 (RQ006 / RQ007 / RQ008). Data rather than a constant in the screens, so a fourth type is usable without a YAML edit. Blank means no limit is defined; treat as 0 and say so rather than guessing. |
| State | Choice | Yes | Active, Retired. New types default to Active. |

**Indexes:** `State`.
**Seed:** `build/scripts/competency-types.csv`, via `New-LdpSharePointLists.ps1 -SeedCompetencies`.

**Why a list and not a Choice column.** A type had to be addable "in the future if
necessary". A Choice column can only be extended in SharePoint's column settings by
someone with list-design rights, and never from the app. A lookup list makes a new type
a **row** — addable from the Competencies admin screen by DTD, like any other data.
Same parent/child shape as `PROGRAMS` → `PROGRAM_OPTIONS`.

**Retire, do not delete.** A retired type keeps its competencies resolvable while
dropping out of pickers. Anything offering types to a user MUST filter `State = "Active"`.
