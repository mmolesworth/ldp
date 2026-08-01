# PROGRAM_OPTIONS

**Purpose:** Selectable options under a program. Applicants select/rank options; DTD places into one.
**Anchors:** RQ072–074; UC-4.1.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| ProgramID | Lookup (PROGRAMS) | Yes | Parent program. |
| OptionName | Single line of text | Yes | e.g., "Mini MBA: Management & Leadership". |
| Description | Multiple lines of text | No | |
| Vendor | Single line of text | No | |
| GradeLevel | Single line of text | No | Descriptive only; eligibility not system-enforced. |
| CourseLength | Single line of text | No | |
| Competency | Multiple lines of text | No | |
| Requirements | Multiple lines of text | No | |
| Website | Single line of text | No | URL (open via `Launch()`). |
| State | Choice | Yes | Active, Retired. New options default to Active. |

**Indexes:** `ProgramID`, `State`.
**Validation:** required attributes present before save (FR-038) — `OptionName` and `ProgramID` only,
matching the Required column above; the other seven attributes are recorded but optional.
DTD-managed CRUD.
**Retire, do not delete.** DTD retires an option instead of removing it. A retired
option keeps every historical reference intact — an applicant who ranked it, a
placement made into it, a committee score against it all still resolve — while
disappearing from anywhere an applicant can choose. This is the safe reading of
RQ072's "remove", and it makes the FR-038b delete guard mostly moot: there is no
longer a routine path that orphans data. Hard delete remains available for options
that have never been referenced.

**Anything that offers an option to an applicant MUST filter `State = "Active"`.**
That is the Application Screen's step 2 dropdowns today. A retired option must never
appear as a new choice, but must still display on applications that already chose it.

**Delete guard (FR-038b):** an option is deletable only when nothing references it —
`APPLICATION_PROGRAM_CHOICES.ProgramOptionID`, `PLACEMENTS.ProgramOptionID` (both indexed), in any
cycle. Both are now OPTIONAL lookups, so a program with no options orphans nothing by having none. Test with `IsEmpty(Filter(…))`, never `CountRows` — `CountRows` does not delegate to
SharePoint and would silently pass after 500 rows.
