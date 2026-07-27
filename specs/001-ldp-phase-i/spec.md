# Feature Specification: LDP Application — Phase I

**Feature Branch**: `001-ldp-phase-i`

**Created**: 2026-07-25

**Status**: Draft — blocking clarifications Q1–Q3 resolved (OI-1, OI-2, OI-3); OI-2 carries a
Constitution follow-up (see Open Items). Non-blocking items OI-4–OI-9 and dependencies D-1/D-2
remain for review. **FR-012a is marked Proposed** (Constitution I) — pending DTD confirmation
before transcription.

**Input**: User description: "I have created initial requirements document that can be found in the docs/ folder. Please review these documents and create specs. Flag any inconsistencies for me to review and clarify."

**Source anchors** (per Constitution Principle I): `docs/LDP_Functional_Requirements_Phase_I.md` (RQ001–RQ119), `docs/LDP_Use_Cases.md` (UC-1.1–UC-5.2), `docs/LDP_Logical_Data_Model.md`.

> **Scope note.** This is a single Phase I specification covering the full value stream (Submit → Endorse → Validate → Score → Place → Notify) plus administration (programs, cycles, rating sheets, criterion catalog). It is large by design because Phase I is one coherent release. User stories below are prioritized so the build can be sliced; they are not independent products, because the value stream is sequential and every stage depends on an open cycle and configured programs.

## Clarifications

### Session 2026-07-25

- Q: Endorsement routing when the applicant has no second-line supervisor (OI-6)? → A: Hold the
  application after the first-line decision until DTD designates an alternate second-line reviewer,
  then route to that reviewer (Option B).
- Q: Is the "performance rating" attached document distinct from the numeric
  `LatestPerformanceRating` field (OI-8)? → A: Distinct — keep both the attached appraisal document
  and the separate numeric latest rating (Option A).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Applicant submits an application (Priority: P1)

An authenticated NCUA employee opens the program, has their personnel details filled in
automatically, selects and ranks up to three program options, records their competencies and
ECQs, attaches their supporting documents, and submits — receiving confirmation. They can save
a partial application and resume it later without losing work.

**Why this priority**: This is the entry point of the entire value stream. Without submission
there is nothing to endorse, validate, score, or place. It is the highest-volume interaction
(every applicant) and the primary replacement for today's email-based process.

**Independent Test**: With an Open cycle and configured program options, a signed-in employee
can complete and submit an application by hand, save a draft, reopen it, and see a submission
confirmation. Anchors: UC-1.1, UC-1.2, UC-1.3, UC-1.4.

**Acceptance Scenarios**:

1. **Given** an Open cycle and no existing application, **When** the applicant starts a new
   application, **Then** personnel fields (Name, Location, Grade, Job Series, Job Title) are
   populated from HR Links, or left blank for manual entry if HR Links returns nothing.
2. **Given** a started application, **When** the applicant selects program options, **Then** they
   may select and rank between one and three options from highest to lowest preference, and may
   view a program option's full details without leaving the application.
3. **Given** a completed application with all required fields and the three required documents,
   **When** the applicant submits, **Then** the system validates completeness as a whole (not
   per-section), records the application as Submitted, and confirms success.
4. **Given** an application missing required items, **When** the applicant submits, **Then** the
   system identifies what is missing or invalid and does not record a submission.
5. **Given** an in-progress application, **When** the applicant chooses Save for Later, **Then**
   the application is saved as Draft and can be resumed later with all data intact.
6. **Given** a Draft, **When** the applicant resumes it and a personnel value has changed in HR
   Links since the last save, **Then** the system shows the change and asks the applicant to
   accept before applying it.
7. **Given** a Draft, **When** the cycle has closed since it was saved, **Then** the Draft opens
   read-only, the applicant is told the cycle is closed, and submission is blocked.
8. **Given** an applicant who already submitted in the current cycle, **When** they start again,
   **Then** the system prevents a second application in the same cycle.

---

### User Story 2 - Supervisors endorse (Priority: P1)

A submitted application routes to the applicant's first-line supervisor, then to the second-line
supervisor, each recording an approve/disapprove decision with a required written statement, and
optionally recommending alternative program options — without changing the applicant's own
selections. The application advances regardless of approval or disapproval.

**Why this priority**: Endorsement is the first review gate and establishes the supervisory
record the committee and DTD rely on. Anchors: UC-2.1; RQ015–RQ025.

**Independent Test**: A submitted application appears in the assigned first-line supervisor's
queue in view-only mode; the supervisor records a decision with a statement; it then routes to
the second-line supervisor who can see the first decision; after both, it routes to DTD.

**Acceptance Scenarios**:

1. **Given** a submitted application, **When** it is routed, **Then** it goes to the applicant's
   first-line supervisor, assigned by organizational hierarchy, in view-only mode.
2. **Given** a supervisor reviewing an application, **When** they record a decision, **Then** the
   system requires a disposition statement on both approve and disapprove before recording.
3. **Given** the first-line decision is recorded, **When** routing continues, **Then** the
   application advances to the second-line supervisor and shows them the first-line decision and
   statement — regardless of whether the first-line supervisor approved or disapproved.
4. **Given** a supervisor recommends alternative program options, **When** recorded, **Then** the
   recommendation is captured (options, who, when) without altering the applicant's selections,
   and informs DTD at placement only.
5. **Given** both supervisors have decided, **When** routing continues, **Then** the application
   advances to DTD validation.

---

### User Story 3 - DTD validates completeness (Priority: P1)

After both supervisor decisions, DTD reviews the application, marks it Complete or Incomplete,
may edit it (attach documents, supply values) to bring it to complete, and advances only Complete
applications to the committee. Incomplete applications appear in a follow-up list and are held.

