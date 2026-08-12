# UI Contract — Screen Inventory, LDP Application Phase I

> **`EMPLOYEE_DIRECTORY` withdrawn 2026-07-26.** Personnel and supervisor-chain data comes from an existing system of record (D-1). References to the interim list below are superseded; see `build/lists/EMPLOYEE_DIRECTORY.md`.
>
> **`COMMITTEE_SCORES` retired 2026-08-07** (see `_SCHEMA.md`). **`PLACEMENTS` retired 2026-08-11** — final placement is `APPLICATIONS.PlacementProgramID` / `PlacementOptionID`. `build/screens/` is the source of truth for screen bindings.

**Feature**: `001-ldp-phase-i` | **Date**: 2026-07-25

The canvas app's "interface contract": every screen, its purpose, the lists it binds, the PowerLibs
components it is assembled from, its required states, and its RQ/UC/FR anchors. Screens are **built
from PowerLibs components** (Constitution VIII), **classic controls only** (Constitution II), each
component **renamed to project convention** on transcription.

## Global rules (apply to every screen)

- **Naming (Constitution V):** screen names are plain language, include spaces, end with "Screen"
  (screen readers announce them). Control names: camel case, 3-char type prefix, unique across the
  app; reused controls take a short screen suffix (e.g., `galApplicationsDTD`).
- **Accessibility (Constitution V):** every meaningful control carries an accessible label; the
  Power Apps accessibility checker MUST be clean before a screen is *verified*.
- **Delegation (Constitution III):** every gallery filters by an indexed, `CycleID`-scoped predicate
  first (see data-model.md indexes). No screen loads an unfiltered list.
- **Confidentiality (Constitution VI):** hiding/disabling a control is **not** access control. Who
  may see each screen's data is enforced by the SharePoint permission model (**OI-7, deferred**).
  Committee-scoring and change-history screens MUST NOT be *verified* until that model exists.
- **Component source:** discover components via the PowerLibs MCP before building; prefer a library
  component over primitives; justify any bespoke control in tasks (Constitution VIII).
- **Colour & type:** reference `ColorPalette.*` and `Typography.*` from
  [`build/theme/theme.md`](../../../build/theme/theme.md) (set in `App.OnStart`); never hardcode a
  colour, font, size, or weight. Default font `Open Sans`. Classic `ColorPalette`/font path only —
  modern/Creator Kit themes are excluded (Constitution II). Honour the theme's AA rules (status text
  uses `*Text` tokens; `TextMuted` is never meaningful text; body ≥ 11pt canvas).

## Component palette (PowerLibs — discover exact components at build)

App shell / bottom-nav or side-menu; header/breadcrumb; responsive form container; labeled input,
dropdown, date picker, numeric input; gallery (list) + detail pane; file attachment control; wizard/
section stepper; slide-out panel; status badge/pill; primary/secondary buttons; confirmation dialog;
toast/notification banner; empty-state and loading-state blocks; data table.

## Required states per screen

Unless noted, each screen defines: **loading**, **empty**, **error/failed-write**, and (for forms)
**invalid/incomplete** states — per the spec's edge cases.

---

## A. Public & applicant

### 1. Landing Screen  *(public)*
- **Anchors:** RQ101–103, FR-051; US13.
- **Binds:** `CYCLES` (current), `PROGRAMS`, `PROGRAM_OPTIONS`.
- **Components:** header, cycle-state banner (Scheduled/Open/Closed/In Review content), program info
  cards, supporting-info sections (eligibility guidance, FAQ, contact, prior-cohort outcomes),
  primary "Start / Resume Application" CTA (auth-gated).
- **States:** content varies by cycle state; CTA disabled when not Open (with explanation).

### 2. Home Screen  *(authenticated router)*
- **Anchors:** RQ104, FR-052.
- **Binds:** M365 identity/role (access model OI-7 — deferred).
- **Components:** role-aware workspace tiles routing to Applicant / Supervisor / DTD / Committee.
- **Note:** role resolution is a **seam** until the access model is defined.

### 3. Application Screen  *(applicant; sectioned, free navigation)*
- **Anchors:** RQ105–108, FR-004–010, FR-006a; US1, US12.
- **Binds:** `APPLICATIONS`, `APPLICATION_PROGRAM_CHOICES`, `PROGRAM_OPTIONS`, `EMPLOYEE_DIRECTORY`
  (read, seam), attachments.
