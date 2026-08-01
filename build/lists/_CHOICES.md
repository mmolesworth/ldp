# Choice Sets — LDP Application Phase I

**Generated:** 2026-07-25. Enumerate these when creating the lists. **Do not invent** competency/ECQ/
status values — they are TBD pending Appendix B (D-2, Constitution I).

| List.Column | Values | Source |
|---|---|---|
| `CYCLES.State` | Scheduled, Open, Closed, In Review | RQ076 |
| `APPLICATIONS.ApplicationStatus` | Draft, Submitted, Validated, Withdrawn | validated 2026-07-31 — see below |
| `APPLICATIONS.ReviewStage` | *(blank)*, Pending First-Line, Needs Supervisor Assigned, Pending Second-Line, Pending DTD Validation, Committee Review, Pending Placement, Pending Notification, Complete | R5, revised 2026-07-31 |
| `APPLICATIONS.PlacementOutcome` | Decision Pending, Placed, Not Selected, Placement Declined | added 2026-07-31 |
| `APPLICATIONS.ListedOnIDP` | Yes, No | data-model |
| `APPLICATIONS.AttendedInfoSession` | Yes, No | data-model |
| `SUPERVISOR_ENDORSEMENTS.SupervisorLevel` | First Line, Second Line, Alternate Second Line **[PROPOSED — FR-012a]** | RQ + FR-012a |
| `SUPERVISOR_ENDORSEMENTS.Decision` | Approve, Disapprove | RQ018 |
| `RATING_SHEETS.State` | Draft, Published, Superseded | revised 2026-07-28 — one Published per program |
| `CRITERION_CATALOG.State` | Draft, Published, Retired | RQ112 + Retired added 2026-07-28 |
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

---

## 2026-07-31 — APPLICATIONS: one status column became three

`Status` was recorded here as *"data-model (inferred; validate at build)"*. This is that validation.

**The problem.** One column was carrying three lifecycles that have different owners and advance on
different clocks:

| Old values | Question | Owner |
|---|---|---|
| Draft, Submitted | has the applicant finished? | the applicant |
| Complete, Incomplete | did it pass DTD validation? | DTD |
| Placed, Not Selected | what was the outcome? | DTD, much later |

Sharing a column meant each advance **destroyed** the previous answer. "A complete application that
was not selected" — an ordinary outcome — could not be recorded at all.

**The split is by OWNER**, which is what makes the three genuinely independent rather than three
arbitrary slices of one sequence:

- `ApplicationStatus` — the applicant owns it
- `ReviewStage` — the workflow owns it
- `PlacementOutcome` — DTD owns it, once, at the end

**Complete and Incomplete are gone, and are not replaced.** They were never states the application
sat in; they were the verdict of the validation step. DTD has full control over decisions and
placement, so a completeness problem does not divert the packet — it is captured and the application
continues. The same is true of a supervisor disapproval: `SUPERVISOR_ENDORSEMENTS.Decision` records
it, and `ReviewStage` does not change.

**`ReviewStage` is linear with one detour.** The only branch is at second-line routing:

```
(blank) --submit--> Pending First-Line
                      |
                      +-- second line on record -------> Pending Second-Line ---+
                      |                                                         |
                      +-- none on record --> Needs Supervisor Assigned ---------+
                                               (DTD names one)                  |
                                                                                v
   Pending DTD Validation --> Committee Review --> Pending Placement
                          --> Pending Notification --> Complete
```

Both paths rejoin at `Pending Second Line`; nothing is unreachable and there is one exit.

**`Needs Supervisor Assigned`** replaces `Held For Alternate` **[PROPOSED — FR-012a]**. The old name
described the record's condition; the new one names the action DTD owes. The wait is on DTD to
designate someone, not on the alternate to respond — a distinction that decides whether an admin
chases a supervisor or does something themselves.

The branch is evaluated **after first-line endorsement**, not at submit. The original R5 wording
("empty → routing Held For Alternate") reads as submit-time, but the packet needs the first-line
step either way and `ReviewStage` holds one value at a time.

