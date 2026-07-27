# Leader Development Program Application — Functional Requirements (Phase I)

**Project:** NCUA OHR Leader Development Program Application (RITM0069731)
**Scope:** Phase I — value stream through selection (Submit Application, Secure Endorsements, Select Participant), plus administration (programs, cycles, rating sheets).
**Convention:** "The system shall" statements, grouped by functional area, continuous RQ numbering.

## Application Submission and Applicant Experience

| # | Description | Status |
|---|---|---|
| RQ001 | The system shall allow an authenticated NCUA employee to create and submit an application to the Leader Development Program. | Not Started |
| RQ002 | The system shall populate the applicant's personnel information (name, location, grade, job series, job title) from HR Links when an application is started. | Not Started |
| RQ003 | The system shall allow the applicant to manually enter personnel information when it cannot be retrieved from HR Links. | Not Started |
| RQ004 | The system shall prompt the applicant to accept any personnel value that has changed since a draft was last saved before applying the change. | Not Started |
| RQ005 | The system shall allow the applicant to select and rank up to three program options, ordered from highest to lowest preference. | Not Started |
| RQ006 | The system shall allow the applicant to select three OPM competencies. | Not Started |
| RQ007 | The system shall allow the applicant to select three technical competencies. | Not Started |
| RQ008 | The system shall allow the applicant to select four Executive Core Qualifications (ECQs). | Not Started |
| RQ009 | The system shall allow the applicant to attach, download, and remove supporting documents (resume, statement of interest, performance rating). | Not Started |
| RQ010 | The system shall allow the applicant to save an incomplete application as a draft and resume it later. | Not Started |
| RQ011 | The system shall present a saved draft as read-only, and prevent submission, when the application cycle is closed. | Not Started |
| RQ012 | The system shall validate that all required fields and documents are present before accepting a submission. | Not Started |
| RQ013 | The system shall confirm to the applicant that their application was submitted successfully. | Not Started |
| RQ014 | The system shall prevent an applicant from submitting more than one application per cycle. | Not Started |

## Endorsement

| # | Description | Status |
|---|---|---|
| RQ015 | The system shall route a submitted application to the applicant's first-line supervisor for endorsement. | Not Started |
| RQ016 | The system shall route an application to the applicant's second-line supervisor after the first-line supervisor records a decision. | Not Started |
| RQ017 | The system shall assign supervisors to an application based on the applicant's position in the organizational hierarchy. | Not Started |
| RQ018 | The system shall allow a supervisor to record an endorsement decision of approve or disapprove. | Not Started |
| RQ019 | The system shall require a disposition statement with every endorsement decision, whether approve or disapprove. | Not Started |
| RQ020 | The system shall display the first-line supervisor's decision and statement to the second-line supervisor. | Not Started |
| RQ021 | The system shall advance an application to the next reviewer regardless of whether a supervisor approved or disapproved it. | Not Started |
| RQ022 | The system shall provide each supervisor a link to the applicant's application in view-only mode. | Not Started |
| RQ023 | The system shall allow a supervisor to recommend one or more alternative program options during endorsement, without altering the applicant's own program-option selections. | Not Started |
| RQ024 | The system shall prevent a supervisor from altering the applicant's program-option selections. | Not Started |
| RQ025 | The system shall record each supervisor's program-option recommendation, capturing the recommended options, who recommended them, and when. | Not Started |

## Application Validation

| # | Description | Status |
|---|---|---|
| RQ026 | The system shall allow DTD to review a submitted application after both supervisors have recorded their decisions. | Not Started |
| RQ027 | The system shall allow DTD to mark an application as Complete or Incomplete. | Not Started |
| RQ028 | The system shall prevent an application from advancing to committee review until it is marked Complete. | Not Started |
| RQ029 | The system shall present DTD a list of applications marked Incomplete for follow-up. | Not Started |
| RQ030 | The system shall allow DTD to edit an application, including attaching documents and supplying field values, to bring it to a complete state. | Not Started |
| RQ031 | The system shall record each completeness determination in the change history, capturing the determination, who made it, and when. | Not Started |
| RQ032 | The system shall advance an application to committee review when DTD marks it Complete. | Not Started |

