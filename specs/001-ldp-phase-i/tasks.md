---
description: "Task list for LDP Application Phase I"
---

# Tasks: LDP Application — Phase I

> **Schema notes:** `EMPLOYEE_DIRECTORY` withdrawn 2026-07-26. `COMMITTEE_SCORES` retired 2026-08-07. `PLACEMENTS` retired 2026-08-11 (folded into `APPLICATIONS.PlacementProgramID` / `PlacementOptionID`). Tasks below referencing those lists remain historical; `build/` is the source of truth.


**Input**: Design documents from `specs/001-ldp-phase-i/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/screens.md, quickstart.md

**Tests**: NOT generated. Nothing in this stack (canvas app over SharePoint, YAML-authored) is
machine-testable from the repository (Constitution IV). Each user story ends with a **manual
validation** task against `quickstart.md`. The agent produces *generated* artifacts only; the maker
transcribes and marks work *verified* (Constitution IV).

**Artifacts the agent produces (for manual transcription):**
- `build/lists/<LIST>.md` — one SharePoint list definition spec per list.
- `build/screens/<Screen>.yaml` — one canvas screen (classic controls, PowerLibs components) per screen.
- Flows are **not** produced as artifacts; the agent will produce flow *construction instructions* in a
  later pass (Constitution II/IV).

**Directive for this build:** define the SharePoint lists first (Phase 2), then build screens
(Phases 3+). Notification flows, HR Links personnel loading (D-1), and the committee access model
(OI-7) are **deferred seams**.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: different file, no dependency on an incomplete task → parallelizable.
- **[Story]**: user-story label (US1–US14) for story-phase tasks only.

---

## Phase 1: Setup (Shared Infrastructure)

- [x] T001 Create the build output structure: `build/lists/` and `build/screens/` at repo root (per plan.md Project Structure).
- [x] T002 [P] Author `build/CONVENTIONS.md` capturing naming rules — list names `UPPER_SNAKE_CASE`, column names Pascal case, control 3-char camel-case prefixes with app-wide uniqueness, screen names plain/spaced/ending "Screen" — sourced from `.specify/memory/constitution.md` (v1.2.0) and `data-model.md`.
- [x] T003 [P] Author `build/POWERLIBS_COMPONENTS.md` — using the PowerLibs MCP, discover the components covering the palette in `contracts/screens.md`, record the chosen component per UI need and a project-convention rename map (Constitution VIII).
- [ ] T003b [P] Apply the app theme: `build/theme/theme.md` is generated from `docs/design/color-palette.html`. Transcribe its `Set(ColorPalette, …)` **and** `Set(Typography, …)` blocks into **`App.OnStart`** (classic `ColorPalette`/font path only — modern/Creator Kit excluded per Constitution II). All screens reference `ColorPalette.*` and `Typography.*`; **no hardcoded colours, fonts, sizes, or weights** (Constitution VIII). Screen accessibility passes check colour pairs against theme.md's AA contrast table (Constitution V).

> **Global colour/type rule (applies to every screen task):** bind colours to `ColorPalette.*` and
> fonts/sizes/weights to `Typography.*` from `build/theme/theme.md`; never hardcode. Use
> `SuccessText`/`WarningText`/`DangerText` for status text/icons and the base `Success`/`Warning`/
> `Danger` only for fills/badges; use `TextSecondary` for large text only, `TextHelp` for help/
> disabled-label text, never `TextMuted` for meaningful text; body ≥ `Typography.SizeBody` (11pt),
> nothing meaningful below `SizeCaption` (9pt) (theme.md A11y).

---

## Phase 2: Foundational — SharePoint List Definitions (Blocking Prerequisites)

**Purpose**: Define all 15 lists. Everything binds to these; no screen can be built first.

**⚠️ CRITICAL**: No user-story (screen) work begins until the list definitions exist and the maker
has created the lists.

- [x] T004 [P] Author `build/lists/CYCLES.md` (columns, `State` choices, dates; index `State`) per data-model.md.
- [x] T005 [P] Author `build/lists/PROGRAMS.md` (NEXT/MDP/HPP) per data-model.md.
- [x] T006 [P] Author `build/lists/PROGRAM_OPTIONS.md` (all attributes; Lookup→PROGRAMS) per data-model.md.
- [x] T007 [P] Author `build/lists/APPLICATIONS.md` — base fields **plus** added `FirstLineSupervisorEmail`, `SecondLineSupervisorEmail`, `AlternateSecondLineEmail`, `RoutingStage`, `RevalidationFlag`; keep both the performance-rating **attachment** and numeric `LatestPerformanceRating` (FR-006/006a); `Status` choices; indexes `CycleID`,`ApplicantEmail`,`Status`,`RoutingStage` (data-model ADD section).
- [x] T008 [P] Author `build/lists/APPLICATION_PROGRAM_CHOICES.md` (Lookups→APPLICATIONS, PROGRAM_OPTIONS; `Rank` 1–3).
- [x] T009 [P] Author `build/lists/SUPERVISOR_ENDORSEMENTS.md` — `SupervisorLevel` choices incl. **Alternate Second Line** (FR-012a); `Decision`; required `DispositionStatement`; `RecommendedOptions`.
- [x] T010 [P] Author `build/lists/RATING_SHEETS.md` (versioned; `State`,`IsCurrent`; Lookups→CYCLES,PROGRAMS; indexes).
- [x] T011 [P] Author `build/lists/RATING_CRITERIA.md` (Lookups→RATING_SHEETS,CRITERION_CATALOG; `DisplayOrder`).
- [x] T012 [P] Author `build/lists/CRITERION_CATALOG.md` (`State`; `StartDate`/`EndDate`; index `State`).
- [x] T013 [P] Author `build/lists/CRITERION_ANCHORS.md` (`Score` fixed 0/1/3/5; Lookup→CRITERION_CATALOG).
- [x] T014 [P] Author `build/lists/COMMITTEE_SCORES.md` (hybrid: `FinalScore`,`PercentOfPossible`,`CriterionScores` JSON,`Rank`; Lookups; indexes).
- [x] T015 [P] Author `build/lists/PLACEMENTS.md` (Lookups→APPLICATIONS,PROGRAM_OPTIONS,CYCLES; `IsFinalized`).
- [x] T016 [P] Author `build/lists/NOTIFICATIONS.md` (`ApplicationID` plain Number; `NotificationType`,`SendOutcome`).
- [x] T017 [P] Author `build/lists/CHANGE_HISTORY.md` (`ApplicationID` plain Number; `ChangeType` incl. Post-Submission Modification, Alternate Designation).
- [~] T018 [P] ~~Author `build/lists/EMPLOYEE_DIRECTORY.md`~~ — **WITHDRAWN 2026-07-26.** Personnel comes from an existing system (D-1); the interim list is not part of the design.
- [x] T019 Author `build/lists/_CHOICES.md` consolidating every choice set from data-model.md; mark competency/ECQ/status values **TBD (Appendix B, D-2)** — do not invent values (Constitution I). (depends on T004–T018)
- [x] T020 Author `build/lists/_RELATIONSHIPS_AND_INDEXES.md` — Lookup wiring and the indexed-column list; note lookups are applied after all target lists exist (delegation, Constitution III). (depends on T004–T018)
- [ ] T021 **[MAKER]** Create the 14 lists in SharePoint from `build/lists/*`, apply indexes and lookups. Confirm a `CycleID`-scoped query returns delegation-clean. (`EMPLOYEE_DIRECTORY` seeding withdrawn 2026-07-26.) (Foundational verification — Constitution IV)

**Checkpoint**: Data layer exists and is delegation-clean. Screen work can begin.

---

## Phase 3: User Story 6 — Administer Application Cycles (Priority: P1) 🎯 MVP-enabler

**Goal**: DTD creates a cycle and moves it Scheduled→Open→Closed→In Review; one Open at a time.
**Independent Test**: quickstart Admin-setup cycle scenarios (valid/invalid dates; second-Open block).
**Why first**: no applicant or reviewer action is possible without a cycle; it is the workflow master switch.

- [x] T022 [US6] Author `build/screens/ApplicationCyclesScreen.yaml` — cycle CRUD, three date pickers, state-transition controls, bound to `CYCLES`, assembled from PowerLibs components (Constitution VIII).
- [x] T023 [US6] Add guards in the same screen: reject inconsistent dates and block a second Open cycle via a delegable count (R6, FR-040/041).
- [ ] T024 [US6] Accessibility pass on `ApplicationCyclesScreen.yaml` (checker-clean, labels, screen name) (Constitution V).
- [ ] T025 [US6] **[MAKER]** Transcribe + validate against quickstart cycle scenarios; mark verified.

**Checkpoint**: A cycle can be created and driven through all four states.

---

## Phase 4: User Story 7 — Administer Program Options (Priority: P2)

**Goal**: DTD maintains programs and their options with descriptive attributes.
**Independent Test**: quickstart program-option CRUD (missing-attribute block).

- [x] T026 [US7] Author `build/screens/ProgramOptionsScreen.yaml` — program grouping + option CRUD (all attributes), bound to `PROGRAMS`/`PROGRAM_OPTIONS`, required-field block on `OptionName` (FR-038).
- [x] T026a [US7] Add program CRUD (create/edit/delete a program) to the same screen. **[PROPOSED — FR-038a]** (Constitution I): generate it, but **do not transcribe** until DTD confirms — every existing requirement treats NEXT/MDP/HPP as a closed set.
- [x] T026b [US7] Add the delete guards (FR-038b): refuse to delete a program referenced by `PROGRAM_OPTIONS`/`RATING_SHEETS`/`COMMITTEE_SCORES`, or an option referenced by `APPLICATION_PROGRAM_CHOICES`/`PLACEMENTS`, in any cycle; name the blocking reference in the message. Use `IsEmpty(Filter(…))` on indexed columns — `CountRows` does not delegate (Constitution III).
- [ ] T027 [US7] Accessibility pass on `ProgramOptionsScreen.yaml`.
- [ ] T028 [US7] **[MAKER]** Transcribe + validate + seed the real program options; mark verified.

---

## Phase 5: User Story 8 — Administer Rating Criterion Catalog (Priority: P2)

**Goal**: DTD builds the shared catalog: name, description, four fixed 0/1/3/5 anchors, availability window.
**Independent Test**: quickstart criterion define/publish (block unless all four anchors; no edit once Published).

- [x] T029 [US8] Author `build/screens/CriterionCatalogScreen.yaml` — criterion CRUD + four-anchor editor (with optional examples) + Draft/Publish + start/end dates, bound to `CRITERION_CATALOG`/`CRITERION_ANCHORS` (FR-046–048).
- [x] T030 [US8] Add publish/edit guards: block publish unless all four anchors present; no edit once Published; end-date retirement (RQ114–116).
- [ ] T031 [US8] Accessibility pass on `CriterionCatalogScreen.yaml`.
- [ ] T032 [US8] **[MAKER]** Transcribe + validate; mark verified.

---

## Phase 6: User Story 9 — Administer Committee Rating Sheets (Priority: P2)

**Goal**: DTD builds per-program/per-cycle immutable versioned sheets from catalog criteria; publish/freeze.
**Independent Test**: quickstart rating-sheet scenarios (≥1 criterion; passed-end-date block; unpublish-after-score block).
**Depends on**: US8 (catalog must exist to select from).

- [x] T033 [US9] Author `build/screens/RatingSheetsScreen.yaml` — sheet builder, catalog criterion picker (Published + in-window only), immutable version list, publish/unpublish, bound to `RATING_SHEETS`/`RATING_CRITERIA`/`CRITERION_CATALOG` (FR-042–045).
- [x] T034 [US9] Implement append-as-row versioning (each save = new row + `IsCurrent` flip), zero-scores unpublish guard, passed-end-date publish block (R3, FR-044/045).
- [ ] T035 [US9] Accessibility pass on `RatingSheetsScreen.yaml`.
- [ ] T036 [US9] **[MAKER]** Transcribe + validate; mark verified.

---

## Phase 7: User Story 1 — Applicant Submits an Application (Priority: P1) 🎯 MVP

**Goal**: An employee completes, saves/resumes, and submits an application; duplicates blocked.
**Independent Test**: quickstart Submit scenarios (autofill/manual, rank 1–3, 3 OPM + 3 technical + 4 ECQ, three docs + numeric rating, Draft resume, whole-app validation, duplicate block).
**Depends on**: US6 (Open cycle), US7 (program options to select).

- [x] T037 [US1] Author `build/screens/ApplicationScreen.yaml` — sectioned, freely navigable screen (Personnel · Program Selections · Competencies & ECQs · Supporting Documents · Latest Performance Rating · Review & Submit), assembled from PowerLibs stepper/form/attachment/panel components (RQ105–108, Constitution VIII).
- [~] T038 [US1] ~~Bind personnel section to `EMPLOYEE_DIRECTORY`~~ — **SUPERSEDED 2026-07-26.** Personnel fields are hand-entered until D-1 exists; the supervisor snapshot at submit has no source and is not written. Revisit when the personnel integration lands.
- [x] T039 [US1] Implement program-option ranking (1–3) with the slide-out details panel (RQ108) and competency/ECQ selectors (3 OPM + 3 technical + 4 ECQ, FR-005); values sourced from `_CHOICES.md` (TBD Appendix B placeholders).
- [ ] T040 [US1] Implement supporting-document slots (resume, statement, appraisal; PDF/Word + size guard) and the numeric `LatestPerformanceRating` field (FR-006/006a).
- [x] T041 [US1] Implement Draft save/resume, read-only when cycle Closed (Draft) / In Review (submitted), duplicate-per-cycle block, and whole-application submit validation + confirmation (FR-007–011, R8).
- [ ] T042 [US1] Accessibility pass on `ApplicationScreen.yaml`.
- [ ] T043 [US1] **[MAKER]** Transcribe + validate against quickstart Submit scenarios; mark verified.

**Checkpoint**: An applicant can submit against an Open cycle → first demonstrable MVP slice.

---

## Phase 8: User Story 2 — Supervisors Endorse (Priority: P1)

**Goal**: First- then second-line endorsement with required statements and advisory recommendations; incl. the no-second-line alternate path.
**Independent Test**: quickstart Endorse + no-second-line (FR-012a) scenarios.
**Depends on**: US1 (submitted applications exist).

- [ ] T044 [US2] Author `build/screens/SupervisorQueueScreen.yaml` — queue filtered by `RoutingStage` and the signed-in supervisor's snapshot email; view-only open (RQ015–017/022).
- [ ] T045 [US2] Author `build/screens/SupervisorEndorsementScreen.yaml` — read-only application detail, Approve/Disapprove, **required** disposition statement, recommended-options field, first-line decision panel for second-line view (FR-013–016).
- [ ] T046 [US2] Implement routing on decision: 1st→2nd→Pending Validation; advance regardless of decision; write `SUPERVISOR_ENDORSEMENTS`; no-second-line → `Held For Alternate` (R5, FR-012/012a). **[PROPOSED — FR-012a]** the `Held For Alternate` / alternate-reviewer portion is Proposed (Constitution I); generate it, but **do not transcribe** it until DTD confirms.
- [ ] T047 [US2] Accessibility pass on both supervisor screens.
- [ ] T048 [US2] **[MAKER]** Transcribe + validate; mark verified.

---

## Phase 9: User Story 3 — DTD Validates Completeness (Priority: P1)

**Goal**: DTD marks Complete/Incomplete, edits to complete, designates alternate reviewers; only Complete advances.
**Independent Test**: quickstart Validate + alternate-designation scenarios.
**Depends on**: US2 (both decisions recorded, or held-for-alternate items).

- [ ] T049 [US3] Author `build/screens/DTDValidationQueueScreen.yaml` — queue by `RoutingStage` ∈ {Pending Validation, Held For Alternate} + Incomplete follow-up list; **Designate Alternate Second-Line Reviewer** action writing `AlternateSecondLineEmail` (FR-012a, RQ026–029). **[PROPOSED — FR-012a]** the Held-For-Alternate queue + designate action are Proposed (Constitution I); generate but **do not transcribe** until DTD confirms.
- [ ] T050 [US3] Author `build/screens/DTDApplicationReviewScreen.yaml` — editable detail, attach-missing-document, Mark Complete/Incomplete, writes to `CHANGE_HISTORY` (FR-017–019).
- [ ] T051 [US3] Implement re-validation of modified apps (`RevalidationFlag`) and advance-on-Complete routing to committee (RQ032, UC-2.2 ext 2b).
- [ ] T052 [US3] Accessibility pass on both DTD screens.
- [ ] T053 [US3] **[MAKER]** Transcribe + validate; mark verified.

---

## Phase 10: User Story 4 — Committee Scores and Ranks (Priority: P1)

**Goal**: Committee scores each pool on the 0/1/3/5 scale; system sums, computes percent of possible, ranks.
**Independent Test**: quickstart Score scenarios (off-anchor rejected; cross-session retention; rank on complete).
**Depends on**: US3 (Complete apps), US9 (published sheet), cycle In Review.
**⚠️ VERIFY GATE (Constitution VI / OI-7):** build and demo permitted, but **do not mark verified** until the SharePoint access model scopes committee members to their program pool.

- [ ] T054 [US4] Author `build/screens/CommitteeProgramPoolScreen.yaml` — pool gallery (selected program or any option, once each) with scored/not-scored status (RQ033/043).
- [ ] T055 [US4] Author `build/screens/CommitteeScoringScreen.yaml` — application detail + published rating sheet with **fixed 0/1/3/5 anchor choice** per criterion, running sum, cross-session save (FR-021–024, R4).
- [ ] T056 [US4] Implement scoring gates (sheet Published + cycle In Review), pool-complete detection, `FinalScore`/`PercentOfPossible` compute + `Rank` write-back; ties reflected not broken (FR-025/026, RQ119, R2).
- [ ] T057 [US4] Accessibility pass on both committee screens.
- [ ] T058 [US4] **[MAKER]** Transcribe + validate (verification gated on OI-7 access model); mark verified only after that model exists.

---

## Phase 11: User Story 5 — DTD Selects and Places (Priority: P1)

**Goal**: DTD places applicants into one option each using rankings; finalize locks and marks not-selected.
**Independent Test**: quickstart Place scenarios (transfer on conflict; finalize).
**Depends on**: US4 (ranked pools).

- [ ] T059 [US5] Author `build/screens/SelectionAndPlacementScreen.yaml` — per-program ranked gallery (rank, %-of-possible, preferences, supervisor recommendations, placement status), place/transfer/remove actions, **Finalize Cohort**, bound to `COMMITTEE_SCORES`/`PLACEMENTS`/`APPLICATION_PROGRAM_CHOICES`/`SUPERVISOR_ENDORSEMENTS` (FR-027–030).
- [ ] T060 [US5] Implement one-active-placement invariant + transfer-removes-prior, and finalize (lock placements, mark unplaced Not Selected) (FR-028/030, RQ047–053).
- [ ] T061 [US5] Accessibility pass on `SelectionAndPlacementScreen.yaml`.
- [ ] T062 [US5] **[MAKER]** Transcribe + validate; mark verified.

---

## Phase 12: User Story 11 — Issue Cohort Disposition Notifications (Priority: P2)

**Goal**: Post-finalize, DTD notifies applicants (some/all), with sent/failed tracking and warned resend.
**Independent Test**: quickstart Disposition scenarios.
**Depends on**: US5 (finalized cohort). **Note**: actual email send is a deferred flow (US10); this screen writes `NOTIFICATIONS`.

- [ ] T063 [US11] Author `build/screens/CohortDispositionScreen.yaml` — cohort list with notified status, select-individual/all, send action writing `NOTIFICATIONS` + `CHANGE_HISTORY`, sent/failed indicators, resend-with-warning (FR-034–037); nothing disclosed pre-finalize (FR-034).
- [ ] T064 [US11] Accessibility pass on `CohortDispositionScreen.yaml`.
- [ ] T065 [US11] **[MAKER]** Transcribe + validate (send simulated until US10 flow exists); mark verified.

---

## Phase 13: User Story 12 — Applicant Modifies a Submitted Application (Priority: P2)

**Goal**: Modify a submitted app until In Review; record to history; flag DTD re-validation.
**Independent Test**: quickstart Modify scenarios (read-only after In Review; no-change → no flag).
**Depends on**: US1 (submitted apps), US3 (re-validation queue).

- [ ] T066 [US12] Extend `build/screens/ApplicationScreen.yaml` with a submitted-app edit mode: editable until cycle In Review, read-only after; write changes to `CHANGE_HISTORY`, set `RevalidationFlag=Yes` on change, no flag when unchanged (FR-050, RQ096–100).
- [ ] T067 [US12] Accessibility pass on the modified `ApplicationScreen.yaml`.
- [ ] T068 [US12] **[MAKER]** Transcribe + validate; mark verified.

---

## Phase 14: User Story 13 — Public Landing & Authenticated Navigation (Priority: P2)

**Goal**: Cycle-state-aware public landing; role-routed workspaces; freely navigable app shell.
**Independent Test**: quickstart landing/nav scenarios.
**Note**: role gating depends on the OI-7 access model (deferred); the shell and routing skeleton are buildable now.

- [x] T069 [US13] Author `build/screens/LandingScreen.yaml` — cycle-state banner + program info + supporting sections (eligibility guidance, FAQ, contact, prior-cohort outcomes), auth-gated CTA (FR-051, RQ101–103).
- [x] T070 [US13] Author `build/screens/HomeScreen.yaml` + app-shell navigation — role-aware workspace tiles (role resolution stubbed pending OI-7) (FR-052, RQ104).
- [ ] T071 [US13] Accessibility pass on `LandingScreen.yaml` and `HomeScreen.yaml`.
- [ ] T072 [US13] **[MAKER]** Transcribe + validate; mark verified (role gating pending OI-7).

---

## Phase 15: User Story 14 — Change History & Confidentiality (Priority: P2)

**Goal**: Per-application change history shown to reviewers, withheld from applicants; confidentiality at the data layer.
**Independent Test**: quickstart change-history visibility scenarios.
**⚠️ VERIFY GATE (Constitution VI / OI-7):** the "withheld from applicant" guarantee is enforced by SharePoint permissions, not by hiding the control — **do not mark verified** until the access model exists.

- [ ] T073 [US14] Author `build/screens/ChangeHistoryPanel.yaml` — reusable panel listing `CHANGE_HISTORY` by `ApplicationID` (what/who/when), embedded on DTD/supervisor/committee application detail (FR-049, RQ093–095).
- [ ] T074 [US14] Accessibility pass on `ChangeHistoryPanel.yaml`.
- [ ] T075 [US14] **[MAKER]** Transcribe + validate; mark verified only after the OI-7 permission model withholds history from applicants.

---

## Phase 16: Deferred Seams (designed, not built this pass)

**Purpose**: Track the deferred integration work so it is not lost. Do NOT build in this pass.

- [ ] T076 [DEFERRED] Author flow construction instructions for notifications & reminders (UC-5.1/5.2, FR-031–033) — reminders **repeat each interval** until action (OI-3); flows send from `NOTIFICATIONS`. Produced in a later pass; **no deployable flow artifact** (Constitution II/IV).
- [~] T077 [DEFERRED] ~~Define the loading mechanism for `EMPLOYEE_DIRECTORY`~~ — **WITHDRAWN 2026-07-26**; superseded by the D-1 integration with the existing system of record. Original text: define personnel/hierarchy loading without a premium connector (D-1); until then, manual entry + maker-loaded directory stand.
- [ ] T078 [DEFERRED] Define the committee/DTD/applicant access model — M365 groups + SharePoint permissions (OI-7) — required to *verify* US4, US11, US14 (Constitution VI). Likely a `/speckit-clarify` or dedicated design pass.
- [ ] T079 [DEFERRED] Design the retention/archive move for closed cycles (`APPLICATIONS_ARCHIVE` family, R7) — build after a cycle can close; never deletes in-window (Constitution VII).
- [ ] T080 [DEFERRED] Obtain Appendix B (D-2) and replace TBD choice values (competencies, ECQs, statuses) in `_CHOICES.md`; do not invent values (Constitution I).

---

## Phase 17: Polish & Cross-Cutting Concerns

- [ ] T081 [P] Full accessibility sweep across all screens; confirm the Power Apps checker is clean app-wide and that every colour pair meets WCAG AA per `build/theme/theme.md` (Constitution V).
- [ ] T082 [P] Verify delegation app-wide: every gallery is `CycleID`-scoped and delegation-warning-free at multi-cycle volume (Constitution III, R2).
- [ ] T083 [P] Confirm PowerLibs component reuse and project-convention renames across all screens; justify any bespoke control (Constitution VIII).
- [ ] T084 **[MAKER]** Run the full `quickstart.md` end-to-end validation across the value stream; record verified/held per item.

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (P1)** → no dependencies.
- **Foundational (P2 — lists)** → after Setup; **blocks all screens**. T021 (maker creates lists) gates every story.
- **Story phases** → after Foundational. Ordered by **build practicality** (data must exist), which differs from raw spec priority:
  - Admin data screens first: US6 → US7 → US8 → US9 (US9 depends on US8's catalog).
  - Applicant value stream: US1 → US2 → US3 → US4 → US5 → US11.
  - Cross-cutting: US12 (extends US1), US13, US14.
- **Deferred (Phase 16)** → tracked, not built.
- **Polish (Phase 17)** → after desired stories complete.

### Why build order ≠ pure priority

US6 is P1 but several P2 admin stories (US7–US9) are sequenced early because applicants and committees
have nothing to act on until programs, criteria, and sheets exist. All P1 value-stream stories still
land before the P2 tail (US11–US14). Independence is preserved where the domain allows; the value
stream is inherently sequential (noted in spec.md scope).

### Story dependency notes

- US9 → US8 (catalog before sheets). US1 → US6+US7. US2 → US1. US3 → US2. US4 → US3+US9+In Review.
  US5 → US4. US11 → US5. US12 → US1+US3. US14 embeds into US2/US3/US4 hosts.

---

## Parallel Opportunities

- **Setup**: T002, T003 in parallel.
- **Foundational**: T004–T018 (one list file each) are all `[P]` — parallelizable; T019–T020 follow.
- **Within a story**: screen-authoring tasks for distinct `.yaml` files are `[P]`; guard/logic tasks
  that edit the same screen file are sequential.
- **Across stories**: once the lists exist (T021), independent stories can be authored in parallel by
  different makers, respecting the story dependency notes above.

### Parallel example — Foundational lists

```text
Author build/lists/CYCLES.md
Author build/lists/PROGRAMS.md
Author build/lists/APPLICATIONS.md
Author build/lists/COMMITTEE_SCORES.md
... (T004–T018 together)
```

---

## Implementation Strategy

### MVP first (your directive: lists + first screens)

1. Phase 1 Setup → Phase 2 Foundational (all list definitions + maker creates lists).
2. Phase 3 US6 (cycles) → Phase 7 US1 (submit).
3. **STOP and VALIDATE**: open a cycle, submit an application end-to-end (quickstart). This is the
   first demonstrable slice and directly satisfies "lists + screens first."

### Incremental delivery

Add admin (US7–US9) → complete the value stream (US2→US5) → P2 tail (US11–US14) → resolve deferred
seams (Phase 16) → polish (Phase 17). Each story is validated manually before the next.

---

## Notes

- `[MAKER]` tasks are manual transcription/verification steps — the agent does not perform or mark
  them (Constitution IV). All other tasks produce `build/` artifacts.
- No test tasks: nothing is machine-testable; `quickstart.md` is the executable validation.
- `[DEFERRED]` tasks are tracked seams, intentionally out of scope for this build pass.
- Verify gates on US4/US11/US14 rest on the OI-7 access model (Constitution VI) — build is allowed,
  *verified* status is not, until that model exists.
