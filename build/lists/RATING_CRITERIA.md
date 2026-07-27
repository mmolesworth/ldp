# RATING_CRITERIA

**Purpose:** The criteria selected onto a rating-sheet version. References a catalog criterion;
criterion text lives on `CRITERION_CATALOG`, not here.
**Anchors:** RQ083; UC-4.3.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| RatingSheetID | Lookup (RATING_SHEETS) | Yes | Owning sheet version. |
| CatalogCriterionID | Lookup (CRITERION_CATALOG) | Yes | Selected catalog criterion. |
| DisplayOrder | Number | No | Order on the sheet. |

**Indexes:** `RatingSheetID`.
**Validation:** only a Published, in-window catalog criterion may be selected (FR-048).
