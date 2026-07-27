# COMMITTEE_SCORES

**Purpose:** An applicant's score for a program (hybrid). `FinalScore`/`PercentOfPossible` are
queryable Numbers; the per-criterion breakdown is JSON.
**Anchors:** RQ036–043, RQ119; UC-3.1.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| ApplicationID | Lookup (APPLICATIONS) | Yes | Applicant being scored. |
| ProgramID | Lookup (PROGRAMS) | Yes | Program pool. |
| RatingSheetID | Lookup (RATING_SHEETS) | Yes | Published version scored against. |
| FinalScore | Number | Yes | Sum of anchors (ranking within pool). |
| PercentOfPossible | Number | No | FinalScore ÷ (5 × criteria count) — cross-pool comparison (RQ119). |
| CriterionScores | Multiple lines of text | No | Per-criterion breakdown as JSON. |
| Rank | Number | No | Rank within the program pool (written at ranking). |
| ScoredBy | Single line of text | No | Committee recorder. |
| ScoredDate | Date | No | When scoring completed. |

**Indexes:** `ApplicationID`, `ProgramID`, `RatingSheetID`.
**Validation:** only anchor values 0/1/3/5 contribute (FR-022, enforced by fixed-choice input — R4);
ranking writes `Rank` once the pool is fully scored (R2); scored/ranked independently per program.
