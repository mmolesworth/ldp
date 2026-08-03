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
    locDropRank2: false,
    locDropRank3: false,
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
        { CompId:    ac.CompetencyID.Id,
          CompName:  ac.CompetencyID.Value,
          TypeId:    LookUp(COMPETENCIES, ID = ac.CompetencyID.Id).CompetencyTypeID.Id,
          TypeName:  LookUp(COMPETENCIES, ID = ac.CompetencyID.Id).CompetencyTypeID.Value,
          TypeOrder: LookUp(COMPETENCY_TYPES,
                       ID = LookUp(COMPETENCIES,
                              ID = ac.CompetencyID.Id).CompetencyTypeID.Id).SortOrder }))