**Why this priority**: The completeness gate protects committee time and enforces the invariant
that no incomplete application is scored. Anchors: UC-2.2; RQ026–RQ032.

**Independent Test**: An application that cleared both supervisors appears to DTD; DTD marks it
Complete and it advances; DTD marks another Incomplete and it is held and listed for follow-up.

**Acceptance Scenarios**:

1. **Given** an application with both supervisor decisions, **When** DTD opens it, **Then** DTD
   can mark it Complete or Incomplete.
2. **Given** DTD marks an application Complete, **When** recorded, **Then** the determination is
   written to the change history (what, who, when) and the application advances to the committee.
3. **Given** an application missing components, **When** DTD supplies them and marks it Complete,
   **Then** each edit is recorded in the change history and the application advances.
4. **Given** an application marked Incomplete, **When** DTD saves, **Then** it does not advance
   and appears in DTD's follow-up list until it becomes Complete.

---

### User Story 4 - Committee scores and ranks by program (Priority: P1)

For each program, the committee sees the applicants who selected that program or any of its
options (once each), scores each against the program's published rating sheet using the fixed
0/1/3/5 anchor scale, and — once every applicant in the pool is scored — the system sums scores,
computes percent of possible, and ranks the pool.

**Why this priority**: Scoring and ranking produce the competitive order that drives selection.
Anchors: UC-3.1; RQ033–RQ044, RQ119.

**Independent Test**: With a published rating sheet for a program and Complete applications in
its pool, the committee records anchor-value scores per criterion; the system rejects non-anchor
values, retains scores across sessions, sums totals, and ranks the pool once fully scored.

**Acceptance Scenarios**:

1. **Given** a program with a published rating sheet, **When** the committee opens it, **Then**
   the system presents applicants who selected that program or any of its options (each once),
   with scoring status, alongside each full application, supervisor decisions and statements, and
   the DTD determination.
2. **Given** an applicant being scored, **When** the committee enters a criterion score, **Then**
   the system accepts only 0, 1, 3, or 5 and rejects any other value.
3. **Given** scores entered across multiple sessions, **When** the committee returns, **Then**
   prior scores are retained.
