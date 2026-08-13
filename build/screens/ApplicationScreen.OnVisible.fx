// ApplicationScreen — the SCREEN's OnVisible.
//
// Select the SCREEN in the tree view, not a control on it, and paste this into
// OnVisible in the properties pane. No leading '=' — Studio's formula bar
// supplies it. Delete these // lines before pasting.
//
// EXTRACTED from the header comment in ApplicationScreen.yaml, which stays the source of
// truth — including the rationale. Edit there and re-extract.

Set(gblFormDirty, false);
Set(gblConfirmExitAP, false);
UpdateContext({
    locCycle: If(IsBlank(LookUp(CYCLES, State.Value = "Open")),
                 First(Sort(CYCLES, OpenDate, SortOrder.Descending)),
                 LookUp(CYCLES, State.Value = "Open")),
    locStep: 1,
    locCompTypeAP: First(SortByColumns(
                       Filter(COMPETENCY_TYPES, State.Value = "Active"),
                       "SortOrder", SortOrder.Ascending)).ID
});
UpdateContext({
    locApp: LookUp(APPLICATIONS,
              And(CycleID.Id = locCycle.ID, ApplicantEmail = User().Email))
});
ClearCollect(colAppComps,
    ForAll(Filter(APPLICATION_COMPETENCIES, ApplicationID.Id = locApp.ID) As ac,
        With({ compRec: LookUp(COMPETENCIES, ID = ac.CompetencyID.Id) },
        With({ typeRec: LookUp(COMPETENCY_TYPES, ID = compRec.CompetencyTypeID.Id) },
            { CompId:    ac.CompetencyID.Id,
              CompName:  ac.CompetencyID.Value,
              TypeId:    compRec.CompetencyTypeID.Id,
              TypeName:  compRec.CompetencyTypeID.Value,
              TypeOrder: typeRec.SortOrder }))));
// Program choices. Same shape as colAppComps: source of truth for what the
// applicant has picked, mutated only by explicit Add/Remove/Reorder actions
// on step 2. The Save/Submit handlers diff it against SharePoint. Rank is
// dense (1..N with no gaps); Remove compacts, MoveUp/MoveDown swap ranks.
// HasOptions carries the "this program requires an option" fact so the
// gallery row and the Add-button gate do not each re-query PROGRAM_OPTIONS.
ClearCollect(colProgChoicesAP,
    ForAll(
        SortByColumns(
            Filter(APPLICATION_PROGRAM_CHOICES, ApplicationID.Id = locApp.ID),
            "Rank", SortOrder.Ascending) As ch,
        { Rank:       ch.Rank,
          ProgId:     ch.ProgramID.Id,
          ProgName:   ch.ProgramID.Value,
          OptId:      ch.ProgramOptionID.Id,
          OptName:    ch.ProgramOptionID.Value,
          HasOptions: Not(IsEmpty(Filter(PROGRAM_OPTIONS,
                        ProgramID.Id = ch.ProgramID.Id,
                        State.Value = "Active"))) }))