## Committee Review and Ranking

| # | Description | Status |
|---|---|---|
| RQ033 | The system shall present each committee the applicants who selected a given program or any of its program options. | Not Started |
| RQ034 | The system shall display to the committee the full application, including supporting documents, supervisor decisions and statements, and the DTD completeness determination. | Not Started |
| RQ035 | The system shall present the committee the published rating sheet for the program being scored. | Not Started |
| RQ036 | The system shall allow the committee to select one of the defined anchor values (0, 1, 3, or 5) for each criterion. | Not Started |
| RQ037 | The system shall accept only a defined anchor value (0, 1, 3, or 5) as a criterion score and shall reject any other value. | Not Started |
| RQ038 | *Removed.* Predefined criteria no longer exist; every criterion is committee-scored on the shared anchor scale. | Removed |
| RQ039 | The system shall sum an applicant's criterion points into a final score. | Not Started |
| RQ040 | The system shall retain committee scores entered across multiple scoring sessions. | Not Started |
| RQ041 | The system shall rank the applicants in a program pool by final score once every applicant in the pool has been scored. | Not Started |
| RQ042 | The system shall record each applicant's rank on their application. | Not Started |
| RQ043 | The system shall include an applicant once in a program's pool regardless of how many of that program's options they selected, and shall score and rank the applicant independently in each program they selected. | Not Started |
| RQ044 | The system shall prevent committee scoring of a program until its rating sheet is published. | Not Started |
| RQ119 | The system shall compute each applicant's percent of possible as the final score divided by the product of five and the number of criteria on the applicant's rating sheet. | Not Started |

## Selection and Placement

| # | Description | Status |
|---|---|---|
| RQ045 | The system shall present DTD, for each program, the applicants in that pool with their committee ranking, their percent of possible, their ranked program-option preferences, any supervisor recommendations, and their placement status. | Not Started |
| RQ046 | The system shall allow DTD to place an applicant into a program option. | Not Started |
| RQ047 | The system shall permit an applicant to be placed in at most one program option at any time. | Not Started |
| RQ048 | The system shall indicate to DTD when a selected applicant is already placed in another program option. | Not Started |
| RQ049 | The system shall transfer an applicant's placement to a new program option when DTD places them there, removing the prior placement. | Not Started |
| RQ050 | The system shall allow DTD to remove an applicant's placement. | Not Started |
| RQ051 | The system shall allow DTD to finalize the cohort. | Not Started |
| RQ052 | The system shall lock all placements when the cohort is finalized. | Not Started |
| RQ053 | The system shall mark every applicant not placed in a program option as not selected when the cohort is finalized. | Not Started |
| RQ054 | The system shall allow DTD to revise placements at any time before the cohort is finalized. | Not Started |

## Notifications and Reminders