4. **Given** every applicant in a program pool is scored, **When** the pool completes, **Then**
   the system sums each applicant's points into a final score, computes percent of possible as
   final score ÷ (5 × number of criteria on that applicant's sheet), and ranks the pool, recording
   each rank on the application. Ties are reflected, not broken.
5. **Given** an applicant selected options in more than one program, **When** scoring runs,
   **Then** they are scored and ranked independently in each program's pool.

---

### User Story 5 - DTD selects and places participants (Priority: P1)

DTD reviews each program's ranked pool with percent of possible, the applicant's ranked
preferences, and any supervisor recommendations, and places applicants into exactly one program
option each. DTD finalizes the cohort, locking placements and marking unplaced applicants
not-selected.

**Why this priority**: Placement is the decision the whole process exists to produce. Anchors:
UC-3.2; RQ045–RQ054.

**Independent Test**: DTD places a ranked applicant into a program option; placing an already-
placed applicant transfers them (prior placement removed); finalize locks placements and marks
everyone unplaced as not-selected.

**Acceptance Scenarios**:

1. **Given** a ranked program pool, **When** DTD opens it, **Then** each applicant shows committee
   rank, percent of possible, ranked program-option preferences, supervisor recommendations, and
   placement status.
2. **Given** DTD places an applicant into a program option, **When** the applicant is already
   placed elsewhere, **Then** the system indicates the existing placement and, if DTD proceeds,
   transfers it so the applicant holds exactly one placement.
3. **Given** placements in progress, **When** DTD removes a placement, **Then** the applicant
   returns to unplaced.
4. **Given** DTD finalizes the cohort, **When** finalized, **Then** all placements lock, every
   unplaced applicant is marked not-selected, and the cohort is ready for notification.
5. **Given** an unfinalized cohort, **When** DTD revises placements, **Then** revisions are
   allowed and no notifications are triggered.

---

### User Story 6 - Administer application cycles (Priority: P1)

DTD creates a cycle with open, close, and expected-decision dates, and moves it through
Scheduled → Open → Closed → In Review. The state governs applicant submission, resume, post-
submission modification, and committee scoring. At most one cycle is Open at a time.

**Why this priority**: No applicant can act without an Open cycle, and cycle state is the master
switch for the whole workflow. Anchors: UC-4.2; RQ075–RQ081.

**Independent Test**: DTD creates a cycle, is blocked from inconsistent dates, opens it (blocked
if another is Open), closes it, and sets In Review; each transition changes what applicants and
the committee may do.

**Acceptance Scenarios**:

1. **Given** cycle creation, **When** DTD enters dates, **Then** the system rejects a close date
   before the open date or an expected-decision date before the close date.
2. **Given** a Scheduled cycle, **When** DTD sets it Open while another cycle is Open, **Then**
   the transition is blocked.
3. **Given** an Open cycle, **When** DTD sets it Closed, **Then** new submissions and resume-to-
   submit stop, but applicants may still modify already-submitted applications.
4. **Given** a Closed cycle, **When** DTD sets it In Review, **Then** all applications lock
   against applicant modification and committee scoring may begin.
5. **Given** any cycle, **When** an applicant views the landing page, **Then** the expected
   decision date is shown.

---

### User Story 7 - Administer program options (Priority: P2)

DTD maintains the catalog of programs (NEXT, MDP, HPP) and their selectable options, each with
descriptive attributes applicants and committees rely on.

**Why this priority**: Program options must exist before applicants can select them, but the
catalog is low-volume, low-churn admin. Anchors: UC-4.1; RQ072–RQ074.

**Independent Test**: DTD adds a program option under a program with all required attributes,
edits it, and removes it; a missing required attribute blocks the save.

**Acceptance Scenarios**:

1. **Given** program-option management, **When** DTD adds an option under a program, **Then** the
   system records name, description, vendor, grade level, course length, competency, requirements,
   and website, organized under the parent program.
2. **Given** an option being saved, **When** a required attribute is missing, **Then** the save is
   blocked with a prompt.
3. **Given** an existing option, **When** DTD edits or removes it, **Then** the catalog reflects
   the change.

---

### User Story 8 - Administer rating criterion catalog (Priority: P2)

DTD maintains one shared catalog of scoring criteria, each with a name, description, four fixed
anchors (0/1/3/5) with optional examples, and an availability window. Draft criteria are
editable; Published criteria are frozen (a change means a new criterion).

**Why this priority**: The catalog is the source rating sheets draw from; it must exist before
sheets can be built. Anchors: UC-4.4; RQ109–RQ118.

**Independent Test**: DTD defines a Draft criterion, edits it, publishes it (blocked unless all
four anchors are present), and retires it with an end date; a Published criterion cannot be
edited.

**Acceptance Scenarios**:

1. **Given** the catalog, **When** DTD defines a criterion, **Then** it records a name,
   description, and the four fixed anchors (0/1/3/5), each with descriptor text and an optional
   example, and starts as Draft.
2. **Given** a Draft criterion, **When** DTD publishes it, **Then** the system blocks publishing
   if any of the four anchors is missing; otherwise it freezes the text and records a start date.
3. **Given** a Published criterion, **When** DTD attempts to edit it, **Then** editing is not
   allowed; a correction is made by creating a new criterion.
4. **Given** a criterion, **When** DTD sets an end date, **Then** it is no longer offered for new
   selection from that date; a null end date means still available.

---

### User Story 9 - Administer committee rating sheets (Priority: P2)

DTD builds a per-program, per-cycle rating sheet by selecting criteria from the catalog, saving
immutable versions, and publishing a chosen version. Publishing freezes the sheet; unpublishing
is allowed only before any scores exist.

**Why this priority**: A published rating sheet is required before the committee can score
(gates User Story 4). Anchors: UC-4.3; RQ082–RQ092.

**Independent Test**: DTD selects catalog criteria onto a sheet, saves versions, publishes;
scoring is blocked until published; unpublish is blocked once scores exist; a sheet with a
passed-end-date criterion is blocked from publishing.

**Acceptance Scenarios**:

1. **Given** a rating sheet for a program in a cycle, **When** DTD selects criteria, **Then** only
   Published, in-window catalog criteria can be selected.
2. **Given** a sheet with no selected criteria, **When** DTD saves, **Then** the save is blocked.
3. **Given** a saved sheet, **When** DTD saves a change, **Then** a new immutable version is
   created superseding the prior, and prior versions remain viewable.
4. **Given** a sheet carrying a criterion whose end date has passed, **When** DTD attempts to
   publish, **Then** the system flags the criterion and blocks publishing.
5. **Given** a published sheet, **When** DTD attempts to unpublish after any score exists, **Then**
   the system blocks it; before any score exists, unpublish is allowed.

---

### User Story 10 - Notify and remind stakeholders (Priority: P2)

The system emails the responsible stakeholder when an action becomes pending or an application
advances, includes a link to the relevant application or task, sends reminders after defined
intervals when a step stalls, and stops reminders once the action is recorded.

**Why this priority**: Notifications keep the workflow moving without manual chasing, but the
value stream can be demonstrated end-to-end without them. Anchors: UC-5.1, UC-5.2; RQ055–RQ062.

**Independent Test**: When an application advances, the next reviewer receives an email with a
link; if a first-line supervisor takes no action for five days, a reminder is sent; once they
act, reminders stop.

**Acceptance Scenarios**:

1. **Given** an action becomes pending for a stakeholder, **When** the event fires, **Then** the
   system emails that stakeholder with a link to the relevant application or task and records the
   send outcome.
2. **Given** a pending first-line or second-line approval, **When** five days pass with no action,
   **Then** a reminder is sent to that supervisor.
3. **Given** a pending committee action, **When** five days pass with no action, **Then** a
   reminder is sent to the committee.
4. **Given** a pending DTD selection entry, **When** three days pass with no action, **Then** a
   reminder is sent to DTD.
5. **Given** a reminder is due to fire, **When** the responsible action has been recorded, **Then**
   no reminder is sent for that step.

---

### User Story 11 - Issue cohort disposition notifications (Priority: P2)

After the cohort is finalized, DTD notifies applicants of their outcomes — selected (with program
option) or not selected — individually or all at once, with a clear record of who has been
notified and which sends failed, and the ability to resend after a warning. No disposition is
revealed to any applicant before finalization.

**Why this priority**: This closes the loop for applicants but occurs once per cycle at the end.
Anchors: UC-3.3; RQ063–RQ071.

**Independent Test**: With a finalized cohort, DTD selects recipients (some or all), sends
dispositions, sees per-applicant sent/failed outcomes and notified status, and can resend to an
already-notified applicant after a warning.

**Acceptance Scenarios**:

1. **Given** results before finalization, **When** anytime prior, **Then** no disposition is
   disclosed to applicants.
2. **Given** a finalized cohort, **When** DTD selects recipients, **Then** DTD may choose
   applicants individually or select all in the cohort.
3. **Given** a send, **When** it completes, **Then** each applicant's outcome (sent/failed) is
   recorded, successes are marked notified, and each send is written to the change history.
4. **Given** a failed send, **When** reported, **Then** the applicant remains visibly not-notified
   and can be included in a later send.
5. **Given** an already-notified applicant, **When** DTD sends again, **Then** the system warns
   first and proceeds only if DTD confirms.

---

### User Story 12 - Applicant modifies a submitted application (Priority: P2)

An applicant may change any part of a submitted application until the cycle enters In Review. A
modification is recorded in the change history and flags the application for DTD re-validation;
supervisors are not re-engaged.

**Why this priority**: A useful correction path, but secondary to the core submit/review flow.
Anchors: UC-1.5; RQ096–RQ100.

**Independent Test**: After submission and before In Review, the applicant edits their
application; the change is recorded and the application is flagged for DTD re-validation; after
In Review, the application opens read-only.

**Acceptance Scenarios**:

1. **Given** a submitted application in a cycle not yet In Review, **When** the applicant changes
   it, **Then** the changes are recorded in the change history and the application is flagged for
   DTD re-validation.
2. **Given** the cycle has entered In Review, **When** the applicant opens the application, **Then**
   it is read-only and cannot be changed.
3. **Given** the applicant makes no change, **When** they close the application, **Then** no
   re-validation flag is raised.

---

### User Story 13 - Public landing and authenticated navigation (Priority: P2)

A public landing page presents program information and the current cycle's state and dates, with
content appropriate to each state and supporting applicant information. Committee members and DTD
sign in and are directed to their respective workspaces. The application presents as freely
navigable sections.

**Why this priority**: The front door and workspace routing frame the experience but depend on
the underlying flows existing. Anchors: RQ101–RQ108.

**Independent Test**: An unauthenticated visitor sees the landing page with the current cycle
state and dates and supporting information; a committee member and a DTD admin sign in and reach
their respective workspaces; an applicant can move between application sections in any order.

**Acceptance Scenarios**:

1. **Given** any cycle state, **When** a visitor loads the landing page, **Then** it presents
   program information, the current cycle state and dates, and supporting information (eligibility
   guidance, FAQ, contact, prior-cohort outcomes) appropriate to the state.
2. **Given** a committee member or DTD administrator, **When** they sign in, **Then** they are
   directed to their respective workspace.
3. **Given** an applicant in the application, **When** they navigate, **Then** they can move
   between sections in any order, incomplete required items are visually indicated without
   blocking navigation, and completeness is validated as a whole at submission.

---

### User Story 14 - Change history and confidentiality (Priority: P2)

The system maintains a change history for each application (what changed, who, when), shows it on
the application record to supervisors, DTD, and the committee, and withholds it from the
applicant. Confidentiality of application data is enforced at the data layer, not by the
interface.

**Why this priority**: Auditability and confidentiality are cross-cutting obligations, realized
alongside the flows that write to the history. Anchors: RQ093–RQ095; Constitution VI.

**Independent Test**: Program recommendations, completeness determinations, placements, and
notification sends appear in an application's change history to a reviewer; the same history is
not visible to the applicant.

**Acceptance Scenarios**:

1. **Given** a consequential change (recommendation, determination, placement, notification send),
   **When** it occurs, **Then** it is recorded in the application's change history with who and
   when.
2. **Given** the application record, **When** a supervisor, DTD, or committee member views it,
   **Then** the change history is visible.
3. **Given** the application record, **When** the applicant views it, **Then** the change history
   is withheld.

---

### Edge Cases

- **HR Links unavailable** (fresh vs. resumed Draft): fresh leaves personnel fields empty for
  manual entry; a resumed Draft keeps its saved values. Retrieval failure never blocks the
  application. (UC-1.4 ext 2a.)
- **Declined personnel change** on resume: the saved value stands. (UC-1.4 ext 3a.)
- **Invalid or oversized document**: rejected; the existing slot contents are left unchanged; no
  partial/corrupt file is stored. (UC-1.3 ext 3a, 3b, 4a.)
- **Missing/unreadable previously-attached document** on resume: flagged and re-attachment
  prompted before submit. (UC-1.2 ext 2a.)
- **Supervisor disapproves**: routing is unchanged; both supervisors review regardless. (UC-2.1
  ext 2a.)
- **Applicant modifies after a Complete determination**: returns to DTD for re-validation; the
  prior determination stands in the change history. (UC-2.2 ext 2b.)
- **Tie in final scores**: recorded and reflected in ranking; not broken by the system; resolved
  by DTD at placement. (UC-3.1 ext 5a.)
- **Applicant in multiple program pools**: scored and ranked independently per program; not
  reconciled across programs by scoring. (UC-3.1 ext 7a.)
- **Placing an already-placed applicant**: transfers the placement; exactly one placement holds
  at all times. (UC-3.2 ext 2a.)
- **Finalize with unplaced applicants**: unplaced become not-selected; finalize does not require
  everyone placed. (UC-3.2 ext 5a.)
- **Resend to an already-notified applicant**: allowed after a warning. (UC-3.3 ext 3a.)
- **Notification send failure**: recorded; the run continues; the applicant stays not-notified and
  can be included later. (UC-3.3 ext 4a; UC-5.1 ext 3a.)
- **Reminder interval elapses again with action still not taken**: the reminder **re-fires each
  interval** until the action is recorded (resolved OI-3, Q3=B).
- **Applicant with no second-line supervisor** (top of the supervisory chain): the application is
  held after the first-line decision and surfaced to DTD, who designates an alternate second-line
  reviewer; it then routes to that reviewer. (Resolved OI-6.)

## Requirements *(mandatory)*

### Functional Requirements

Requirements below restate the source RQ statements as testable behavior and cite the anchor.
Where the source is silent or in conflict, the requirement carries a `[NEEDS CLARIFICATION]`
marker or references an Open Item.

**Application submission (UC-1.1–1.4)**

- **FR-001**: The system MUST allow an authenticated, active NCUA employee to create and submit
  an application while a cycle is Open. (RQ001)
- **FR-002**: The system MUST populate personnel information (Name, Location, Grade, Job Series,
  Job Title) from HR Links when an application is started, and MUST allow manual entry when it
  cannot be retrieved. (RQ002, RQ003) *(Retrieval mechanism — see Dependency D-1.)*
- **FR-003**: The system MUST prompt the applicant to accept any personnel value that changed
  since the last save before applying it. (RQ004)
- **FR-004**: The system MUST allow the applicant to select and rank between one and three program
  options, highest to lowest preference. (RQ005)
- **FR-005**: The system MUST allow the applicant to select three OPM competencies, three
  technical competencies, and four ECQs. (RQ006, RQ007, RQ008) *(Resolved OI-1: the form captures
  all three groups; UC-1.1 step 3 is to be corrected to add the three technical competencies.)*
- **FR-006**: The system MUST allow the applicant to attach, download, and remove the three
  supporting documents (resume, statement of interest, performance rating appraisal), accepting
  only PDF or Word files within the size limit. (RQ009; UC-1.3) The attached performance-rating
  appraisal document is **distinct** from the numeric `LatestPerformanceRating` field in FR-006a.
  (Resolved OI-8.)
- **FR-006a**: The system MUST capture the applicant's latest performance rating as a separate
  numeric value (`LatestPerformanceRating`), independent of the attached appraisal document.
  (Resolved OI-8; Clarifications 2026-07-25.)
- **FR-007**: The system MUST allow saving an incomplete application as a Draft and resuming it
  later with all data intact. (RQ010; UC-1.2)
- **FR-008**: The system MUST present a saved Draft as read-only and prevent submission when the
  cycle is Closed. (RQ011)
- **FR-009**: The system MUST validate that all required fields and documents are present before
  accepting a submission, validating the whole application at submission rather than per section.
  (RQ012, RQ107)
- **FR-010**: The system MUST confirm successful submission to the applicant. (RQ013)
- **FR-009a** **[PROPOSED — awaiting DTD confirmation]**: The system MUST present the application
  as an ordered wizard of six steps — personnel, program choices, competencies and ECQs, eligibility
  and background, supporting documents, review and submit — navigable forward and backward only,
  with jump-to-step links from the review step. (RQ105a)
  *Rationale:* supersedes RQ105's free-order navigation. A guided sequence suits a once-a-cycle form
  with dependencies between steps better than free browsing. **Advancing is never blocked**: FR-009
  (whole-application validation at submission) and RQ106 (indicate incomplete items without blocking)
  are unaffected — missing items surface at the review step and block Submit, never Next.
- **FR-009b** **[PROPOSED — awaiting DTD confirmation]**: On resuming a saved draft, the system MUST
  prompt the applicant to accept or decline personnel values that have changed in the directory since
  the draft was saved. (RQ105b)
- **FR-011**: The system MUST prevent more than one application per applicant per cycle. (RQ014)

**Endorsement (UC-2.1)**

- **FR-012**: The system MUST route a submitted application to the first-line supervisor, then to
  the second-line supervisor after the first records a decision, assigning supervisors from the
  applicant's position in the organizational hierarchy. (RQ015, RQ016, RQ017) *(Hierarchy source —
  see Dependency D-1.)*
