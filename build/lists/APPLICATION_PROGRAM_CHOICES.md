# APPLICATION_PROGRAM_CHOICES

**Purpose:** An applicant's ranked program-option selections (join of APPLICATIONS × PROGRAM_OPTIONS).
**Anchors:** RQ005; UC-1.1.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| ApplicationID | Lookup (APPLICATIONS) | Yes | Owning application. |
| ProgramOptionID | Lookup (PROGRAM_OPTIONS) | Yes | Selected option. |
| Rank | Number | Yes | 1 = highest, up to 3. |

**Indexes:** `ApplicationID`, `ProgramOptionID`.
**Validation:** one to three rows per application, ranks 1–3, no duplicate rank (FR-004).
