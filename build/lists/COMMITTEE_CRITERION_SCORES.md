# COMMITTEE_CRITERION_SCORES

**Purpose:** The committee's per-criterion score and comment for an applicant's program choice.
One row per (choice × criterion). Aggregate lives on `APPLICATION_PROGRAM_CHOICES`
(`FinalScore`, `PercentOfPossible`, `ScoredBy`, `ScoredDate`).
**Anchors:** RQ036–043, RQ119; UC-3.1; added 2026-08-07.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| ApplicationProgramChoiceID | Lookup (APPLICATION_PROGRAM_CHOICES) | Yes | Parent aggregate row (application × program). |
| RatingCriterionID | Lookup (RATING_CRITERIA) | Yes | Which criterion on which sheet version. Preserves the exact rubric instance scored. |
| Score | Number | Yes | 0, 1, 3, or 5 — enforced by input (anchor-card selector), matches `CRITERION_ANCHORS.Score`. |
| Comment | Multiple lines of text | No | Committee's discussion notes for this criterion. Optional. |

**Indexes:** `ApplicationProgramChoiceID`, `RatingCriterionID`.
**Uniqueness:** (`ApplicationProgramChoiceID`, `RatingCriterionID`) — one score per criterion per
choice.
**Why link to RATING_CRITERIA, not CRITERION_CATALOG.** The join row is the specific instance the
committee actually saw (order, sheet version, catalog identity). Linking to the catalog master
would lose the sheet-version pin — a new publish that swaps criteria would silently re-parent
old scores. The catalog identity is still one hop away (`RatingCriterionID.CatalogCriterionID`).
**Aggregate is computed on submit**, not stored per-criterion. The Score Screen writes N rows here
plus one Patch on the parent (`FinalScore = Sum`, `PercentOfPossible = Sum / (5 × N)`).