- **FR-012a** **[PROPOSED — pending DTD confirmation]**: When the applicant has no second-line
  supervisor (top of the supervisory chain), the system MUST hold the application after the
  first-line decision and surface it to DTD, who MUST designate an alternate second-line reviewer;
  the application then routes to that reviewer and proceeds as a normal second-line endorsement.
  (Resolved OI-6; Clarifications 2026-07-25.)
  *Proposed rationale (Constitution I): no source RQ/UC covers the no-second-line case; this
  behavior originates from the OI-6 clarification, not the source documents. It may be specified,
  planned, and generated, but MUST NOT be transcribed into the application until DTD confirms it.
  The dependent data fields (`AlternateSecondLineEmail`, `SupervisorLevel = Alternate Second Line`,
  `RoutingStage = Held For Alternate`) are Proposed on the same basis.*
- **FR-013**: The system MUST let a supervisor record an approve or disapprove decision and MUST
  require a disposition statement on both. (RQ018, RQ019)
- **FR-014**: The system MUST display the first-line decision and statement to the second-line
  supervisor, and MUST advance the application to the next reviewer regardless of approval or
  disapproval. (RQ020, RQ021)
- **FR-015**: The system MUST provide each supervisor a view-only link to the application. (RQ022)
- **FR-016**: The system MUST let a supervisor recommend one or more alternative program options
  without altering the applicant's selections, recording the recommendation (options, who, when)
  to the change history to inform DTD at placement. (RQ023, RQ024, RQ025)

