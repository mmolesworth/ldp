# APPLICATION_PROGRAM_CHOICES

**Purpose:** An applicant's ranked program selections (join of APPLICATIONS × PROGRAMS),
with the chosen option where the program has any.
**Anchors:** RQ005; UC-1.1.

| Column | Type | Required | Notes |
|---|---|---|---|
| ID | Number | Yes | Identifier. |
| ApplicationID | Lookup (APPLICATIONS) | Yes | Owning application. |
| ProgramID | Lookup (PROGRAMS) | Yes | **The choice.** Stores `PROGRAMS.ID`. |
| ProgramOptionID | Lookup (PROGRAM_OPTIONS) | No | The option chosen under that program. Populated only where the program has active options — HPP today; blank for MDP and NEXT. |
| Rank | Number | Yes | 1 = highest, up to 3. |

**Indexes:** `ApplicationID`, `ProgramID`, `ProgramOptionID`.
**Validation:** one to three rows per application, ranks 1–3, no duplicate rank (FR-004).
**Uniqueness is on the PAIR** (`ProgramID`, `ProgramOptionID`), not on the program. An applicant may
rank HPP more than once with a different option each time. MDP or NEXT twice is still blocked, and
falls out of the same rule without a special case: both rows would be (program, blank).
**An option is mandatory where the program has active options**, and the option picker is hidden
where it has none. That is an Application Screen rule, not a schema constraint — the column stays
optional because most programs genuinely have no option to record.

## Revised 2026-07-31 — the PROGRAM became the choice

`ProgramOptionID` used to be the only program reference, and it was Required. Four consequences:

- **It invented data.** MDP and NEXT have no options, so `Add-LdpProgramOptions.ps1` created an
  "N/A" option per program purely so those programs could be chosen. A schema constraint
  satisfying itself.
- **Every join walked backwards.** `RATING_SHEETS` and `COMMITTEE_SCORES` key on `ProgramID`, so
  matching a choice to a score meant dereferencing the option to its parent first —
  `LookUp(colOptions, ID = ch.ProgramOptionID.Id).ProgramID.Id`, twice per gallery row.
- **The applicant's actual decision was not stored.** Step 2 asks for the program first and the
  option second; only the second half was written.
- **The duplicate guard compared options** when the rule is about program-and-option together.

Migrated by `build/scripts/Update-LdpProgramChoices.ps1`. `PLACEMENTS` had the identical defect and
was fixed in the same run.
