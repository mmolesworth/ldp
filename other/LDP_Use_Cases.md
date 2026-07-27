# LDP Application — Use Cases

NCUA OHR Leader Development Program Application (RITM0069731) — Phase I

## Contents

**Stage 1 — Submit Application**
- UC-1.1 Submit LDP Application
- UC-1.2 Resume a Saved Application
- UC-1.3 Manage Supporting Document
- UC-1.4 Populate Personnel Data
- UC-1.5 Modify a Submitted Application

**Stage 2 — Secure Endorsements**
- UC-2.1 Record Endorsement Decision
- UC-2.2 Validate Application

**Stage 3 — Select Participant**
- UC-3.1 Review and Rank Applicants by Program
- UC-3.2 Record Final Selection and Placement
- UC-3.3 Issue Cohort Disposition Notifications

**Administration**
- UC-4.1 Manage Program Option
- UC-4.2 Manage Application Cycle
- UC-4.3 Manage Committee Rating Sheet

**Shared**
- UC-5.1 Notify Stakeholder of Pending Action
- UC-5.2 Send Reminder for Overdue Action

---

## UC-1.1: Submit LDP Application

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | User goal |
| **Primary actor** | Applicant |
| **Supporting actor** | HR Links |

### Stakeholders and interests

- **Applicant:** submit a complete application with minimal manual entry, without losing work on interruption, and get confirmation it went through.
- **DTD:** receive complete, valid applications so validation is not spent chasing missing fields.
- **1st line supervisor:** receive only genuinely submitted applications into their review queue.
- **OHR / NCUA:** a standardized, auditable submission replacing the email-based process.

### Preconditions

- Applicant is authenticated.
- Applicant is an active NCUA employee.
- The LDP application cycle is open.

### Success guarantee

The application is recorded as Submitted, complete against Appendix A / Appendix B, queued for 1st line supervisor review, and a submission confirmation is sent. The applicant's candidacy is established.

### Minimal guarantee

No partial application is submitted. Data already entered is retained as a Draft, so the applicant loses no work, and the applicant is shown what remains.

### Trigger

Applicant chooses to begin a new LDP application.

### Main success scenario

1. Applicant starts a new application.
2. System populates personnel information (Name, Location, Grade, Job Series, Job Title) from HR Links. *[UC-1.4]*
3. Applicant completes the application: ranked program selections (one to three, ranked highest to lowest), 3 OPM competencies, 4 ECQs, and supporting information per Appendix A.
4. Applicant attaches the required documents: resume, statement of interest, performance rating. *[UC-1.3, per document]*
5. Applicant submits the application.
6. System validates completeness against the required fields and records the application as Submitted.
7. System sends the applicant a submission confirmation. *[UC-5.1]*

### Extensions

- **1a.** An application already exists for this applicant in the current cycle: system opens it (Draft resumes via UC-1.2; a prior submission blocks a duplicate).
- **2a.** Personnel data cannot be retrieved: system leaves the personnel fields empty for manual entry and continues. Fail quietly.
- **4a.** An attached file is missing or not PDF/Word: system rejects it and prompts for a valid file.
- **5a.** Applicant chooses Save for Later: system saves the application as Draft; the use case ends without submission and candidacy is not yet established.
- **6a.** Submission fails completeness validation: system identifies the missing or invalid required fields; applicant corrects and resubmits.

---

## UC-1.2: Resume a Saved Application

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | User goal |
| **Primary actor** | Applicant |
| **Supporting actor** | HR Links |

### Stakeholders and interests

- **Applicant:** return to a previously saved application, find it as left (or sensibly updated), and complete submission without redoing work.
- **DTD:** a resumed application is still validated for completeness at submit, identical to a first-sitting submission.

### Preconditions

- Applicant is authenticated.
- A Draft application exists for this applicant in the current cycle.

### Success guarantee