| # | Description | Status |
|---|---|---|
| RQ055 | The system shall notify the responsible stakeholder by email when an action becomes pending for them. | Not Started |
| RQ056 | The system shall include in each notification a link to the relevant application or task. | Not Started |
| RQ057 | The system shall notify the next reviewer when an application advances to them. | Not Started |
| RQ058 | The system shall send a first-line supervisor a reminder five days after an approval is pending with no action recorded. | Not Started |
| RQ059 | The system shall send a second-line supervisor a reminder five days after an approval is pending with no action recorded. | Not Started |
| RQ060 | The system shall send a committee reminder five days after an endorsement is pending with no action recorded. | Not Started |
| RQ061 | The system shall send DTD a reminder three days after a selection entry is pending with no data recorded. | Not Started |
| RQ062 | The system shall stop reminders for a step once the required action is recorded. | Not Started |
| RQ063 | The system shall withhold all disposition results from applicants until DTD issues the final notifications. | Not Started |
| RQ064 | The system shall allow DTD to notify applicants of their disposition after the cohort is finalized. | Not Started |
| RQ065 | The system shall allow DTD to select notification recipients individually or select all applicants in the cohort. | Not Started |
| RQ066 | The system shall send each notified applicant their disposition, indicating selection and program option, or non-selection. | Not Started |
| RQ067 | The system shall record the send outcome for each applicant and mark those successfully sent as notified. | Not Started |
| RQ068 | The system shall record each notification send in the change history. | Not Started |
| RQ069 | The system shall indicate to DTD which applicants have already been notified. | Not Started |
| RQ070 | The system shall report notification send failures to DTD and allow the applicant to be included in a later send. | Not Started |
| RQ071 | The system shall allow DTD to send a notification to an applicant who has already been notified, after warning that a notification was previously sent. | Not Started |

## Administration — Program Options

| # | Description | Status |
|---|---|---|
| RQ072 | The system shall allow DTD to create, edit, and remove program options. | Not Started |
| RQ072a **[PROPOSED]** | The system shall allow DTD to create, edit, and remove programs, recording each program's name and code. | Proposed — awaiting DTD confirmation |
| RQ072b **[PROPOSED]** | The system shall prevent deletion of a program or program option that is referenced by any application selection, placement, rating sheet, or committee score, and shall notify the user why the deletion was refused. | Proposed — awaiting DTD confirmation |
| RQ073 | The system shall record for each program option its name, description, vendor, grade level, course length, competency, requirements, and website. | Not Started |
| RQ074 | The system shall organize program options under their parent program. | Not Started |

## Administration — Application Cycles

| # | Description | Status |
|---|---|---|
| RQ075 | The system shall allow DTD to create an application cycle with an open date, a close date, and an expected decision date. | Not Started |
| RQ076 | The system shall support four cycle states: Scheduled, Open, Closed, and In Review. | Not Started |
| RQ077 | The system shall allow DTD to transition a cycle between states. | Not Started |
| RQ078 | The system shall accept applicant submissions and resumes only while a cycle is Open. | Not Started |
| RQ079 | The system shall prevent more than one cycle from being Open at the same time. | Not Started |
| RQ080 | The system shall reject cycle dates that are inconsistent, such as a close date before the open date or an expected decision date before the close date. | Not Started |
| RQ081 | The system shall display the expected decision date to applicants. | Not Started |

## Administration — Committee Rating Sheets

| # | Description | Status |
|---|---|---|
| RQ082 | The system shall allow DTD to create a rating sheet for a program within a cycle. | Not Started |
| RQ083 | The system shall allow DTD to select one or more criteria from the shared criterion catalog onto a rating sheet. | Not Started |
| RQ084 | *Removed.* Per-criterion point ranges are replaced by the shared 0/1/3/5 anchor scale, defined once in the criterion catalog rather than per criterion. | Removed |
| RQ085 | *Removed.* Predefined criteria no longer exist; every criterion is committee-scored on the shared anchor scale. | Removed |
| RQ086 | The system shall prevent a rating sheet from being saved without at least one selected criterion. | Not Started |
| RQ087 | The system shall record each saved rating sheet as an immutable version. | Not Started |
| RQ088 | The system shall create a new version, superseding the prior, each time DTD saves a change to a rating sheet. | Not Started |
| RQ089 | The system shall allow DTD to view prior versions of a rating sheet. | Not Started |
| RQ090 | The system shall allow DTD to publish a rating sheet version. | Not Started |
| RQ091 | The system shall prevent further changes to a rating sheet once it is published. | Not Started |
| RQ092 | The system shall allow DTD to unpublish a rating sheet only while no scores have been recorded against it. | Not Started |

## Administration — Rating Criterion Catalog

