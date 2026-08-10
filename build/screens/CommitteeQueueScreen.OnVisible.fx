// CommitteeQueueScreen — the SCREEN's OnVisible.
//
// Select the SCREEN in the tree view, not a control on it, and paste this into
// OnVisible in the properties pane. No leading '=' — Studio's formula bar
// supplies it. Delete these // lines before pasting.
//
// EXTRACTED from the header comment in CommitteeQueueScreen.yaml, which stays the source of
// truth — including the Phase I one-Active-committee assumption.

UpdateContext({
    locCommittee: LookUp(COMMITTEES, State.Value = "Active")
});
UpdateContext({
    locProgram: LookUp(PROGRAMS,      ID = locCommittee.ProgramID.Id),
    locCycle:   LookUp(CYCLES,        ID = locCommittee.CycleID.Id),
    locSheet:   LookUp(RATING_SHEETS, ID = locCommittee.RatingSheetID.Id)
});
// Hydrate the pool ONCE. Outer Filter uses indexed ProgramID (delegable);
// the join to APPLICATIONS is a per-row LookUp inside ForAll (non-delegable
// but bounded by the outer Filter). Screens read from colPoolCQ only.
ClearCollect(colPoolCQ,
    ForAll(
        Filter(APPLICATION_PROGRAM_CHOICES,
               ProgramID.Id = locCommittee.ProgramID.Id) As ch,
        With({app: LookUp(APPLICATIONS, ID = ch.ApplicationID.Id)},
            { Choice:        ch,
              App:           app,
              ApplicantName: app.ApplicantName,
              Grade:         app.Grade,
              SubmittedDate: app.SubmittedDate,
              FinalScore:    Coalesce(ch.FinalScore, 0),
              InPool:        And(app.CycleID.Id = locCommittee.CycleID.Id,
                                 app.ReviewStage.Value = "Committee Review"),
              IsScored:      And(Not(IsBlank(ch.CommitteeID)),
                                 ch.CommitteeID.Id = locCommittee.ID) })));
// Split into the two galleries' sources. Filter locally on the collection so
// the galleries themselves stay simple and don't re-query.
ClearCollect(colToScoreCQ, Filter(colPoolCQ, InPool, Not(IsScored)));
ClearCollect(colScoredCQ,  Filter(colPoolCQ, IsScored))
