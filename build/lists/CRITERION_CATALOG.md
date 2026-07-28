# CRITERION_CATALOG

**Purpose:** The shared master set of scoring criteria, reusable across all programs and cycles.
Not versioned, not cycle-scoped; a Published criterion is immutable (a change is a new criterion).
**Anchors:** RQ109–116; UC-4.4.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | SharePoint auto-number (Counter). **The primary key** — `CRITERION_ANCHORS.CatalogCriterionID` and `RATING_CRITERIA.CatalogCriterionID` are Lookups storing this value. |
| CriterionName | Single line of text | Yes | |
| Description | Multiple lines of text | Yes | What the rater evaluates. |
| State | Choice | Yes | Draft, Published, Retired. |
| StartDate | Date | No | Set on publish. |
| EndDate | Date | No | Null = still available. |

**Indexes:** `State`.
**Validation:** all four anchors present before publish (FR-046); no edit once Published (FR-047);
only Published + in-window selectable onto a sheet (FR-048).

**Retired added 2026-07-28.** Lifecycle is `Draft -> Published -> Retired`, and Retired is
reversible back to Published. It needs no change to FR-048: the Rating Sheets picker already
filters `State.Value = "Published"`, so a retired criterion drops out of selection on its own while
staying resolvable from every sheet that already references it.

**Retiring is not the same as an end date.** `EndDate` expresses "this criterion expired on a date"
and is what FR-045 / RQ117 flag on an existing sheet. Retiring is an immediate administrative
withdrawal. Both are supported; only Retired is currently exposed in the UI.

**CriterionCode removed 2026-07-28.** It was a hand-typed identifier duplicating the job of the
auto-number `ID` — the same mistake as `PROGRAMS.ProgramCode`. Nothing joined on it; both child
lookups already stored `ID`. It was only ever the lookups' **ShowField**, i.e. the label SharePoint
drew in the column, which is now `CriterionName`. **No row data changed** when it went: a lookup
stores the target's `ID` and renders the ShowField, so the anchors that displayed "C01" now display
the criterion name and point at exactly the same parent.