The shared criterion catalog is a single set of scoring criteria available to every program's rating sheet. A rating sheet selects criteria from it (RQ083) rather than authoring them. Criterion text (name, description, anchors, examples) lives on the catalog and does not vary by program.

| # | Description | Status |
|---|---|---|
| RQ109 | The system shall allow DTD to define a criterion in the shared criterion catalog, each with a name, a description, and a set of scoring anchors. | Not Started |
| RQ110 | The system shall provide the same four scoring anchors, 0, 1, 3, and 5, for every catalog criterion, and shall not permit a criterion-specific scale. | Not Started |
| RQ111 | The system shall allow DTD to attach an illustrative example to any anchor of a catalog criterion. | Not Started |
| RQ112 | The system shall maintain each catalog criterion in one of two states, Draft or Published. | Not Started |
| RQ113 | The system shall allow DTD to edit a catalog criterion while it is Draft. | Not Started |
| RQ114 | The system shall prevent any change to a catalog criterion once it is Published. A change to a published criterion is made by creating a new criterion. | Not Started |
| RQ115 | The system shall record a start date and an end date for each catalog criterion, where a null end date denotes a criterion still available for selection. | Not Started |
| RQ116 | The system shall allow only a Published criterion within its availability window to be selected onto a rating sheet. | Not Started |
| RQ117 | The system shall flag a criterion on a draft rating sheet whose end date has passed. | Not Started |
| RQ118 | The system shall prevent a rating sheet from being published while it carries a criterion whose end date has passed. | Not Started |

## Change History

| # | Description | Status |
|---|---|---|
| RQ093 | The system shall maintain a change history for each application, recording what changed, who changed it, and when. | Not Started |
| RQ094 | The system shall display an application's change history on the application record. | Not Started |
| RQ095 | The system shall withhold an application's change history from the applicant. | Not Started |

## Post-Submission Modification

| # | Description | Status |
|---|---|---|
| RQ096 | The system shall allow an applicant to modify any part of their submitted application until the cycle enters the In Review state. | Not Started |
| RQ097 | The system shall prevent an applicant from modifying their application once the cycle enters the In Review state. | Not Started |
| RQ098 | The system shall flag an application for DTD re-validation when the applicant modifies it after submission. | Not Started |
| RQ099 | The system shall record each post-submission applicant modification in the change history. | Not Started |
| RQ100 | The system shall prevent committee scoring until the cycle enters the In Review state. | Not Started |

## Presentation and Navigation

These requirements state what the system must present and how it must let users move through it. They are deliberately design-neutral: they fix behavior, not layout. Visual treatment (panels, wizard chrome, page layout) is a design deliverable, not specified here.

| # | Description | Status |
|---|---|---|
| RQ101 | The system shall provide a public landing page presenting program information and the current application cycle's state and dates. | Not Started |
| RQ102 | The system shall present landing-page content appropriate to the current cycle state (Scheduled, Open, Closed, or In Review). | Not Started |
| RQ103 | The system shall present supporting applicant information on the landing page, including eligibility guidance, frequently asked questions, contact information, and prior-cohort outcomes. | Not Started |
| RQ104 | The system shall provide authenticated sign-in for committee members and DTD administrators, directing each to their respective workspace. | Not Started |
| RQ105 | The system shall present the application as distinct sections the applicant can navigate freely, in any order. | **Superseded by RQ105a** |
| RQ105a **[PROPOSED]** | The system shall present the application as an ordered sequence of steps, navigable forward and backward one step at a time, with direct jump-to-step links available from the final review step. | Proposed — awaiting DTD confirmation |
| RQ105b **[PROPOSED]** | The system shall prompt the applicant to accept or decline changed personnel values when a saved draft is resumed and the directory record has since changed. | Proposed — awaiting DTD confirmation |
| RQ106 | The system shall visually indicate incomplete required items as the applicant works through the application, without blocking navigation between sections. | Not Started |
| RQ107 | The system shall validate the completeness of the whole application at submission, not on a per-section basis. | Not Started |
| RQ108 | The system shall allow the applicant to view a program option's full details while selecting programs, without leaving the application. | Not Started |

