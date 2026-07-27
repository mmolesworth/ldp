# APPLICATIONS

**Purpose:** The central application record. Supporting documents (resume, statement of interest,
performance-rating appraisal) are **native SharePoint attachments** on this item.
**Anchors:** RQ001–014, RQ096–100; UC-1.x; data-model.md (ADD section).

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| CycleID | Lookup (CYCLES) | Yes | Owning cycle. |
| ApplicantEmail | Single line of text | Yes | Identity/owner. |
| ApplicantName | Single line of text | Yes | Manual entry until the D-1 personnel integration exists (`EMPLOYEE_DIRECTORY` withdrawn 2026-07-26). |
| Location | Single line of text | No | |
| Grade | Single line of text | No | |
| JobSeries | Single line of text | No | |
| JobTitle | Single line of text | No | |
| OPMCompetencies | Multiple lines of text | No | Three OPM competencies (values TBD Appendix B). |
| TechnicalCompetencies | Multiple lines of text | No | Three technical competencies (FR-005; values TBD Appendix B). |
| ECQs | Multiple lines of text | No | Four ECQs (values TBD Appendix B). |
| ListedOnIDP | Choice | No | Yes/No. |
| LatestPerformanceRating | Number | No | Numeric latest rating — **distinct** from the attached appraisal document (FR-006a / OI-8). |
| AttendedInfoSession | Choice | No | Yes/No. |
| InfoSessionDate | Date | No | |
| NCUAStartDate | Date | No | |
| ServiceComputationDate | Date | No | |
| Status | Choice | Yes | Draft, Submitted, Complete, Incomplete, Placed, Not Selected. |
| FirstLineSupervisorEmail | Single line of text | No | Snapshot at submission (R1/R5). |
| SecondLineSupervisorEmail | Single line of text | No | Snapshot; empty → routing `Held For Alternate`. |
| AlternateSecondLineEmail | Single line of text | No | **[PROPOSED — FR-012a]** set by DTD; do not transcribe until DTD confirms (Constitution I). |
| RoutingStage | Choice | No | Endorsement/workflow stage (see `_CHOICES.md`); `Held For Alternate` is **[PROPOSED]**. |
| RevalidationFlag | Choice | No | Yes/No — set on post-submission modification (FR-050). |

**Indexes:** `CycleID`, `ApplicantEmail`, `Status`, `RoutingStage`.
**Validation:** one application per applicant per cycle (FR-011 / R8); whole-application completeness
at submit (FR-009); Draft read-only when cycle Closed (FR-008); read-only when cycle In Review.
**Attachments:** resume, statement of interest, performance-rating appraisal (PDF/Word; size guard) — FR-006.
