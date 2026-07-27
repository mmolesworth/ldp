# CRITERION_CATALOG

**Purpose:** The shared master set of scoring criteria, reusable across all programs and cycles.
Not versioned, not cycle-scoped; a Published criterion is immutable (a change is a new criterion).
**Anchors:** RQ109–116; UC-4.4.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| CriterionCode | Single line of text | Yes | Stable code (e.g., "C01") — identifier, not display name. |
| CriterionName | Single line of text | Yes | |
| Description | Multiple lines of text | Yes | What the rater evaluates. |
| State | Choice | Yes | Draft, Published. |
| StartDate | Date | No | Set on publish. |
| EndDate | Date | No | Null = still available. |

**Indexes:** `State`.
**Validation:** all four anchors present before publish (FR-046); no edit once Published (FR-047);
only Published + in-window selectable onto a sheet (FR-048).
