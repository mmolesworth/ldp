# CRITERION_ANCHORS

**Purpose:** The four scoring anchors (0/1/3/5) for a catalog criterion. Four rows per criterion.
**Anchors:** RQ110–111; UC-4.4.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| CatalogCriterionID | Lookup (CRITERION_CATALOG) | Yes | Owning criterion. |
| Score | Number | Yes | Fixed: 0, 1, 3, or 5 (no criterion-specific scale). |
| AnchorText | Multiple lines of text | Yes | Descriptor the rater applies at this score. |
| ExampleText | Multiple lines of text | No | Optional illustrative example. |

**Indexes:** `CatalogCriterionID`.
**Validation:** exactly four rows (scores 0/1/3/5) required before the criterion can be Published (FR-046).