**Validation (UC-2.2)**

- **FR-017**: The system MUST allow DTD to review a submitted application after both supervisor
  decisions, mark it Complete or Incomplete, and prevent advancement to committee until Complete.
  (RQ026, RQ027, RQ028)
- **FR-018**: The system MUST present DTD a list of Incomplete applications for follow-up, and MUST
  let DTD edit an application (attach documents, supply values) to bring it to complete. (RQ029,
  RQ030)
- **FR-019**: The system MUST record each completeness determination in the change history (what,
  who, when), and MUST advance an application to committee review when marked Complete. (RQ031,
  RQ032)

**Committee scoring and ranking (UC-3.1)**

- **FR-020**: The system MUST present each committee the applicants who selected a given program
  or any of its options, including each applicant once regardless of how many of that program's
  options they selected. (RQ033, RQ043)
- **FR-021**: The system MUST display to the committee the full application, supporting documents,
  supervisor decisions and statements, and the DTD completeness determination, plus the published
  rating sheet for the program. (RQ034, RQ035)
- **FR-022**: The system MUST accept only a defined anchor value (0, 1, 3, or 5) per criterion and
  reject any other value. (RQ036, RQ037)
- **FR-023**: The system MUST retain committee scores across multiple sessions and sum each
  applicant's criterion points into a final score. (RQ039, RQ040)