- **Sections (navigable in any order):** Personnel · Program Selections (rank 1–3) · Competencies &
  ECQs (3 OPM + 3 technical + 4 ECQ) · Supporting Documents (resume, statement, appraisal) · Latest
  Performance Rating (numeric) · Review & Submit.
- **Components:** section stepper (non-blocking), form container, attachment control, program-option
  **slide-out details panel** (RQ108), incompleteness indicators (non-blocking), submit with
  whole-application validation.
- **States:** Draft save/resume; read-only when cycle Closed (Draft) or In Review (submitted);
  personnel-change accept/decline prompt (seam); duplicate-application block.
- **Delegation:** all lookups scoped to active `CycleID` + `ApplicantEmail`.

---

## B. Supervisor

### 4. Supervisor Queue Screen
- **Anchors:** RQ015–017, RQ022; US2.
- **Binds:** `APPLICATIONS` filtered by `RoutingStage` ∈ {Pending First Line, Pending Second Line}
  and the signed-in supervisor's email (snapshot fields).
- **Components:** queue gallery, status pills, open-to-review action (view-only link).

### 5. Supervisor Endorsement Screen
- **Anchors:** RQ018–025, FR-013–016; US2.
- **Binds:** `APPLICATIONS` (view-only), `SUPERVISOR_ENDORSEMENTS`, `APPLICATION_PROGRAM_CHOICES`,
  attachments, prior first-line decision (for second line).
- **Components:** read-only application detail, decision control (Approve/Disapprove), **required**
  disposition statement, **recommended-options** field (advisory; RQ023/UI note), first-line
  decision panel (second-line view).
- **States:** block record without statement; advance regardless of decision.

---

## C. DTD workspace

### 6. DTD Validation Queue Screen
- **Anchors:** RQ026–029, FR-017–018, FR-012a; US3.
- **Binds:** `APPLICATIONS` filtered by `RoutingStage` ∈ {Pending Validation, Held For Alternate}
  and `Status = Incomplete` (follow-up list).
- **Components:** queue gallery, Incomplete follow-up list, **"Designate alternate second-line
  reviewer"** action for Held-For-Alternate items (FR-012a) writing `AlternateSecondLineEmail`.

### 7. DTD Application Review Screen  *(validate / edit)*
- **Anchors:** RQ030–032, FR-017–019; UC-2.2.
- **Binds:** `APPLICATIONS` (editable by DTD), attachments, `CHANGE_HISTORY`.
- **Components:** editable detail, attach-missing-document, Mark Complete / Mark Incomplete, change-
  history panel (see #14).
- **States:** advance to committee on Complete; hold + list on Incomplete; re-validation of modified
  apps (RevalidationFlag).

### 8. Selection And Placement Screen
- **Anchors:** RQ045–054, FR-027–030, RQ119; US5.
- **Binds:** `COMMITTEE_SCORES` (ranked, `Rank`, `PercentOfPossible`), `APPLICATION_PROGRAM_CHOICES`,
  `SUPERVISOR_ENDORSEMENTS` (recommendations), `PLACEMENTS`.
- **Components:** per-program ranked gallery (rank, %-of-possible, preferences, recommendations,
  placement status), place-into-option action, transfer-on-conflict, remove-placement, **Finalize
  Cohort**.
- **States:** already-placed indicator + transfer; finalize locks placements, marks unplaced
  not-selected; revisions allowed pre-finalize.
- **Delegation:** pool scoped by `CycleID` + `ProgramID`; reads stored `Rank` (R2).

### 9. Cohort Disposition Screen
- **Anchors:** RQ063–071, FR-034–037; US11.
- **Binds:** finalized `APPLICATIONS`/`PLACEMENTS`, `NOTIFICATIONS`, `CHANGE_HISTORY`.
- **Components:** cohort list with notified status, select-individual / select-all, send action
  (writes `NOTIFICATIONS`; **flow sends** — seam), sent/failed indicators, resend-with-warning.
- **States:** nothing disclosed pre-finalize; per-applicant outcome; failures remain not-notified.

---

## D. Committee  *(verification gated on OI-7 access model)*

### 10. Committee Program Pool Screen
- **Anchors:** RQ033, RQ043; US4.
- **Binds:** `APPLICATIONS` for the program's pool (selected program or any of its options, once
  each), scoring status from `COMMITTEE_SCORES`.
