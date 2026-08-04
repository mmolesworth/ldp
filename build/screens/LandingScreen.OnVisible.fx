// LandingScreen — the SCREEN's OnVisible.
//
// Select the SCREEN in the tree view, not a control on it, and paste this into
// OnVisible in the properties pane. No leading '=' — Studio's formula bar
// supplies it. Delete these // lines before pasting.
//
// EXTRACTED from the header comment in LandingScreen.yaml, which stays the source of
// truth — including the rationale. Edit there and re-extract.

UpdateContext({
   locCycle: If(IsBlank(LookUp(CYCLES, State.Value = "Open")),
                First(Sort(CYCLES, OpenDate, SortOrder.Descending)),
                LookUp(CYCLES, State.Value = "Open")),
   locFaqOpenLD:    false, locOpenFaqIdLD:   Blank(),
   locNeedOpenLD:   false, locOpenNeedIdLD:  Blank(),
   locDatesOpenLD:  false, locOpenDatesIdLD: Blank(),
   locEligOpenLD:   false, locOpenEligIdLD:  Blank()
});
UpdateContext({
   locApp: LookUp(APPLICATIONS,
             And(CycleID.Id = locCycle.ID, ApplicantEmail = User().Email))
});
ClearCollect(colFaqAnimTriggersLD,   { itemID: 0, timestamp: "" });
ClearCollect(colNeedAnimTriggersLD,  { itemID: 0, timestamp: "" });
ClearCollect(colDatesAnimTriggersLD, { itemID: 0, timestamp: "" });
ClearCollect(colEligAnimTriggersLD,  { itemID: 0, timestamp: "" })
