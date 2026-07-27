# LDP Application — Proposed Screens

**Project:** NCUA OHR Leader Development Program Application (RITM0069731)
**Scope:** Phase I

Screens grouped by actor, with the use case each traces to and a short description. Descriptions state what a screen does, not how it looks; visual design is a separate deliverable.

## Applicant

| # | Screen | Use case | Description |
|---|---|---|---|
| 1 | Application form | UC-1.1, UC-1.3, UC-1.4 | Create and submit an application: personnel fields autofilled from HR Links, up to three ranked program-option choices (program then option), competencies, ECQs, supporting information, three document slots with import/download/delete. Save for Later or Submit. Presented as navigable sections (wizard). |
| 2 | My applications landing | UC-1.2, UC-1.5 | Entry point showing the applicant's application for the cycle and its state, with the right action: continue a draft, or open a submitted application to modify. |
| 3 | Resume draft view | UC-1.2 | The form repopulated with saved data. Personnel fields refresh on open with an accept prompt for any changed value. Read-only if the cycle closed since the save. |
| 4 | Edit submitted application | UC-1.5 | Modify any part of a submitted application until the cycle reaches In Review. Changes write to the change history and flag the application for DTD re-validation. |
| 5 | Submission confirmation | UC-1.1 | Confirmation state after a successful submit, plus the confirmation email. |

## Supervisor

| # | Screen | Use case | Description |
|---|---|---|---|
| 6 | Endorsement screen | UC-2.1 | Review the assigned application read-only, record approve or disapprove with a required disposition statement, and optionally recommend alternative program options. 2nd line also sees the 1st line's decision. |

## DTD

| # | Screen | Use case | Description |
|---|---|---|---|
| 7 | Validation screen | UC-2.2 | Check an application for completeness, mark it Complete or Incomplete, and edit in place to attach missing documents or fill missing fields. Complete advances it to the committee. |
| 8 | Validation queue | RQ029, RQ098 | DTD's working list of applications needing attention, each with the reason: awaiting validation, marked Incomplete, or modified by the applicant since the last determination. |
| 9 | Placement screen | UC-3.2 | Open a program, see its ranked pool with each applicant's committee rank, their ranked option preferences, supervisor recommendations, and placement status. Place into an option, transfer, remove, and finalize the cohort. |
| 10 | Notification send | UC-3.3 | The finalized cohort as a checkbox list with each applicant's disposition and notified status. Select individually or all, send, resend with a warning, and see failures. |

## Committee

| # | Screen | Use case | Description |
|---|---|---|---|
| 11 | Scoring screen | UC-3.1 | Open a program and see its pool, one row per applicant. Score each against the published rating sheet (ranged and fixed criteria) alongside the full application and prior decisions. Ranking computes once the pool is complete. |

## Administration

| # | Screen | Use case | Description |
|---|---|---|---|
| 12 | Program option management | UC-4.1 | The nine options grouped under their three programs. Add, edit, and remove options, each with its ten attributes. |
| 13 | Cycle management | UC-4.2 | The cycle's three dates and its state, with controls to move it: Scheduled → Open → Closed → In Review. Date validation and the one-Open constraint. |
| 14 | Rating sheet builder | UC-4.3 | One sheet per program per cycle. Author criteria (name, type, range or fixed value), save as immutable versions, view version history, publish and unpublish. |

## Public / shared

| # | Screen | Use case | Description |
|---|---|---|---|
| 15 | Landing page | RQ101–RQ104 | Public, applicant-facing page presenting program information and the current cycle's state and dates, plus eligibility guidance, FAQ, contact, and prior-cohort outcomes. Provides authenticated sign-in for committee and DTD, routing each to their workspace. |

## Cross-cutting components

| Component | Use case | Description |
|---|---|---|
| Change history panel | RQ094, RQ095 | What changed, who changed it, when. Appears on the application wherever a reviewer opens it (screens 6, 7, 9, 11). Hidden from the applicant. |
| Program details panel | RQ108 | A program option's full details (the ten attributes), viewable while selecting programs without leaving the application. Shared with the landing page's program display. |

## Email templates

| Template | Use case | Description |
|---|---|---|
| Event notifications | UC-5.1 | Pending action, advance to next reviewer, submission confirmation. Each links to the relevant application or task. |
| Reminder emails | UC-5.2 | The six Appendix D triggers, with the message text the appendix supplies. |
| Disposition emails | UC-3.3 | Selected (naming the program option) and not selected. Content authored by DTD. |

## Notes

- **Screen 2 (My applications landing) has no requirement behind it.** UC-1.2 and UC-1.5 both have the applicant "opening" their application without specifying where from. A requirement may be warranted before design.
- **Descriptions are behavior, not design.** Panels, wizard chrome, and page layout are design decisions, captured in the design deliverable rather than here.
- **Mockup coverage is thin.** The existing form mockups (Appendix B) cover parts of screens 1 and 6; pages 3–6 are Phase II. The Phase I UI is effectively greenfield.