- **Components:** pool gallery with scored/not-scored status.

### 11. Committee Scoring Screen
- **Anchors:** RQ034–040, RQ044, RQ100, RQ119, FR-021–026; US4.
- **Binds:** `APPLICATIONS` (full, view-only), attachments, `SUPERVISOR_ENDORSEMENTS`, DTD
  determination, published `RATING_SHEETS` + `RATING_CRITERIA` + `CRITERION_ANCHORS`,
  `COMMITTEE_SCORES`.
- **Components:** application detail, rating sheet with **fixed 0/1/3/5 anchor choice** per criterion
  (rejects off-anchor — R4), running sum, save (retains across sessions), rank-on-complete.
- **States:** scoring blocked until sheet Published and cycle In Review; ties reflected not broken.

---

> **Screen renames — as built, 2026-07-26.** The app uses shorter names than this
> contract for four screens. The app's name is authoritative for `Navigate()`:
>
> | This contract | As built in the app |
> |---|---|
> | *(no entry)* | `Admin Dashboard Screen` — new, no requirement anchor |
> | DTD Validation Queue Screen | `DTD Applications Screen` |
> | Selection And Placement Screen | `Placement Screen` |
> | Cohort Disposition Screen | `Notification Screen` |
> | *(no entry)* | `Competencies Screen` — new; no data layer yet, see D-2 |

## E. Administration (DTD)

### 12. Program Options Screen
- **Anchors:** RQ072–074, FR-038; US7. **Binds:** `PROGRAMS`, `PROGRAM_OPTIONS`.
- **Components:** program grouping, option CRUD form (all attributes), required-field block.

### 13. Application Cycles Screen
- **Anchors:** RQ075–081, FR-039–041; US6. **Binds:** `CYCLES`.
- **Components:** cycle CRUD, three date pickers, state transition controls; guards: reject bad
  dates, block second Open cycle (R6).

### 14. Change History  *(panel/component, reused on application records)*
- **Anchors:** RQ093–095, FR-049; US14.
- **Binds:** `CHANGE_HISTORY` by `ApplicationID`.
- **Components:** history list (what/who/when). **Withheld from applicants** — enforced at the
  permission layer (OI-7, deferred), not by hiding the control.

### 15. Rating Sheets Screen
- **Anchors:** RQ082–092, RQ117–118, FR-042–045; US9. **Binds:** `RATING_SHEETS`, `RATING_CRITERIA`,
  `CRITERION_CATALOG`.
- **Components:** per-program/per-cycle sheet builder, criterion picker (Published + in-window only),
  version list (immutable), publish/unpublish (zero-scores guard), passed-end-date flag + publish
  block.

### 16. Criterion Catalog Screen
- **Anchors:** RQ109–118, FR-046–048; US8. **Binds:** `CRITERION_CATALOG`, `CRITERION_ANCHORS`.
- **Components:** criterion CRUD (name, description, four fixed anchors + optional examples),
  Draft/Publish, start/end dates; block publish unless all four anchors present; no edit once
  Published.

---

## Screens vs. deferred seams

| Screen | Depends on deferred seam | Buildable now? |
|---|---|---|
| Application Screen (personnel autofill) | D-1 personnel load | Yes — bind to `EMPLOYEE_DIRECTORY` + manual entry; loading deferred. |
| Home Screen (role routing) | OI-7 access model | Shell yes; role gating deferred. |
| Supervisor/DTD/Cohort (sends) | Notification flows | Screens write `NOTIFICATIONS`; sending deferred to flows. |
| Committee Pool / Scoring, Change History | OI-7 access model | Build yes; **verify** blocked until permission model defined (Constitution VI). |

## Build order (matches plan work-sequencing & spec priorities)

1. Admin first (data must exist): **13 Cycles → 12 Program Options → 16 Criterion Catalog → 15 Rating
   Sheets.**
2. Applicant value stream: **1 Landing → 3 Application → 4/5 Supervisor → 6/7 DTD Validation.**
3. Evaluation/selection: **10/11 Committee → 8 Placement → 9 Disposition.**
4. Cross-cutting: **2 Home**, **14 Change History** panel — integrated as their host screens land.
