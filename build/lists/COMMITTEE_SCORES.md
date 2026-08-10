# COMMITTEE_SCORES — DEPRECATED 2026-08-07

**Superseded by** `APPLICATION_PROGRAM_CHOICES` (aggregate) and `COMMITTEE_CRITERION_SCORES`
(per-criterion detail). Dropped from `New-LdpSharePointLists.ps1`. Never populated in any
environment, so no migration path is needed.

## Why the split

This list held two things on one row: aggregates (`FinalScore`, `PercentOfPossible`, `Rank`,
`ScoredBy`, `ScoredDate`) and per-criterion detail (`CriterionScores` as JSON in a long text
field). Two problems:

- **Detail rows in a text blob are opaque.** JSON in a long-text column cannot be filtered,
  indexed, or joined. Any per-criterion query — "show me every applicant's Leadership score",
  "which criterion has the widest score spread" — required parsing JSON in Power Fx, which is
  not delegable.
- **The aggregate key duplicated `APPLICATION_PROGRAM_CHOICES`.** That list already had one row
  per (application × program) — the same key this one used. A whole list was orbiting a key that
  already existed.

## The new shape

- `APPLICATION_PROGRAM_CHOICES` gained `CommitteeID`, `FinalScore`, `PercentOfPossible`,
  `ScoredBy`, `ScoredDate`. `Rank` (applicant preference 1–3) was already there; committee rank
  is derived at query time — no column.
- `COMMITTEE_CRITERION_SCORES` is a new list with one row per (choice × criterion), holding
  `Score` (0/1/3/5) and `Comment`.
- `COMMITTEES` is a new list capturing the scoping entity (program × cycle × pinned rubric).

If a SharePoint site was already provisioned with this list from an earlier script run, it can
be deleted manually — nothing reads or writes it.
