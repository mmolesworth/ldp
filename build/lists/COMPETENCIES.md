# COMPETENCIES

**Purpose:** The competency catalogue applicants and reviewers select from.
**Anchors:** docs/competencies.xlsx; D-2 / Appendix B.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | SharePoint auto-number (Counter). |
| CompetencyTypeID | Lookup → `COMPETENCY_TYPES` | Yes | Shows `TypeName`. Power Fx reads the key as `.Id`, the label as `.Value`. |
| CompetencyName | Single line of text | Yes | Longest in the source is 73 characters. |
| Description | Multiple lines of text | No | Plain text, not rich. Longest in the source is 417 characters. |
| State | Choice | Yes | Active, Retired. New competencies default to Active. |

**Indexes:** `CompetencyTypeID`, `State`.
**Seed:** 85 rows — OPM 17, ECQ 20, Technical 48 — from `build/scripts/competencies.csv`
via `New-LdpSharePointLists.ps1 -SeedCompetencies`.

**Patching the lookup from Power Fx requires the OData annotation** or the value is
silently dropped and the row saves with an empty parent (see `build/CONVENTIONS.md`):

```
CompetencyTypeID: {
  '@odata.type': "#Microsoft.Azure.Connectors.SharePoint.SPListExpandedReference",
  Id: <type record>.ID,
  Value: <type record>.TypeName
}
```

**Uniqueness is by type + name, not name alone** — that is also the key the seeder
de-duplicates on. Nothing enforces it in SharePoint; the app layer must.

**Source data defects.** `Convert-CompetencyWorkbook.py` repairs three problems in the
workbook and reports what it touched. One defect it does NOT repair, because repairing
it would mean inventing content (Constitution I):

- **OPM / "Continual Learning"** — the description is truncated mid-word in the source:
  *"Assesses and recognizes own strengths and weaknesses; pursues self-developmen"*.
  Fix the workbook cell and re-convert.