- **FR-024**: The system MUST rank the applicants in a program pool by final score once every
  applicant in the pool is scored, record each rank on the application, and score/rank an
  applicant independently in each program they selected. (RQ041, RQ042, RQ043)
- **FR-025**: The system MUST prevent committee scoring of a program until its rating sheet is
  published and until the cycle enters In Review. (RQ044, RQ100)
- **FR-026**: The system MUST compute each applicant's percent of possible as the final score
  divided by (five × the number of criteria on the applicant's rating sheet). (RQ119)

**Selection and placement (UC-3.2)**

- **FR-027**: The system MUST present DTD, per program, the pool's applicants with committee
  ranking, percent of possible, ranked program-option preferences, supervisor recommendations,
  and placement status. (RQ045)
- **FR-028**: The system MUST let DTD place an applicant into a program option, permit at most one
  active placement per applicant at any time, indicate when a selected applicant is already placed
  elsewhere, and transfer the placement (removing the prior) when DTD places them anew. (RQ046,
  RQ047, RQ048, RQ049)
- **FR-029**: The system MUST let DTD remove a placement and revise placements at any time before
  finalization. (RQ050, RQ054)
- **FR-030**: The system MUST let DTD finalize the cohort, lock all placements, and mark every
  applicant not placed in a program option as not selected. (RQ051, RQ052, RQ053)

**Notifications and reminders (UC-5.1, UC-5.2)**

- **FR-031**: The system MUST notify the responsible stakeholder by email when an action becomes
  pending, include a link to the relevant application or task, and notify the next reviewer when
  an application advances. (RQ055, RQ056, RQ057)
- **FR-032**: The system MUST send a reminder to a first-line supervisor, second-line supervisor,
  or committee five days after their action is pending with none recorded, and to DTD three days
  after a selection entry is pending with none recorded. The system MUST **re-send the reminder
  each interval** (5 days / 3 days respectively) until the required action is recorded. (RQ058,
  RQ059, RQ060, RQ061) *(Resolved OI-3: reminders repeat each interval, not fire-once.)*
- **FR-033**: The system MUST stop reminders for a step once the required action is recorded.
  (RQ062)

**Disposition notifications (UC-3.3)**

- **FR-034**: The system MUST withhold all disposition results from applicants until DTD issues
  final notifications, and MUST let DTD notify applicants after the cohort is finalized. (RQ063,
  RQ064)
- **FR-035**: The system MUST let DTD select recipients individually or all applicants in the
  cohort, and send each their disposition (selection and program option, or non-selection).
  (RQ065, RQ066)
- **FR-036**: The system MUST record each send outcome per applicant, mark successes as notified,
  record each send in the change history, and indicate which applicants have been notified.
  (RQ067, RQ068, RQ069)
- **FR-037**: The system MUST report send failures to DTD and allow the applicant to be included
  in a later send, and MUST allow re-sending to an already-notified applicant after warning.
  (RQ070, RQ071)

**Administration — program options (UC-4.1)**

- **FR-038**: The system MUST let DTD create, edit, and remove program options, recording each
  option's name, description, vendor, grade level, course length, competency, requirements, and
  website, organized under its parent program. (RQ072, RQ073, RQ074)
- **FR-038a** **[PROPOSED — awaiting DTD confirmation]**: The system MUST let DTD create, edit, and
  remove programs, recording each program's name and code. (RQ072a)
  *Rationale:* every existing requirement treats the three programs (NEXT, MDP, HPP) as a fixed,
  closed set — `spec.md` Key Entities, UC-4.1, and `PROGRAMS.md` all assume DTD never adds a fourth.
  Administering programs is a scope addition, not a restatement, so it is Proposed under
  Constitution I and MUST NOT be transcribed into the app until DTD confirms it.
- **FR-038b** **[PROPOSED — awaiting DTD confirmation]**: The system MUST refuse to delete a program
  or program option that is referenced by any application program selection, placement, rating sheet,
  or committee score — in any cycle, not only prior ones — and MUST tell the user which reference
  blocked the deletion. (RQ072b)
  *Rationale:* SharePoint enforces no referential integrity, so an unguarded delete silently orphans
  an applicant's ranked selections or a recorded placement. Deletion remains available for programs
  and options that have never been used.

**Administration — cycles (UC-4.2)**

- **FR-039**: The system MUST let DTD create a cycle with open, close, and expected-decision
  dates, supporting four states (Scheduled, Open, Closed, In Review) with DTD transitions. (RQ075,
  RQ076, RQ077)
- **FR-040**: The system MUST accept applicant submissions and resumes only while a cycle is Open,
  and MUST prevent more than one cycle from being Open at once. (RQ078, RQ079)
- **FR-041**: The system MUST reject inconsistent cycle dates (close before open, or expected
  decision before close), and MUST display the expected decision date to applicants. (RQ080,
  RQ081)

**Administration — rating sheets (UC-4.3)**

- **FR-042**: The system MUST let DTD create a per-program, per-cycle rating sheet by selecting
  one or more criteria from the shared catalog, and MUST prevent saving a sheet with no selected
  criterion. (RQ082, RQ083, RQ086)
- **FR-043**: The system MUST record each saved rating sheet as an immutable version, create a new
  superseding version on each change, and let DTD view prior versions. (RQ087, RQ088, RQ089)
- **FR-044**: The system MUST let DTD publish a rating sheet version, prevent further changes once
  published, and allow unpublishing only while no scores have been recorded against it. (RQ090,
  RQ091, RQ092)
- **FR-045**: The system MUST flag a criterion on a draft rating sheet whose end date has passed
  and prevent publishing a sheet that carries such a criterion. (RQ117, RQ118)

**Administration — criterion catalog (UC-4.4)**

- **FR-046**: The system MUST let DTD define a catalog criterion with a name, description, and the
  four fixed anchors (0, 1, 3, 5), permitting no criterion-specific scale, and allow attaching an
  illustrative example to any anchor. (RQ109, RQ110, RQ111)
- **FR-047**: The system MUST maintain each criterion as Draft or Published, allow editing only
  while Draft, and prevent any change once Published (a change is a new criterion). (RQ112, RQ113,
  RQ114)
- **FR-048**: The system MUST record a start and end date per criterion (null end = still
  available), and allow only a Published, in-window criterion to be selected onto a rating sheet.
  (RQ115, RQ116)

**Change history and post-submission modification (RQ093–100)**

- **FR-049**: The system MUST maintain a change history per application (what, who, when), display
  it on the application record to supervisors, DTD, and committee, and withhold it from the
  applicant. (RQ093, RQ094, RQ095)
- **FR-050**: The system MUST let an applicant modify any part of a submitted application until the
  cycle enters In Review, prevent modification afterward, flag a modified application for DTD
  re-validation, and record each post-submission modification in the change history. (RQ096,
  RQ097, RQ098, RQ099)

**Presentation and navigation (RQ101–108)**

- **FR-051**: The system MUST provide a public landing page presenting program information and the
  current cycle's state and dates, with content appropriate to the state, plus supporting
  applicant information (eligibility guidance, FAQ, contact, prior-cohort outcomes). (RQ101,
  RQ102, RQ103)
- **FR-052**: The system MUST provide authenticated sign-in for committee members and DTD
  administrators, directing each to their respective workspace. (RQ104)
- **FR-053**: The system MUST present the application as distinct sections navigable in any order,
  visually indicate incomplete required items without blocking navigation, and let the applicant
  view a program option's full details while selecting without leaving the application. (RQ105,
  RQ106, RQ108)

