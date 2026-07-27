# SUPERVISOR_ENDORSEMENTS

**Purpose:** Each supervisor's endorsement decision, statement, and advisory program recommendations.
**Anchors:** RQ018–025; UC-2.1.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| ApplicationID | Lookup (APPLICATIONS) | Yes | Application being endorsed. |
| SupervisorEmail | Single line of text | Yes | Recording supervisor. |
| SupervisorLevel | Choice | Yes | First Line, Second Line, **Alternate Second Line [PROPOSED — FR-012a]**. |
| Decision | Choice | Yes | Approve, Disapprove. |
| DispositionStatement | Multiple lines of text | Yes | Required on both approve and disapprove (FR-013). |
| RecommendedOptions | Multiple lines of text | No | Advisory; does not alter applicant selections (FR-016). |
| DecisionDate | Date | Yes | When recorded. |

**Indexes:** `ApplicationID`.
**Validation:** no decision without a statement (FR-013). An `Alternate Second Line` decision is
treated as the second-line decision (FR-012a; Proposed — do not transcribe until DTD confirms).