The Draft is reopened with its saved data intact, and the applicant either submits (handing off to UC-1.1's submit path) or saves again as Draft.

### Minimal guarantee

No saved data is lost on reopen. If the application can no longer be submitted, the applicant is told why and the saved data remains viewable.

### Trigger

Applicant chooses to open an existing application, from the app or a notification link.

### Main success scenario

1. Applicant opens their saved application.
2. System retrieves the Draft with all previously entered data: program selections, competencies, ECQs, supporting information, and attached documents.
3. System refreshes personnel fields (Name, Location, Grade, Job Series, Job Title) from HR Links; if any value changed since the last save, it shows the change and asks the applicant to accept before applying. *[UC-1.4]*
4. Applicant edits or completes remaining fields and documents.
5. Applicant submits the application. *(Submit validation and confirmation per UC-1.1, steps 6–7.)*

### Extensions

- **1a.** The application cycle has closed since the Draft was saved: system opens the Draft read-only, tells the applicant the cycle is closed, and blocks submission. Saved data stays viewable.
- **2a.** A previously attached document is missing or unreadable: system flags the affected document and prompts re-attachment before submit.
- **3a.** Personnel data cannot be retrieved from HR Links: system leaves the saved personnel values in place and continues. Fail quietly.
- **3b.** Applicant declines a personnel change shown in step 3: system keeps the saved value and continues.
- **4a.** Applicant chooses Save for Later again: system re-saves as Draft; the use case ends without submission.
- **5a.** Submission fails completeness validation: handled by UC-1.1's submit path.

---

## UC-1.3: Manage Supporting Document

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | Subfunction |
| **Primary actor** | Applicant |
| **Called by** | UC-1.1 (step 4), UC-1.2 (step 4) |

Applies to the three supporting document slots the application defines: Resume, Statement of Interest, Performance Rating. Behavior is the same at each slot.

### Stakeholders and interests

- **Applicant:** place, retrieve, or remove a required supporting document, in an accepted format, so the application can reach a complete state.
- **DTD:** each submitted application carries its required documents, readable, so validation is not spent chasing missing or unopenable files.

### Preconditions

- Applicant is authenticated and working in their own application (Draft or in-progress).

### Success guarantee

The document slot reflects the applicant's last action, one of: a valid file attached, the file retrieved, or the slot empty.

### Minimal guarantee

An invalid or failed operation leaves any previously attached file untouched. No slot is left holding a corrupt or partial file.

### Trigger

Applicant chooses Import, Download, or Delete on a supporting document slot.

### Main success scenario (Attach)

1. Applicant selects Import on the document slot.
2. Applicant chooses a file.
3. System checks the file is PDF or Word.
4. System stores the file and marks the slot attached.

### Alternate flows

- **Download:** applicant selects Download; system returns the stored file. Requires a file present.
- **Delete:** applicant selects Delete; system removes the file and marks the slot empty. Requires a file present.
- **Replace:** applicant selects Import on a slot that already holds a file; the new valid file supersedes the old (delete-then-attach).

### Extensions

- **3a.** File is not PDF or Word: system rejects it, states the accepted formats, and leaves the existing slot contents unchanged.
- **3b.** File exceeds the size limit: system rejects it.
- **4a.** Storage fails: system reports the failure and leaves the slot in its prior state (fail without partial write).

---

## UC-1.4: Populate Personnel Data

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | Subfunction |
| **Primary actor** | Applicant, on whose behalf the system acts |
| **Supporting actor** | HR Links |
| **Called by** | UC-1.1 (step 2, populate into empty), UC-1.2 (step 3, reconcile against saved) |

### Trigger

Proxy. The system pulls personnel data on the applicant's behalf when the application opens; the applicant does not invoke it directly.

### Stakeholders and interests

- **Applicant:** have personnel fields filled accurately from the system of record, without manual entry, and not have a value silently changed under them.
- **DTD:** personnel data on the application matches the HR system of record, so downstream review is not spent correcting identity, grade, or series.

### Personnel fields

Name, Location, Grade, Job Series, Job Title.

### Preconditions

- An application (fresh or Draft) is open for the applicant.

### Success guarantee

The personnel fields hold current HR Links values, or, where a saved value differs and the applicant declined the change, the value the applicant chose. On retrieval failure, the fields are left for manual entry (fresh) or hold their saved values (Draft).

### Minimal guarantee

No personnel value is overwritten without the applicant's acceptance. Retrieval failure never blocks the application.

### Main success scenario

1. System requests the applicant's personnel record from HR Links.
2. HR Links returns Name, Location, Grade, Job Series, Job Title.
3. System populates the personnel fields.

### Extensions

- **2a.** HR Links is unavailable or returns no record: system leaves the fields empty for manual entry, or, if this is a resumed Draft, leaves the saved values in place. Continue without blocking (fail quietly).
- **3a.** A returned value differs from a value already saved on a resumed Draft: system shows the difference and asks the applicant to accept before applying. On accept, the new value replaces the saved one; on decline, the saved value stands. *(This branch is exercised only by the UC-1.2 caller; a fresh application has no saved value to reconcile.)*

---

## UC-1.5: Modify a Submitted Application

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | User goal |
| **Primary actor** | Applicant |

### Stakeholders and interests

- **Applicant:** wants to correct or improve a submitted application while there is still time, without having to work through DTD.
- **DTD:** wants to know when a submitted application has changed, so completeness is confirmed against the current version before the committee sees it.

### Preconditions

- Applicant is authenticated.
- The applicant has a submitted application in the current cycle.
- The cycle has not entered In Review.

### Success guarantee

The application reflects the applicant's changes, the changes are recorded in the change history, and the application is flagged for DTD re-validation.

### Minimal guarantee

No change is partially applied. The application's prior content stands if a change fails.

### Trigger

Applicant opens their submitted application to change it.

### Main success scenario

1. Applicant opens their submitted application.
2. Applicant changes any part of the application: program-option selections and ranking, competencies, ECQs, supporting information, or attached documents. *[UC-1.3, per document]*
3. System records the changes and appends them to the change history.
4. System flags the application for DTD re-validation. *[UC-2.2]*

### Extensions

- **1a.** The cycle has entered In Review: system opens the application read-only and tells the applicant it can no longer be changed.
- **2a.** An attached file is missing or not PDF/Word: system rejects it and prompts for a valid file.
- **3a.** The applicant makes no change and closes the application: no re-validation flag is raised.

---

## UC-2.1: Record Endorsement Decision

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | User goal |
| **Primary actor** | Supervisor (1st line or 2nd line) |
| **Called sub-use case** | UC-5.1 (notify next reviewer) |

### Stakeholders and interests

- **Supervisor (acting):** wants to review the assigned application, record an approve-or-disapprove decision with a written reason, and if needed recommend alternative program options, all in one sitting.
- **Applicant:** wants their endorsement decided by their own supervisory chain, and wants any supervisor recommendation on their program choices recorded and attributed rather than made without a trace.
- **2nd line supervisor:** wants to see how the first-line supervisor decided, and their reasoning, before making an independent decision, so the second review builds on the first rather than repeating it.
- **DTD and committee:** want the application to arrive with both supervisor decisions recorded and any supervisor recommendations visible, so later review starts from solid ground.

### Preconditions

- Application = Submitted, or Submitted with a 1st line disposition already recorded (for the 2nd line reviewer).
- The acting supervisor is the one assigned to this application by organizational hierarchy.
- The acting supervisor has not yet recorded a disposition on this application.

### Success guarantee

The acting supervisor's decision and statement are recorded on the application; any program-option recommendation is recorded to the change history; the application advances to the next reviewer in sequence.

### Minimal guarantee

No decision is recorded without a statement. A failed or abandoned recommendation leaves the applicant's program choices and the change history unchanged.

### Trigger

Supervisor opens an application assigned to them for review (from a notification link or their queue).

### Main success scenario

1. Supervisor opens the assigned application and reviews it, including attached documents. *(2nd line: also sees the 1st line decision and statement.)*
2. Supervisor records a decision: approve or disapprove.
3. Supervisor enters a disposition statement.
4. System records the decision and statement against the application, attributed to the acting supervisor.
5. System advances the application to the next reviewer (1st line → 2nd line → DTD validation) and notifies them. *[UC-5.1]*

### Extensions

- **1a.** Supervisor recommends one or more alternative program options: system records the recommendation to the change history (what was recommended, by whom, when) without altering the applicant's own selections. The recommendation informs DTD at placement.
- **2a.** Supervisor disapproves: the decision records as disapprove; routing is unchanged (step 5 proceeds). Both supervisors review regardless of a prior disapproval; the application is not diverted or held.
- **4a.** Supervisor attempts to record a decision without a statement: system blocks the record and prompts for the statement (statement required on both approve and disapprove).
- **5a.** The acting supervisor is the 2nd line (final supervisor in sequence): the next reviewer is DTD validation (UC-2.2), not another supervisor.

---

## UC-2.2: Validate Application

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | User goal |
| **Primary actor** | DTD Personnel |
| **Calls** | UC-1.3 (attach missing documents); UC-5.1 (notify committee, on Complete) |

### Stakeholders and interests

- **DTD Personnel:** wants to confirm each application has everything required before it reaches the committee, complete any that fall short, and keep a clear list of which ones still need attention.
- **Applicant:** wants to be told promptly if something is missing, while there is still time to supply it, rather than being passed along incomplete or stalled without notice.
- **Committee:** wants only complete applications to reach them, so their review and ranking is not spent on applications missing documents or fields.

### Preconditions

- Both supervisors have recorded their decisions (the application has passed through the 1st and 2nd line reviewers).
- DTD has not yet recorded a Complete determination on this application, or the applicant has modified it since the last determination (UC-1.5).

### Success guarantee

The application is marked Complete, the determination is recorded and appended to the change history, and the application advances to the committee.

### Minimal guarantee

The application's completeness state is recorded, attributed to DTD, and appended to the change history. No incomplete application advances to the committee.

### Invariant

An application must be Complete to advance past this stage. Incomplete never advances.

### Trigger

DTD Personnel opens an application that has cleared both supervisor reviews (from a notification link or their queue).

### Main success scenario

1. DTD Personnel opens the application and checks its components against what a complete application requires: required fields present, and the required documents (resume, statement of interest, performance rating) attached and readable.
2. DTD Personnel marks the application Complete.
3. System records the Complete determination, attributed to DTD, and appends it to the change history (what was determined, by whom, when).
4. System advances the application to the committee and notifies them. *[UC-5.1]*

### Extensions

- **1a.** One or more required components are missing, and DTD completes them directly: DTD attaches missing documents *[UC-1.3]* or supplies missing field values, working from material the applicant provided off-system. Each change appends to the change history. DTD then marks the application Complete (resume at step 2).
- **1b.** Components are missing and cannot be completed yet (applicant has not supplied them): DTD Personnel marks the application Incomplete. The system records the Incomplete determination, appends it to the change history, and holds the application (it does not advance). The application appears in DTD's follow-up list until it becomes Complete.
- **2a.** An application previously marked Incomplete is revisited after the applicant supplies what was missing: DTD completes it (per 1a) and marks it Complete; it then advances.
- **2b.** The applicant modified the application after a Complete determination (UC-1.5): the application returns to DTD for re-validation. DTD re-checks it and records a fresh determination; the prior determination stands in the change history.

---

## UC-3.1: Review and Rank Applicants by Program

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | User goal |
| **Primary actor** | Committee (acting through a designated recorder) |

### Stakeholders and interests

- **Committee:** wants to see everything about each applicant to a program, score them against the program's defined criteria, and have those scores produce a ranking without hand-ordering the pool.
- **Applicant:** wants to be evaluated on the committee's defined criteria, consistently with everyone else who applied to the same program.
- **DTD:** wants a completed, scored ranking for each program, so final selection and placement (UC-3.2) starts from a clear competitive order.

### Preconditions

- The cycle has entered In Review; applications are locked against applicant modification.
- One or more applications have reached the committee (Complete per UC-2.2, both supervisor decisions recorded).
- The program's committee rating sheet exists and is published: criteria, point ranges for committee-entered criteria, and predefined-point values.

### Success guarantee

Every applicant to the program has a completed score against the rating sheet; the system has summed each applicant's points and produced a ranking of the program's pool; the ranking is recorded on each application, attributed to the committee.

### Minimal guarantee

No partial or out-of-range score is recorded as final. Scores entered in one session are retained for the next; an abandoned session leaves prior recorded scores intact.

### Trigger

The committee (via its recorder) opens a program to evaluate its applicant pool.

### Main success scenario

1. Committee (via recorder) opens a program; the system presents the applicants who selected that program or any of its options, showing each applicant's scoring status (scored / not yet scored). An applicant who selected more than one of the program's options appears once.
2. For an applicant not yet scored, the committee reviews the full application, including attached documents, the supervisor decisions and statements, and the DTD completeness determination.
3. The system presents the program's rating sheet: committee-entered criteria (each with its allowed point range) and predefined criteria (points already set).
4. The committee enters points for each committee-entered criterion, within range; predefined criteria carry their set points.
5. The system sums the applicant's points into a final score and marks the applicant scored.
6. The committee scores remaining applicants across as many sessions as needed; the system retains scores between sessions.
7. When every applicant in the program's pool is scored, the system ranks the pool by final score and records each applicant's rank on their application, attributed to the committee.

### Extensions

- **4a.** A committee-entered point value is outside the criterion's allowed range: the system rejects it and prompts for a value within range (not recorded until valid).
- **5a.** Two or more applicants have equal final scores: the system records equal scores and reflects the tie in the ranking; it does not break ties. DTD resolves tied positions during placement (UC-3.2).
- **6a.** The committee revises a previously entered score before the pool is complete: the system updates the score and the applicant's sum.
- **7a.** An applicant appears in more than one program's pool: scored and ranked independently in each; this use case does not reconcile positions across programs (DTD resolves at UC-3.2).

---

## UC-3.2: Record Final Selection and Placement

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | User goal |
| **Primary actor** | DTD Personnel |

### Stakeholders and interests

- **DTD Personnel:** wants to place applicants into programs using the committee rankings as guidance, keep full control over who goes where, and be able to move an applicant to a better-fitting program without fighting the tool.

### Preconditions

- At least one program's pool has been scored and ranked by the committee (UC-3.1). DTD may begin placement as pools become ranked; not every program need be ranked first.

### Success guarantee

DTD has recorded placements for the selected applicants, each placed in exactly one program option; the cohort is finalized; every applicant not placed stands as not-selected. The finalized cohort is ready for notification (UC-3.3).

### Minimal guarantee

No applicant is placed in more than one program option at any time. No applicant is placed in a program they did not apply to. An unfinalized placement session leaves recorded placements revisable and triggers no notification.

### Invariant

At most one active placement per applicant, at all times, including mid-revision.

### Trigger

DTD Personnel opens a program to place its applicants.

### Main success scenario

1. DTD opens a program; the system presents that program's ranked applicants with, for each: the committee ranking, the applicant's ranked program-option preferences, any supervisor recommendations, and whether they are already placed elsewhere.
2. DTD selects an applicant and places them into a program option within this program.
3. The system records the placement, attributed to DTD.
4. DTD places further applicants in this program and moves across programs as needed, working from the rankings as guidance.
5. DTD finalizes the cohort.
6. The system locks all placements, marks every unplaced applicant not-selected, and hands off to notification. *[UC-3.3]*

### Extensions

- **2a.** The applicant DTD selects is already placed in another program option: the system shows the existing placement; DTD may place them here anyway, which transfers the placement (the prior placement is removed automatically). The applicant remains in exactly one program option.
- **3a.** DTD removes a placement without reassigning: the applicant returns to unplaced and, absent any later placement, will stand as not-selected at finalize.
- **5a.** DTD finalizes with applicants still unplaced: unplaced applicants are not-selected. Finalize does not require everyone to be placed.

---

## UC-3.3: Issue Cohort Disposition Notifications

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | User goal |
| **Primary actor** | DTD Personnel |
| **Trigger source** | Cohort finalization (UC-3.2 step 6) |

### Stakeholders and interests

- **DTD Personnel:** wants to notify applicants of their outcomes on their own terms, all at once or a chosen few, with a clear record of who has already been told and the ability to send again when needed.
- **Applicant:** wants to learn their outcome, selected and where, or not selected, clearly, once the decisions are settled.

### Preconditions

- The cohort is finalized (UC-3.2): every applicant is placed in exactly one program or not-selected.
- No applicant has been sent a disposition result earlier in the process (dispositions were withheld until finalization).

### Success guarantee

Every applicant in the cohort has been sent their disposition notification, via any combination of full-cohort and selective sends, each send recorded in the change history, and DTD can see who has been notified and which sends failed.

### Minimal guarantee

Every send is recorded per applicant and written to the change history. No notification failure is silently dropped; failed recipients remain visibly not-notified.

### Trigger

DTD finalizes the cohort (UC-3.2), settling every applicant's disposition.

### Main success scenario

1. On finalization, the system makes the settled cohort available for notification: each applicant with their resolved disposition (selected + program, or not-selected) and a not-yet-notified status.
2. DTD selects recipients from the cohort list, choosing individually or selecting all.
3. DTD sends the disposition notification to the selected applicants by email, content per DTD's defined messaging.
4. The system sends to each selected applicant, records the send outcome per applicant (sent / failed), marks those sent as notified, and appends each send to the change history.
5. DTD repeats steps 2–4 as needed until every applicant has been notified.

### Extensions

- **3a.** DTD selects an applicant already marked notified: the system shows they were already sent (visual cue) and warns, but allows the send if DTD proceeds (a deliberate resend, for a corrected or re-delivered message).
- **4a.** An applicant's notification fails to send (bad address, delivery error): the system records the failure, continues with the rest of the send, and leaves that applicant not-notified. The failure is visible to DTD, who can include them in a later send.

---

## UC-4.1: Manage Program Option

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | User goal |
| **Primary actor** | DTD Personnel (administrator) |

### Stakeholders and interests

- **DTD Personnel:** wants to maintain the catalog of programs and their options, with the descriptive detail applicants and committees rely on, so each cycle runs against accurate offerings.
- **Applicant (indirect):** wants to choose from options that are current and correctly described.
- **Committee (indirect):** wants the option each pool is scored against to be well-defined.

### Preconditions

- DTD Personnel is authenticated with administrator rights.

### Success guarantee

The program-option catalog reflects DTD's change, a program option added, edited, or removed, with its attributes recorded.

### Minimal guarantee

No partial or invalid program-option record is saved. A failed edit leaves the prior record intact.

### Trigger

DTD Personnel opens program-option management to change the catalog.

### Main success scenario (add)

1. DTD chooses to add a program option under a program (NEXT, MDP, or HPP).
2. DTD enters the option's attributes: Course/Program Name, Description, Vendor, Grade Level, Course Length, Competency, Requirements, Website.
3. The system records the program option under its program.

### Alternate flows

- **Edit:** DTD opens an existing program option and changes its attributes; the system records the update.
- **Remove:** DTD removes a program option; the system removes it from the catalog.

### Extensions

- **2a.** A required attribute is missing: the system blocks the save and prompts for it.

---

## UC-4.2: Manage Application Cycle

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | User goal |
| **Primary actor** | DTD Personnel (administrator) |

### Stakeholders and interests

- **DTD Personnel:** wants to set up an application cycle with its key dates and control when it moves from scheduled to open to closed, so intake happens in a defined window and applicants know when to expect a decision.
- **Applicant (indirect):** wants a clear application window and a stated date by which to expect a decision.

### Preconditions

- DTD Personnel is authenticated with administrator rights.

### Success guarantee

The cycle exists with its three dates recorded and its state set (Scheduled, Open, Closed, or In Review); at most one cycle is Open at any time; the system enforces the current state on applicant submission and resume.

### Minimal guarantee

The cycle's state and dates are recorded and attributed. The cycle is unambiguously in one of the four states.

### Trigger

DTD Personnel opens cycle management to create or update the application cycle.

### Cycle states

- **Scheduled** — the cycle is set up with its dates but is not yet accepting applications.
- **Open** — the cycle is accepting applicant submissions and resumes.
- **Closed** — the cycle is no longer accepting submissions or resume-to-submit. Applicants may still modify applications they have already submitted.
- **In Review** — applications are locked against applicant modification; committee evaluation is under way.

### Cycle dates

- **Open date** — when applications are intended to open.
- **Close date** — when applications are intended to close.
- **Expected decision date** — when a disposition is expected; shown to applicants.

### Main success scenario (set up and run a cycle)

1. DTD creates the cycle and enters its three dates. The cycle is Scheduled.
2. When intake should begin, DTD sets the cycle to Open.
3. The system records the state change; the cycle now accepts submissions (UC-1.1) and resumes (UC-1.2).
4. When intake should end, DTD sets the cycle to Closed.
5. The system records the state change; the cycle stops accepting new submissions and resume-to-submit. Applicants may still modify applications they have already submitted (UC-1.5), and review continues.
6. When committee evaluation should begin, DTD sets the cycle to In Review.
7. The system records the state change and locks every application against further applicant modification; committee scoring may begin (UC-3.1).

### Extensions

- **1a.** Dates are inconsistent (close date before open date, or expected-decision date before close date): the system blocks the save and prompts DTD to correct.
- **2a.** DTD sets a cycle to Open while another cycle is already Open: the system blocks the transition. Intake cannot overlap; the prior cycle must be Closed first. *(A Closed cycle with pending decisions does not block a new cycle from opening — only an Open one does.)*
- **4a.** DTD closes a cycle with applications still in Draft: those Drafts can no longer be submitted (per UC-1.2 extension 1a). No new rule.

---

## UC-4.3: Manage Committee Rating Sheet

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | User goal |
| **Primary actor** | DTD Personnel (administrator) |

### Stakeholders and interests

- **DTD Personnel:** wants to build each program's scoring rubric, revise it freely until it's right, and release a final version for the committee, with a record of what each version contained.
- **Committee (indirect):** wants to score against a stable, released rubric that doesn't shift mid-evaluation.

### Preconditions

- DTD Personnel is authenticated with administrator rights.
- The program the sheet is for exists, within a cycle (UC-4.2).

### Success guarantee

The program has a Published rating sheet version, frozen, and the committee can score its pool against it. All prior versions are retained and inspectable.

### Minimal guarantee

Every saved version is recorded immutably and attributed. No published sheet changes; no unpublished draft is scored against.

### Trigger

DTD opens rating-sheet management for a program in a cycle.

### Sheet lifecycle

- **Draft** — DTD is building/revising. Each save is a new immutable version, superseding the prior. Revision is unlimited.
- **Published** — DTD has released a chosen version. Frozen: no new versions. The committee can now score the pool against it.

### Criteria structure (per sheet version)

- A set of criteria, each with a name and a type.
- **Committee-entered:** carries a point range (min–max the committee may enter).
- **Predefined:** carries a fixed point value.
- Criteria sum to a total; the total is emergent (no imposed maximum).

### Main success scenario (build and publish)

1. DTD opens the rating sheet for a program and adds criteria, each with a name, a type, and either a point range (committee-entered) or a fixed value (predefined).
2. DTD saves. The system records this as an immutable version.
3. DTD revises as needed; each save creates a new version that supersedes the prior. DTD can view prior versions at any time.
4. DTD publishes the current version.
5. The system freezes the sheet at that version and makes it available for the committee to score the pool (UC-3.1).

### Extensions

- **1a.** A committee-entered criterion's range is invalid (min > max, or non-numeric): the system blocks the save and prompts for correction.
- **2a.** DTD attempts to save a sheet with no criteria: the system blocks the save. A sheet must contain at least one criterion to be saved as a version.
- **4a.** DTD publishes, then catches an error before any scoring has begun: DTD unpublishes (allowed only while zero scores exist for the pool), returning the sheet to Draft; DTD revises (new version) and republishes.
- **4b.** DTD attempts to unpublish after scoring has begun (one or more scores exist): the system blocks it. The published version is locked; the sheet cannot change once evaluation is underway.
- **5a.** The committee attempts to score a program whose sheet is not Published: the system blocks scoring until the sheet is published.

---

## UC-5.1: Notify Stakeholder of Pending Action

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | Subfunction |
| **Primary actor** | The notified stakeholder (applicant, supervisor, DTD, committee), on whose behalf the system acts |
| **Trigger** | Proxy — invoked by another use case when a workflow event requires a stakeholder to act or be informed |
| **Called by** | UC-1.1 (submission confirmation), UC-2.1 (notify next reviewer), UC-2.2 (notify committee on Complete) |

### Interest

The stakeholder who needs to act, or needs to know an action occurred, is told promptly through a recorded notification, so the workflow moves without someone manually chasing the next person.

### Preconditions

- A calling use case has reached a point defined as notifiable (an action is now pending for a stakeholder, or a step the stakeholder cares about has completed).
- The recipient is identified by the calling context (the assigned supervisor, DTD, the committee, or the applicant).

### Success guarantee

The notification is sent to the intended recipient by email and recorded (recipient, trigger, time).

### Minimal guarantee

A send is attempted and its outcome recorded. A failure is logged, not silently dropped.

### Main success scenario

1. A calling use case signals a notifiable event, naming the recipient and the event.
2. The system composes the notification for that event and recipient, including a link to the relevant application or task.
3. The system sends the notification by email and records it (recipient, trigger, time).

### Extensions

- **3a.** The send fails (bad address, delivery error): the system records the failure.

---

## UC-5.2: Send Reminder for Overdue Action

| | |
|---|---|
| **Scope** | LDP Application |
| **Level** | Subfunction |
| **Primary actor** | The responsible stakeholder (supervisor, committee, DTD, applicant), on whose behalf the system acts |
| **Trigger** | Time — a defined interval elapses with no action recorded on a pending step |

### Interest

The stakeholder responsible for a pending step is reminded if it stalls, so a forgotten action does not silently hold up an applicant's progress.

### Preconditions

- A step is in a pending state awaiting a specific stakeholder's action (an approval assigned, a DTD entry due, a consult response awaited).
- No action has been recorded on that step.

### Success guarantee

When the step's defined interval elapses with no action, a reminder is sent to the responsible stakeholder and recorded.

### Minimal guarantee

The reminder send is attempted and its outcome recorded. Once the action is taken, no reminder for that step is sent.

### Trigger table

| Reminder | Interval | Recipient | Phase |
|---|---|---|---|
| 1st line supervisor reminder | 5 days, no action on the approval | 1st line supervisor | I |
| 2nd line supervisor reminder | 5 days, no action on the approval | 2nd line supervisor | I |
| Committee endorsement | 5 days, no action on the approval | Committee | I |
| Selection Flag | 3 days, no data entry for the selection | DTD | I |
| Detail Entry | 3 days, no data entry for the detail options | DTD | II |
| Consult Date Request | 5 days, no action on the consult date request | Applicant | II |

### Main success scenario

1. A step enters a pending state; the system notes the responsible stakeholder and starts the step's interval (3 or 5 days).
2. The interval elapses with no action recorded on the step.
3. The system sends the reminder to the responsible stakeholder by email, with links to the relevant data-entry screen and the applicant's application.
4. The system records the reminder (recipient, step, time).

### Extensions

- **2a.** The action is taken before the interval elapses: no reminder is sent; the clock is cleared.
- **3a.** The send fails: the system records the failure.
- **3b.** The interval elapses again with the action still not taken: repeat behavior to be confirmed (fire once, or re-fire each interval until acted on).

