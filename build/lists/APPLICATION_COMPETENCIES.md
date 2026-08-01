# APPLICATION_COMPETENCIES

**Purpose:** An application's selected competencies (join of APPLICATIONS × COMPETENCIES).
**Anchors:** RQ006–RQ008; FR-005; UC-1.1.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | SharePoint auto-number (Counter). |
| ApplicationID | Lookup (APPLICATIONS) | Yes | Owning application. |
| CompetencyID | Lookup (COMPETENCIES) | Yes | The selection. Shows `CompetencyName`. |

**Indexes:** `ApplicationID`, `CompetencyID`.

**The TYPE is not stored here.** It is the competency's parent —
`COMPETENCIES.CompetencyTypeID`. Duplicating it onto the join row would let the two disagree, and
there is no question the copy could answer that the parent cannot.

**Counts are a MAXIMUM, and they live in data.** `COMPETENCY_TYPES.SelectionCount` holds the limit
per type — OPM 3, Technical 3, ECQ 4, per RQ006 / RQ007 / RQ008. No requirement states a minimum,
so zero selections of a type is valid and nothing blocks submission on it.

The limit is a column rather than a constant in the screens because the type list is data-driven:
the Competencies admin screen lets DTD add a fourth type, and a hardcoded 3/3/4 would make that new
type unusable until someone edited YAML.

## Created 2026-07-31 — replaced three text columns

`APPLICATIONS` carried `OPMCompetencies`, `TechnicalCompetencies` and `ECQs` as
*Multiple lines of text* — one column per type. That cannot survive the types being data-driven,
which is the same defect `APPLICATION_PROGRAM_CHOICES` had one table over and the same fix.

Nothing had ever written those columns: step 3 of the applicant form was a placeholder with no
controls at all, pending the competency vocabulary (blocker D-2). The 85-row catalogue that landed
in `COMPETENCIES` **was** that vocabulary, so D-2 is closed and step 3 can now be built for real.

Migrated by `build/scripts/Update-LdpCompetencySelections.ps1`.
