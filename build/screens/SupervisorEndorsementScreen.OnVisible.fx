// SupervisorEndorsementScreen — the SCREEN's OnVisible.
//
// Select the SCREEN in the tree view, not a control on it, and paste this into
// OnVisible in the properties pane. No leading '=' — Studio's formula bar
// supplies it. Delete these // lines before pasting.
//
// EXTRACTED from the header comment in SupervisorEndorsementScreen.yaml, which stays the source of
// truth — including why the third block is duplicated in drpQueueSE.OnChange.

ClearCollect(colSupAppsSE,
    ForAll(
        Filter(APPLICATIONS,
            ApplicationStatus.Value <> "Draft",
            ApplicationStatus.Value <> "Withdrawn",
            Or(FirstLineSupervisorEmail = User().Email,
               SecondLineSupervisorEmail = User().Email)) As a,
        { App: a, Label: a.ApplicantName }));
UpdateContext({ locTabSE: 1, locDecisionSE: Blank(),
                locOpenCardSE: Blank(),
                varOpenSupItemSE: Blank(),
                locCompTypeSE: First(SortByColumns(
                    Filter(COMPETENCY_TYPES, State.Value = "Active"),
                    "SortOrder", SortOrder.Ascending)).ID,
                locApp: First(colSupAppsSE).App });
ClearCollect(colSuggestSE, Filter(Table({id: 0, program: "", option: ""}), false));
ClearCollect(colSupDecisionsSE,
    { level: "First Line",  decision: "", comment: "" },
    { level: "Second Line", decision: "", comment: "" });
UpdateContext({
    locMineSE: LookUp(SUPERVISOR_ENDORSEMENTS,
        And(ApplicationID.Id = locApp.ID, SupervisorEmail = User().Email))
})
