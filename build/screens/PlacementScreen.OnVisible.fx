// PlacementScreen — the SCREEN's OnVisible.
//
// Paste into the SCREEN's OnVisible property. No leading '=' — Studio's
// formula bar supplies it. Delete these // lines before pasting.
//
// Rebuild started 2026-08-11. Only the state the new tab bar needs is set
// here; the prior locSelectedAppPL / locPlacementModalPL / etc. were tied
// to the cleared master-detail layout and are re-added when their controls
// are re-added.
//
// colTabsPL: two fixed rows (All Applicants, Not Selected) plus one row
// per Active program. Negative ids for the fixed rows so they cannot
// collide with a PROGRAMS.ID. locTabPL seeds on the first tab (-1).

UpdateContext({
    locCyclePL:   LookUp(CYCLES, State.Value = "Open"),
    locTabPL:     -1,
    // Sort state for the All Applicants gallery. Column is a SharePoint
    // InternalName so SortByColumns delegates. Blank = default (unsorted).
    locSortColPL: "",
    locSortAscPL: true,
    // Sort state for the per-program tab gallery. Column is a colProgRowsPL
    // field name (local collection, so no delegation concern). Shared across
    // program tabs so switching tabs keeps the last sort.
    locSortColProgPL: "",
    locSortAscProgPL: true,
    // Schema anchor: LookUp(APPLICATIONS, ID = -1) returns a Blank-but-typed
    // record so downstream .field reads type-check before the first row click.
    locSelectedAppPL: LookUp(APPLICATIONS, ID = -1)
});
ClearCollect(colTabsPL,
    { id: -1, label: "All Applicants", programId: Blank() },
    { id: -2, label: "Not Selected",   programId: Blank() });
ForAll(
    Sort(Filter(PROGRAMS, State.Value = "Active"), ProgramName) As p,
    Collect(colTabsPL,
        { id:        p.ID,
          label:     p.Abbreviation,
          programId: p.ID }));
// Per-applicant placement options. Rows: two fixed ("" and "Not Selected")
// followed by each program the applicant applied to (Distinct guards against
// multi-option applications; Sort orders alphabetically after the fixed rows).
// The dropdown filters this by appId — a plain Filter is cheap; the union
// pattern (Ungroup, table concat) breaks on Items with only nested columns.
Clear(colAppOptsPL);
ForAll(
    Filter(APPLICATIONS, CycleID.Id = locCyclePL.ID) As app,
    Collect(colAppOptsPL,
        { appId: app.ID, label: "" },
        { appId: app.ID, label: "Not Selected" });
    Collect(colAppOptsPL,
        Sort(
          ForAll(
            Distinct(
              Filter(APPLICATION_PROGRAM_CHOICES,
                     ApplicationID.Id = app.ID),
              ProgramID.Id) As d,
            { appId: app.ID,
              label: LookUp(PROGRAMS, ID = d.Value).Abbreviation }),
          label))
);
// Persisted placement state per applicant, resolved to a single label the
// dropdown Default can echo without another LookUp per row.
//   label:            "Not Selected" / <program abbreviation> / ""
//   placedProgramId:  PROGRAMS.ID of the placement, Blank when unplaced
// Both are patched together by the All Applicants dropdown AND the per-program
// toggle so switching between them stays consistent.
// PLACEMENTS list retired 2026-08-11 — placement is two lookups on APPLICATIONS.
Clear(colAppPlacementPL);
ForAll(
    Filter(APPLICATIONS, CycleID.Id = locCyclePL.ID) As app,
    Collect(colAppPlacementPL, {
        appId: app.ID,
        label: Switch(true,
                   app.PlacementOutcome.Value = "Not Selected", "Not Selected",
                   Not(IsBlank(app.PlacementProgramID.Id)),
                      LookUp(PROGRAMS, ID = app.PlacementProgramID.Id).Abbreviation,
                   ""),
        placedProgramId: app.PlacementProgramID.Id
    })
);
// Per-program tab rows: one row per (application, program) an applicant
// applied to, denormalised with the applicant fields the gallery displays.
// Filtered in Items by programId = locTabPL. Distinct guards against HPP
// showing twice when an applicant ranked two options under the same program —
// score is per (app, program) so both rows carry the same FinalScore.
Clear(colProgRowsPL);
ForAll(
    Filter(APPLICATIONS, CycleID.Id = locCyclePL.ID) As app,
    Collect(colProgRowsPL,
        ForAll(
            Distinct(
                Filter(APPLICATION_PROGRAM_CHOICES,
                       ApplicationID.Id = app.ID),
                ProgramID.Id) As d,
            With(
                { ch: LookUp(APPLICATION_PROGRAM_CHOICES,
                             ApplicationID.Id = app.ID,
                             ProgramID.Id = d.Value) },
                { appId:             app.ID,
                  programId:         d.Value,
                  ApplicantName:     app.ApplicantName,
                  JobTitle:          app.JobTitle,
                  Grade:             app.Grade,
                  Location:          app.Location,
                  FinalScore:        ch.FinalScore,
                  PercentOfPossible: ch.PercentOfPossible })))
)

