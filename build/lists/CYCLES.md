# CYCLES

**Purpose:** An application cycle — its state and key dates. Scopes applications, rating sheets, placements.
**Anchors:** RQ075–081; UC-4.2; data-model.md.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier (SharePoint auto ID). |
| CycleName | Single line of text | Yes | e.g., "FY2026 LDP Cycle". |
| State | Choice | Yes | Scheduled, Open, Closed, In Review. |
| OpenDate | Date | Yes | Intended open date. |
| CloseDate | Date | Yes | Intended close date. |
| ExpectedDecisionDate | Date | Yes | Shown to applicants. |

**Indexes:** `State`.
**Validation (app-layer):** reject `CloseDate < OpenDate` or `ExpectedDecisionDate < CloseDate`
(FR-041); at most one `State = Open` at a time (FR-040 / R6).