**Cross-cutting (Constitution)**

- **FR-054**: The system MUST enforce confidentiality of application data through the data-layer
  permission model, not through interface affordances alone. (Constitution VI)
- **FR-055**: The system MUST retain application records and their supporting documents, and keep
  them retrievable, for seven years. (Constitution VII)

### Key Entities *(logical; see `docs/LDP_Logical_Data_Model.md` for the backing model)*

- **Cycle**: An application cycle with a state (Scheduled/Open/Closed/In Review) and open, close,
  and expected-decision dates. Scopes applications, rating sheets, and placements.
- **Program / Program Option**: Three programs (NEXT, MDP, HPP), each grouping selectable options
  with descriptive attributes. Applicants select options; committees score at the program level;
  DTD places into an option.
- **Application**: The central applicant record — personnel data, competencies/ECQs, supporting
  information, three document attachments, and a lifecycle status. Belongs to a cycle.
- **Application Program Choice**: An applicant's ranked selection of a program option (rank 1–3).
- **Supervisor Endorsement**: A supervisor's decision (approve/disapprove), required statement,
  level (first/second line), and optional program-option recommendations.
- **Rating Sheet / Rating Criterion**: A per-program, per-cycle immutable, versioned sheet that
  selects criteria from the catalog; publishable and frozen.
- **Criterion Catalog / Criterion Anchor**: The shared, unversioned master criteria, each with
  four fixed 0/1/3/5 anchors (with optional examples) and an availability window.
- **Committee Score**: An applicant's per-program final score, percent of possible, per-criterion
  breakdown, and rank.
- **Placement**: DTD's placement of an applicant into exactly one program option within a cycle;
  lockable at finalization.
- **Notification / Change History**: Append-only logs of sends and consequential changes,
  referencing an application by ID value.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An eligible employee can complete and submit an application in a single sitting in
  under 20 minutes, with personnel fields pre-filled, and can resume a Draft with zero loss of
  previously entered data.
- **SC-002**: 100% of applications that reach the committee have both supervisor decisions
  recorded (each with a statement) and a DTD Complete determination — no incomplete application is
  ever scored.
- **SC-003**: Every committee criterion score on record is one of the four anchor values
  (0/1/3/5); no off-anchor value is ever stored as final.
- **SC-004**: Every applicant holds at most one active placement at all times, including during
  revision, and after finalization every applicant is either placed in exactly one option or
  marked not-selected.
- **SC-005**: No applicant can view any disposition result before the cohort is finalized and DTD
  issues notifications, and no applicant can view any application's change history.
- **SC-006**: 100% of pending-action transitions produce a recorded notification to the correct
  stakeholder with a working link; every send (success or failure) is recorded, and no failure is
  silently dropped.
- **SC-007**: At most one cycle is Open at any time, and inconsistent cycle dates are rejected at
  entry 100% of the time.
- **SC-008**: The application passes the accessibility checker with zero errors and meets WCAG 2.1
  AA before any feature is considered verified. (Constitution V)
- **SC-009**: Application records and their supporting documents remain retrievable for seven
  years after the cycle closes. (Constitution VII)

## Assumptions

- **Appendix A / Appendix B / Appendix D and the traceability matrix are authoritative for the
  detail they carry** but are not present in `docs/`. Choice-field values (competency lists, ECQ
  lists, status values), the full application field set (Appendix A), and reminder triggers
  (Appendix D) are taken from the data model and use cases as available; exact enumerations are
  deferred to those appendices. (See Dependency D-2.)
- **Document format and size**: only PDF and Word documents are accepted; a size limit applies.
  The specific limit is not stated in the source and is assumed to be a standard, reasonable value
  set at build time (UC-1.3 ext 3b).