---

## Notes and open items

- **Presentation requirements are design-neutral (RQ101–RQ108).** They fix what the system presents and how users navigate; the visual design (landing-page layout, slide-out details panel, wizard chrome, incompleteness cues) is a design deliverable. RQ103's "eligibility guidance" is static explanatory content authored by DTD, not a system-enforced eligibility rule — eligibility remains outside the system.
- **Post-submission modification window (new).** Applicants may modify a submitted application after the cycle closes, up until DTD sets the cycle to **In Review**. A modification flags the application for DTD re-validation (RQ098); supervisors are not re-engaged. RQ024 was rewritten accordingly — it previously read as a blanket freeze at submission, when its intent was that *supervisors* cannot change the applicant's selections.
- **Program-level evaluation, option-level selection and placement (correction).** Applicants select and rank program options; the committee pools, scores, and ranks at the **program** level (one pool per program, one rating sheet per program per cycle); DTD places into a **program option**. An applicant who selects more than one option within the same program appears once in that program's pool, with all their option preferences retained to inform placement. This corrects an earlier model that pooled and scored per program option. Affects RQ033, RQ035, RQ041, RQ043, RQ044, RQ045, RQ082.
- **Shared rating criterion catalog (new).** Rating sheets now select criteria from a single shared catalog rather than authoring them per sheet, and every criterion is committee-scored on a fixed 0/1/3/5 anchor scale. This reworded RQ036, RQ037, RQ083, and RQ086; removed RQ038, RQ084, and RQ085 (no predefined criteria, no per-criterion ranges); added the RQ109–RQ118 catalog section and RQ119 (percent of possible, consumed by RQ045). RQ035 needed no change: it already reads program-level. RQ037 is written to hold whether scoring input is a fixed choice set or a typed value, so the input-design question does not gate it. The data model, UC-4.3, a new catalog use case, and Proposed Screens (screens 11 and 14) carry the corresponding edits in their own artifacts.

- **RQ023–RQ025 (supervisor recommendation).** Revised from an earlier "supervisor revises selections" model at DTD's request. Supervisors now *recommend* alternative program options without altering the applicant's selections; the recommendation informs DTD at placement only (RQ045) and does not affect committee pooling. UC-2.1 still describes the older revise model and needs the same correction in a later use-case cleanup pass.
- **RQ058–RQ061 (reminder repetition) depend on an open customer question.** These state only each reminder's first fire, per Appendix D. Appendix D does not define whether reminders repeat. If the customer confirms repetition, each needs a repeat clause or a separate requirement.
- **Phase II reminders excluded.** Appendix D's Detail Entry and Consult Date Request triggers fire for Phase II stages and are out of scope here.
- **Change history (resolved).** Now established by RQ093 and made visible by RQ094–RQ095. The history is shown on the application record to supervisors, DTD, and committee members, and withheld from the applicant. RQ025, RQ031, and RQ068 write to it. No data model change was required — the CHANGE_HISTORY list already carries what changed, who, and when.
- **Requirements originating from design decisions (beyond the RITM).** RQ011, RQ014, RQ024–RQ025, RQ030, RQ047–RQ054, and RQ087–RQ092 encode decisions made during use-case work rather than lines from the RITM. Correct, but these are the statements a reviewer may not recognize from the source requirements.
- **Excluded by prior decisions.** No eligibility-enforcement requirements (eligibility is not a system concern); no capacity requirements (DTD-managed, outside the system); no PDF/Word format-restriction requirement (treated as applicant instruction, not system behavior).
- **UI impact of RQ023.** The endorsement screen (Appendix B mockup, page 2) needs a recommended-options field added.
