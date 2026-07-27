# LDP Phase I — Flagged Inconsistencies & Open Items

**Project:** NCUA OHR Leader Development Program Application (RITM0069731) — Phase I
**Raised during:** `/speckit-specify` review of `docs/LDP_Functional_Requirements_Phase_I.md`,
`docs/LDP_Use_Cases.md`, and `docs/LDP_Logical_Data_Model.md` against
`.specify/memory/constitution.md`.
**Spec:** `specs/001-ldp-phase-i/spec.md`
**Date:** 2026-07-25

This document is the maker's review copy of every discrepancy found across the source documents,
per Constitution Principle I (discrepancies surfaced and resolved at specify/clarify). It mirrors
the "Cross-Document Inconsistencies & Open Items" section of the spec.

---

## Legend

- **RESOLVED** — a decision has been made; the spec reflects it. A source-document edit may still
  be pending (noted under *Doc action*).
- **OPEN** — recorded for review; a sensible default is applied in the spec but your confirmation
  (or a `/speckit-clarify` pass) is welcome.
- **DEPENDENCY** — external input or a planning decision is required; does not block the spec.

---

## Resolved (blocking clarifications Q1–Q3)

### OI-1 — Technical competencies missing from UC-1.1 — RESOLVED (Q1 = A)

- **Conflict:** UC-1.1 main scenario step 3 lists "3 OPM competencies, 4 ECQs" and omits the
  **three technical competencies**. RQ007 and `APPLICATIONS.TechnicalCompetencies` both require
  them.
- **Decision:** The application form captures all three groups — **3 OPM + 3 technical + 4 ECQ**.
- **Spec:** FR-005 stands as written.
- **Doc action:** Correct **UC-1.1 step 3** to add the three technical competencies.

### OI-2 — SharePoint list naming convention (irreversible) — RESOLVED (Q2 = B)

- **Conflict:** The data model names lists in `UPPER_SNAKE_CASE` (e.g.,
  `APPLICATION_PROGRAM_CHOICES`). The Constitution's *Additional Constraints → Naming conventions*
  require **Pascal case** for data sources. A SharePoint list name becomes its Power Fx identifier
  and cannot be renamed after the list is created and referenced.
- **Decision:** **Upper snake case wins.** Lists are created and referenced in upper snake case,
  matching the data model; column (field) names remain Pascal case.
- **Spec:** Recorded at OI-2; no list names appear in the spec body (kept tech-neutral).
- **Doc action (Constitution) — DONE.** The *Additional Constraints → Naming conventions* rule was
  amended in **Constitution v1.2.0 (2026-07-25)**: SharePoint list names are `UPPER_SNAKE_CASE`,
  column names Pascal case; the prior "Open item" was replaced with a "Resolved" note. No deviation
  remains.
- **Doc action (data model) — DONE.** `docs/LDP_Logical_Data_Model.md` Conventions section now
  carries a ratified naming note (list names `UPPER_SNAKE_CASE`, columns Pascal) citing Constitution
  v1.2.0. The conflict is fully closed across governance, spec, and data model.

### OI-3 — Reminder repetition undefined — RESOLVED (Q3 = B)

- **Conflict:** RQ058–RQ061 state only each reminder's **first** fire; UC-5.2 extension 3b leaves
  repeat-vs-once "to be confirmed."
- **Decision:** Reminders **re-fire each interval** until the required action is recorded —
  5 days for first-line/second-line supervisors and the committee, 3 days for DTD.
- **Spec:** FR-032 updated with the repeat clause; Assumptions and Edge Cases updated.
- **Doc action:** Optionally add a repeat clause to RQ058–RQ061 and resolve UC-5.2 ext 3b.

---

## Open (recorded for review — non-blocking)

### OI-4 — Stale requirements note about UC-2.1

