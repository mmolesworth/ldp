# Phase 0 Research — LDP Application Phase I

**Feature**: `001-ldp-phase-i` | **Date**: 2026-07-25

Plan-level decisions that resolve the spec's dependencies/open items enough to define the lists and
screens. Each entry: **Decision → Rationale → Alternatives considered.** Integration items that the
directive defers are recorded as **seams** (decided in principle; build sequenced later).

---

## R1 — Personnel population & supervisor hierarchy without a premium connector (D-1)

> **`EMPLOYEE_DIRECTORY` withdrawn 2026-07-26.** Personnel and supervisor-chain data comes from an existing system of record (D-1). References to the interim list below are superseded; see `build/lists/EMPLOYEE_DIRECTORY.md`.

**Decision.** Introduce a maker-maintained SharePoint list `EMPLOYEE_DIRECTORY` (email → Name,
Location, Grade, Job Series, Job Title, FirstLineSupervisorEmail, SecondLineSupervisorEmail). The
app reads personnel and the supervisory chain from it by delegable lookup on email. Loading/
refreshing this list is done by the **maker outside the app** (manual import or a standard,
non-premium refresh) and is **deferred** in this pass. Manual entry remains the fallback (RQ003).
At submission, the applicant's first-/second-line supervisor emails are **captured as a snapshot**
onto the `APPLICATIONS` item (resolves the snapshot-vs-live question in D-1).

**Rationale.** Keeps the app strictly within Constitution II (no premium connector — the app only
reads a SharePoint list). A submission-time snapshot makes routing deterministic and auditable and
survives later directory changes; it also composes with FR-012a (DTD-designated alternate).

**Alternatives considered.** (a) HR Links live via a connector — rejected: the standard path is a
premium connector, forbidden by Constitution II. (b) Live lookup at each routing step — rejected:
routing would shift if the directory changes mid-review; harder to audit. (c) Office365Users
connector for manager chain — rejected: returns the manager graph but not NCUA's LDP first/second-
line semantics reliably, and couples routing to a live directory.

---

## R2 — Delegation posture for pool ranking and completeness (Constitution III)

**Decision.** Every query is `CycleID`-scoped and delegable on indexed columns. The three inherently
set-wide operations — sort a pool by `FinalScore`, detect "all applicants in the pool scored," and
compare percent-of-possible across pools — operate on a **single program pool within one cycle**
(bounded to tens of rows) and are performed after a delegable `CycleID`+`ProgramID` filter narrows
the set below the row limit. Ranking writes `Rank` back to `COMMITTEE_SCORES`/the application so the
placement screen reads a stored rank (no live re-sort of a large set).

**Rationale.** The non-delegable ceiling of canvas-over-SharePoint bites on unfiltered sorts. A
pool is small by construction; narrowing by cycle+program first keeps every screen delegable up to
the point where only a small, safe set remains.

**Alternatives considered.** (a) Sort the whole scores list client-side — rejected: non-delegable
over multi-cycle volume. (b) Collections holding all scores — rejected: violates "no design assumes
single-cycle size." (c) Compute rank live on the placement screen — rejected: repeated non-delegable
sorts; storing `Rank` at ranking time is cheaper and auditable.

---

## R3 — Immutable rating-sheet versioning in SharePoint (RQ087–092, UC-4.3)

**Decision.** Model versions as **rows**, not edits. Each save inserts a new `RATING_SHEETS` row
(`Version` n+1) and flips `IsCurrent`; prior rows are never updated except the `IsCurrent` flag.
Selected criteria are child rows in `RATING_CRITERIA` keyed to the version's `ID`. Publish sets
`State = Published` and freezes the row; unpublish is permitted only when zero `COMMITTEE_SCORES`
rows reference that sheet version.

**Rationale.** Append-as-row gives immutable history for free in SharePoint and keeps prior versions
inspectable (RQ089) without a versioning engine. The zero-scores guard enforces UC-4.3 ext 4b.

**Alternatives considered.** SharePoint list item versioning — rejected: not queryable as first-
class rows, awkward to display prior versions in-app, and not delegable.

---

## R4 — Committee scoring storage (hybrid) (RQ036–040, RQ119)

**Decision.** Keep the data model's hybrid: `FinalScore` and `PercentOfPossible` as queryable
Numbers on `COMMITTEE_SCORES`; the per-criterion 0/1/3/5 breakdown as JSON in a memo column
(`CriterionScores`). Anchor validation (only 0/1/3/5) is enforced in the scoring screen's input
control (a fixed choice set), so no off-anchor value can be entered. `FinalScore` is the sum of the
selected anchors; `PercentOfPossible = FinalScore / (5 × criteria count)`.

**Rationale.** Queryable numbers keep ranking/comparison delegable; JSON avoids a wide, per-criterion
column set that varies by sheet. A fixed choice input makes RQ037 unbreakable at the UI and keeps the
stored value clean.

