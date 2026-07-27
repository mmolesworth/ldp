# Choice Sets — LDP Application Phase I

**Generated:** 2026-07-25. Enumerate these when creating the lists. **Do not invent** competency/ECQ/
status values — they are TBD pending Appendix B (D-2, Constitution I).

| List.Column | Values | Source |
|---|---|---|
| `CYCLES.State` | Scheduled, Open, Closed, In Review | RQ076 |
| `APPLICATIONS.Status` | Draft, Submitted, Complete, Incomplete, Placed, Not Selected | data-model (inferred; validate at build) |
| `APPLICATIONS.RoutingStage` | Pending First Line, Pending Second Line, Held For Alternate **[PROPOSED]**, Pending Validation, In Committee, Closed | R5 |
| `APPLICATIONS.RevalidationFlag` | Yes, No | FR-050 |
| `APPLICATIONS.ListedOnIDP` | Yes, No | data-model |
| `APPLICATIONS.AttendedInfoSession` | Yes, No | data-model |
| `SUPERVISOR_ENDORSEMENTS.SupervisorLevel` | First Line, Second Line, Alternate Second Line **[PROPOSED — FR-012a]** | RQ + FR-012a |
| `SUPERVISOR_ENDORSEMENTS.Decision` | Approve, Disapprove | RQ018 |
| `RATING_SHEETS.State` | Draft, Published | data-model |
| `RATING_SHEETS.IsCurrent` | Yes, No | data-model |
| `CRITERION_CATALOG.State` | Draft, Published | RQ112 |
| `CRITERION_ANCHORS.Score` | 0, 1, 3, 5 (fixed; no criterion-specific scale) | RQ110 |
| `PROGRAMS.State` | Active, Retired | added 2026-07-26 — retire instead of delete |
| `PROGRAM_OPTIONS.State` | Active, Retired | added 2026-07-26 — retire instead of delete |
| `PLACEMENTS.IsFinalized` | Yes, No | data-model |
| `NOTIFICATIONS.NotificationType` | Pending Action, Advance, Reminder, Disposition | data-model |
| `NOTIFICATIONS.SendOutcome` | Sent, Failed | data-model |
| `CHANGE_HISTORY.ChangeType` | Program Recommendation, Completeness Determination, Notification Sent, Placement, Post-Submission Modification, Alternate Designation **[PROPOSED for last]** | data-model + FR-012a/FR-050 |
| `APPLICATIONS.OPMCompetencies` | **TBD — Appendix B (D-2)** | deferred |
| `APPLICATIONS.TechnicalCompetencies` | **TBD — Appendix B (D-2)** | deferred |
| `APPLICATIONS.ECQs` | **TBD — Appendix B (D-2)** | deferred |

**Modeling note:** competencies/ECQs may be multi-select choice or delimited text pending Appendix B;
decide the exact column type once the value lists arrive.