- **Reminders repeat each interval** until the action is recorded (resolved OI-3, Q3=B): 5 days
  for supervisors/committee, 3 days for DTD.
- **Every applicant has a two-level supervisory chain**; the no-second-line edge (OI-6) is assumed
  rare and is flagged rather than designed.
- **Eligibility is not system-enforced**; grade levels and eligibility guidance are descriptive
  content only (RQ103 note; data model GradeLevel note).
- **Identity is M365/SharePoint** (email as identity); there is no custom users/roles list in
  Phase I. Workspace routing (RQ104) keys off M365 group/role membership.
- **The application status set** is Draft, Submitted, Complete, Incomplete, Placed, Not Selected,
  inferred from the use cases and to be validated against how state is implemented (data model
  note on APPLICATIONS.Status).

## Dependencies

- **D-1 — HR Links / organizational hierarchy access.** FR-002 (personnel population) and FR-012
  (supervisor assignment by hierarchy) require reading HR Links personnel data and the reporting
  chain. The retrieval mechanism is unspecified and must be reconciled at planning against
  Constitution II (**no premium connectors**). This is a material technical risk: the standard
  path to such data may require a premium connector or a maker-provided intermediary. Resolve at
  `/speckit-plan`. The plan MUST also decide whether the applicant's first-/second-line supervisor
  identities are **captured as a snapshot on the application at submission** or **resolved live at
  each routing step** — that choice affects the data model (whether assigned supervisor emails are
  stored on the application) and routing correctness, and it interacts with FR-012a (DTD-designated
  alternate second-line reviewer).
- **D-2 — Source appendices not in repository.** Appendix A (full field set), Appendix B
  (traceability matrix / choice values), and Appendix D (reminder triggers) are referenced by the
  source documents but absent from `docs/`. They are needed to finalize field lists and choice
  enumerations. Obtain or confirm before those details enter the build.

## Cross-Document Inconsistencies & Open Items

Per Constitution Principle I, discrepancies among source documents are surfaced here for
resolution at specify/clarify. Items **OI-1, OI-2, OI-3** were raised as blocking clarification
questions and are now **resolved** (recorded below). The remainder are recorded for the maker's
review; none blocks specification. A standalone review copy of every item lives at
`docs/LDP_Flagged_Inconsistencies.md`.

- **OI-1 — RESOLVED (Q1=A).** UC-1.1 step 3 listed "3 OPM competencies, 4 ECQs," omitting the
  three technical competencies that RQ007 and `APPLICATIONS.TechnicalCompetencies` require. Decision:
  the form captures **all three groups** (3 OPM + 3 technical + 4 ECQ). FR-005 stands; **UC-1.1
  step 3 needs a doc fix** to add the technical competencies.
- **OI-2 — RESOLVED (Q2=B), with Constitution follow-up.** The data model names lists in
  UPPER_SNAKE_CASE (e.g., `APPLICATION_PROGRAM_CHOICES`); the Constitution's Additional Constraints
  require Pascal case for data sources, and a SharePoint list name becomes its (unrenameable) Power
  Fx identifier. Decision: **upper snake case wins** — lists are created and referenced in upper
  snake case; column (field) names remain Pascal case. **Constitution amended** to record this:
  v1.2.0 (2026-07-25) sets SharePoint list names to `UPPER_SNAKE_CASE` in Additional Constraints →
  Naming conventions. No deviation remains.
- **OI-3 — RESOLVED (Q3=B).** RQ058–RQ061 stated only each reminder's first fire; UC-5.2 ext 3b
  left repeat-vs-once open. Decision: reminders **re-fire each interval** (5 days supervisors/
  committee, 3 days DTD) until the action is recorded. FR-032 updated.
- **OI-4 (doc note stale).** The requirements note on RQ023–RQ025 says "UC-2.1 still describes the
  older revise model." UC-2.1 as written already reflects the **recommend** model (ext 1a). The
  note appears stale; the use case needs no change, but the note should be corrected.
- **OI-5 (index omission).** The Use Cases "Contents" list does not include **UC-4.4 Manage Rating
  Criterion Catalog**, though the use case exists in the body and is referenced by UC-4.3 and the
  requirements. Add UC-4.4 to the contents.
- **OI-6 — RESOLVED (Clarifications 2026-07-25).** Endorsement routing (RQ016) assumes a
  second-line supervisor exists. Decision: when none exists, the application is held after the
  first-line decision and surfaced to DTD, who designates an alternate second-line reviewer; it
  then routes to that reviewer (FR-012a). *Note:* this designation capability is new behavior DTD
  must be given — the plan MUST provide a way for DTD to see held applications and assign the
  alternate. **FR-012a is marked Proposed** (Constitution I): it is unsupported by the source RQ/UC
  and MUST NOT be transcribed until DTD confirms it.
- **OI-7 — DEFERRED (maker, 2026-07-25).** UC-3.1 has the committee act "through a designated
  recorder"; how the recorder and committee members are identified, authorized, and scoped to a
  program's pool is unspecified. The maker has not yet defined user access groups — this is
  deferred to a later access-model decision. It bears on the data-layer permission model
  (Constitution VI) and MUST be settled before the committee-scoring screens are built.
- **OI-8 — RESOLVED (Clarifications 2026-07-25).** "Performance rating" is both a required
  **attached document** (RQ009) and a numeric field `APPLICATIONS.LatestPerformanceRating`.
  Decision: they are **distinct** — the attached appraisal document and a separate numeric latest
  rating are both captured (FR-006, FR-006a). No conflation; the data model keeps both.
- **OI-9 (terminology).** RQ060 and the UC-5.2 trigger table describe the committee reminder as
  pending "endorsement/approval," though the committee's action is **scoring**, not endorsement.
  Cosmetic; align wording to avoid confusion.