- The requirements note on RQ023–RQ025 says "UC-2.1 still describes the older revise model and
  needs the same correction." **UC-2.1 as written already reflects the recommend model** (extension
  1a: records the recommendation without altering selections).
- **Assessment:** The note appears stale; the use case itself needs no change.
- **Doc action:** Correct or remove the note in the requirements' "Notes and open items."

### OI-5 — UC-4.4 missing from the Use Cases contents index

- The Use Cases "Contents" list (Administration) shows UC-4.1, UC-4.2, UC-4.3 but **omits UC-4.4
  Manage Rating Criterion Catalog**, which exists in the body and is referenced by UC-4.3 and the
  requirements.
- **Doc action:** Add UC-4.4 to the Contents index.

### OI-6 — Endorsement routing when there is no second-line supervisor

- RQ016 routes to the second-line supervisor after the first-line decision. Behavior for an
  applicant at the **top of the supervisory chain** (no second-line supervisor) is undefined.
- **Default applied:** Assumed rare; flagged rather than designed.
- **Suggested resolution:** Define whether such an application advances straight to DTD after the
  first-line decision, or whether a designated alternate acts as second line. Candidate for
  `/speckit-clarify`.

### OI-7 — Committee "recorder" identity and authorization

- UC-3.1 has the committee act "through a designated recorder," but how the recorder is identified
  and authorized to enter scores is unspecified. This bears on the **data-layer permission model**
  (Constitution VI — confidentiality enforced at the data layer).
- **Suggested resolution:** Define who may record committee scores and how that permission is
  granted at the SharePoint layer. Resolve at `/speckit-clarify` or `/speckit-plan`.

### OI-8 — "Performance rating": document vs. numeric field

- "Performance rating" appears both as a required **attached document** (RQ009, one of the three
  supporting documents) and as a numeric field `APPLICATIONS.LatestPerformanceRating`.
- **Assessment:** Likely distinct (a document plus a separate latest-rating number), but confirm
  they are not a conflation.
- **Doc action:** Confirm and, if distinct, note the distinction in the data model.

### OI-9 — Committee reminder terminology ("endorsement" vs "scoring")

- RQ060 and the UC-5.2 trigger table describe the committee's pending action as
  "endorsement/approval," though the committee's action is **scoring**, not endorsement.
- **Assessment:** Cosmetic; no behavioral impact.
- **Doc action:** Align the wording (e.g., "committee scoring pending").

---

## Dependencies (external input / planning decisions)

### D-1 — HR Links & organizational-hierarchy access vs. "no premium connectors"

- FR-002 (populate personnel data) and FR-012 (assign supervisors by hierarchy) require reading
  HR Links personnel data and the reporting chain. **Constitution Principle II forbids premium
  connectors.** The standard path to such data may require a premium connector or a maker-provided
  intermediary (e.g., a nightly export into a SharePoint list).
- **Impact:** Material technical risk to two P1 requirements.
- **Resolve at:** `/speckit-plan` — decide the non-premium retrieval mechanism.

### D-2 — Source appendices not present in the repository

- Appendix A (full application field set), Appendix B (traceability matrix / choice values), and
  Appendix D (reminder triggers) are referenced by the source documents but are **absent from
  `docs/`**. They are needed to finalize field lists and choice enumerations (competency lists,
  ECQ lists, status values).
- **Resolve at:** obtain or confirm these appendices before those details enter the build.

---

## Suggested next actions

1. ~~Amend the Constitution for OI-2 (list naming carve-out).~~ **Done — Constitution v1.2.0.**
2. **Edit the source documents** for the doc actions above (OI-1 UC-1.1 fix; OI-4 stale note;
   OI-5 contents index; OI-8 field/document note; OI-9 wording).
3. **Run `/speckit-clarify`** to close OI-6 and OI-7 if you want them settled before planning.
4. **Provide Appendix A/B/D** (D-2) and decide the HR Links approach (D-1) — the latter can wait
   for `/speckit-plan`.