**Alternatives considered.** One row per criterion score — rejected: multiplies row volume and
complicates the "pool fully scored" check. Free-numeric input with validation — rejected: allows an
off-anchor value to exist transiently; a fixed choice set is stronger.

---

## R5 — Endorsement routing state, incl. no-second-line (FR-012, FR-012a; OI-6)

**Decision.** Add a `RoutingStage` choice on `APPLICATIONS` to track the endorsement path
independent of the coarse `Status`: `Pending First Line → Pending Second Line → Held For Alternate →
Pending Validation → In Committee → Placed/Not Selected`. Store `FirstLineSupervisorEmail`,
`SecondLineSupervisorEmail`, and `AlternateSecondLineEmail` (snapshot at submission; alternate set by
DTD). When no second-line email exists at submission, `RoutingStage = Held For Alternate` and the
application surfaces on the DTD queue for alternate designation (FR-012a); once designated, it routes
as a normal second-line endorsement.

**Rationale.** A dedicated stage field keeps routing legible and delegable (filter queues by
`RoutingStage`) without overloading `Status`. Snapshot emails make "who is assigned" explicit before
anyone acts (the data model otherwise had no field naming the assigned supervisor).

**Alternatives considered.** Overload `Status` with routing sub-states — rejected: conflates
lifecycle with routing and complicates gallery filters. Derive routing from `SUPERVISOR_ENDORSEMENTS`
row presence — rejected: can't represent "held for alternate," and needs counting child rows
(non-delegable-ish) on every queue load.

---

## R6 — Enforcing one Open cycle & valid cycle dates (RQ079, RQ080)

**Decision.** Enforce "at most one Open cycle" at the **transition action** on the Cycles screen:
before setting a cycle Open, a delegable `CountRows(Filter(CYCLES, State="Open"))`-style guard must
return zero. Date consistency (close ≥ open, decision ≥ close) is validated in the same action before
write. These are app-layer guards; they are not security boundaries.

**Rationale.** SharePoint has no cross-item uniqueness constraint; the invariant is cheap to enforce
at the single point of transition. The filtered count is tiny and delegable.

**Alternatives considered.** A flow/trigger enforcing it — rejected: adds a deferred flow dependency
for a guard the screen can do synchronously. A singleton "current cycle" list — rejected: loses cycle
history and the four-state model.

---

## R7 — Retention & archive for closed cycles (Constitution VII)

**Decision.** Retain applications and their attachments seven years from cycle close. Archive is a
**move, not a delete**: closed-cycle applications (and their child rows) are relocated to parallel
archive lists (e.g., `APPLICATIONS_ARCHIVE`) out of the hot query path, preserving attachments, and
never deleted inside the window. Active screens query only live lists (already `CycleID`-scoped);
a separate retrieval path reads archives. **Building** the archive move is sequenced after a cycle
can close; this pass only fixes the posture and keeps attachments on the item so they travel with it.

**Rationale.** Keeps the hot path small (Constitution III) while meeting the records + PII obligation
(Constitution VII). Native attachments move with the item, so the appraisal/resume/statement travel
with the archived record.

**Alternatives considered.** Delete-after-window automation — rejected: must not delete inside seven
years, and closed cycles sit in-window for years. Keep everything hot forever — rejected: fails the
volume principle as cycles accumulate.

---

## R8 — Duplicate-application prevention & draft handling (RQ014, RQ010–011)

**Decision.** Prevent a second application per applicant per cycle with a delegable guard on
`Filter(APPLICATIONS, CycleID=active And ApplicantEmail=me)` at start/submit; a returning applicant
is routed to their existing Draft (resume) or blocked if already Submitted. A Draft opens read-only
and blocks submit when the cycle is Closed (RQ011).

**Rationale.** Same one-point-of-enforcement pattern as R6; cheap, delegable, no flow needed.

**Alternatives considered.** Enforce via unique column — rejected: SharePoint uniqueness is
per-column tenant-wide, not per-cycle+email composite.

---

## Deferred integration seams (designed, not built this pass)

- **Notifications & reminders (UC-5.1/5.2; FR-031–033, RQ055–062).** Built as **Power Automate flows
  by the maker** (Constitution II/IV). Reminders **repeat each interval** until action (resolved
  OI-3). The app writes to `NOTIFICATIONS`; flows do the sending. Agent will produce flow
  construction instructions in a later pass; no deployable flow artifact is produced.
- **OI-7 committee/DTD/applicant access model.** SharePoint permissions + M365 groups scope who reads
  which applications/scores and hide change history from applicants (Constitution VI). **Must be
  defined before the committee-scoring and change-history screens are verified.** Deferred at the
  maker's direction.
- **D-2 source appendices.** Choice-field enumerations (competencies, ECQs, statuses) and the full
  Appendix A field set are needed to finalize choice columns; where unknown, `data-model.md` marks
  the choice set **TBD (Appendix B)**.