**Invariants**

1. `ReviewStage` is blank while `ApplicationStatus = Draft`.
2. `PlacementOutcome` is set on LEAVING `Pending Placement` — you cannot notify an applicant
   without knowing what you are telling them. It stays `Decision Pending` before that.
3. Exactly one of the three is the interesting one at any moment — so a screen may collapse them
   into a single label **for display**, but must not store one.

**Still to confirm:** `RevalidationFlag` (FR-050) marks post-submission modification. Nothing in this
split makes it redundant — the applicant can still modify after submitting — but it is worth
re-reading FR-050 against the new `ReviewStage` before the next change.

### 2026-07-31, second revision — explicit labels, and a notification stage

The values were renamed to say what they mean without the reader supplying context, and
`Pending Notification` was added between the decision and the close.

| Was | Now | Why |
|---|---|---|
| Closed | **Complete** | "Closed" did not say WHAT had closed — the cycle? the application? |
| Pending Validation | **Pending DTD Validation** | names who is doing it, against the supervisor steps either side |
| Pending Decision | **Pending Placement** | "which decision" was a real question |
| In Committee | **Committee Review** | "in committee" reads as a place rather than a state |
| Held For Alternate | **Needs Supervisor Assigned** | names the action DTD owes, not the record's condition |
| Pending First Line | **Pending First-Line** | hyphenated only; the term itself is already used by `SUPERVISOR_ENDORSEMENTS.SupervisorLevel` and the `FirstLineSupervisorEmail` column |
| Pending Second Line | **Pending Second-Line** | as above |
| Pending | **Decision Pending** | "Pending" beside a stage list full of "Pending …" carried no information |
| Declined | **Placement Declined** | on its own it did not say who declined what |

**`ApplicationStatus` was deliberately NOT renamed.** "Application Submitted" under a column headed
*Application status* repeats itself, and the prefix would cost width in every pill, filter and list
view. The run-together problem it was meant to solve is in the detail panel, where the three appear
without headers — so the panel labels each segment instead: **Application** Submitted · **Stage**
Pending DTD Validation · **Outcome** Placed.

**`Pending Notification` is a stage, not an outcome.** It answers "have we told them", where the
outcome answers "what was decided". Putting it in `PlacementOutcome` would collapse two facts into
one column again — the exact problem this whole revision exists to fix — and would lose the state
"placed, but not yet notified".

### 2026-07-31 — validation is a STATE of the application, not a flag beside it

`RevalidationFlag` recorded *what happened* (a post-submission edit). It was briefly replaced by a
separate `ValidationStatus` column; that column is now gone too, and validation lives in
`ApplicationStatus` as a fourth value.

    Draft -> Submitted -> Validated
                 ^___________|          an edit drops it back

**Why one column and not two.** DTD's acceptance is not a second axis running alongside the
applicant's progress — it is the next step *in* it. Nothing can be validated without being
submitted, so the two columns could only ever hold four of their eight combinations, and the
other four were nonsense the schema still permitted (a validated draft, a validated withdrawal).
A linear column cannot express those at all.

The objection to folding it in was that a status should not oscillate. It does not: `Validated ->
Submitted` on an edit is a backward transition, the same shape as any workflow that reopens a
record for another look. `Submitted` already means "waiting on DTD", so the queue DTD works is
just a filter on a value that has to exist anyway.

**What it costs.** A later value implies the earlier ones, so anything asking "has this been
submitted?" must accept `Validated` too. Two places on the Landing Screen did, and were changed.
`ApplicationStatus.Value <> "Draft"` — the form's read-only test, used a dozen times — is
unaffected, which is most of why this was cheap.

**This is not `ReviewStage`.** `Pending DTD Validation` is where the packet IS. The two do overlap
while a packet sits at that stage; if that proves confusing in use, the stage is the one to drop,
not the status.

**No `ValidatedBy` / `ValidatedDate`.** The state is the whole record. Add them if "who, and when"
ever becomes a question worth answering.
