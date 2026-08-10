// CommitteeScoreScreen — the SCREEN's OnVisible.
//
// PASTE INTO THE SCREEN'S OnVisible property (Studio: select the Screen in
// the tree view — NOT a control on it — and paste into the OnVisible box).
// No leading '=' — Studio's formula bar supplies it. Delete these // lines
// before pasting.
//
// The Score Screen is opened via Navigate('Committee Score Screen', ...,
// { locChoiceID: ID }) from the Queue Screen. If you "Play from this screen"
// in Studio directly, locChoiceID is Blank and every LookUp cascades to
// Blank — the screen renders empty. Open via the Queue to test.
//
// Why each collection is seeded with Filter(Table({...}), false) BEFORE the
// ForAll loops: it gives Power Fx a stable schema even when the collection
// ends up empty. Otherwise the type-checker infers colAnchorsCS.Score as
// Error, and every anchor card's `And(CritId = ..., Score = 0)` fails at
// design-time with "Incompatible types: Error, Number".

UpdateContext({
    locChoice:        LookUp(APPLICATION_PROGRAM_CHOICES, ID = locChoiceID),
    locCommittee:     LookUp(COMMITTEES, State.Value = "Active"),
    locAppExpandedCS: false,
    locDetailTabCS:   1,
    // Default competency tab: first Active type by SortOrder. Data-driven —
    // reorder rows on the admin Competencies screen to change what lands.
    locCompTypeCS:
        First(SortByColumns(
            Filter(COMPETENCY_TYPES, State.Value = "Active"),
            "SortOrder", SortOrder.Ascending)).ID
});
UpdateContext({
    locApp:     LookUp(APPLICATIONS,   ID = locChoice.ApplicationID.Id),
    locProgram: LookUp(PROGRAMS,       ID = locCommittee.ProgramID.Id),
    locCycle:   LookUp(CYCLES,         ID = locCommittee.CycleID.Id),
    locSheet:   LookUp(RATING_SHEETS,  ID = locCommittee.RatingSheetID.Id)
});

// Schema anchors — empty but strongly typed. Do NOT remove.
ClearCollect(colCritsCS,
    Filter(Table({ CritId: 0, CatId: 0, Name: "", Description: "", Order: 0 }), false));
ClearCollect(colAnchorsCS,
    Filter(Table({ CritId: 0, Score: 0, AnchorText: "", ExampleText: "" }), false));
ClearCollect(colScoresCS,
    Filter(Table({ CritId: 0, Score: 0, Comment: "" }), false));

// Populate colCritsCS from the pinned rating sheet.
ForAll(
    Filter(RATING_CRITERIA, RatingSheetID.Id = locSheet.ID) As rc,
    With({cat: LookUp(CRITERION_CATALOG, ID = rc.CatalogCriterionID.Id)},
        Collect(colCritsCS,
            { CritId:      rc.ID,
              CatId:       cat.ID,
              Name:        Coalesce(cat.CriterionName, ""),
              Description: Coalesce(cat.Description, ""),
              Order:       rc.DisplayOrder })));

// Populate colAnchorsCS — one row per (criterion x anchor score). Two nested
// ForAlls; Power Fx may show a delegation warning but the inner list is small
// (bounded by criteria x 4 anchors) so it runs fine.
ForAll(colCritsCS As c,
    ForAll(Filter(CRITERION_ANCHORS, CatalogCriterionID.Id = c.CatId) As a,
        Collect(colAnchorsCS,
            { CritId:      c.CritId,
              Score:       a.Score,
              AnchorText:  Coalesce(a.AnchorText, ""),
              ExampleText: Coalesce(a.ExampleText, "") })));

// Populate colScoresCS. Blank Score is the "unscored" sentinel that the
// anchor-card selected-state formulas test against — do NOT default to 0
// because 0 is a valid anchor value.
ForAll(colCritsCS As c,
    With({e: LookUp(COMMITTEE_CRITERION_SCORES,
             And(ApplicationProgramChoiceID.Id = locChoice.ID,
                 RatingCriterionID.Id = c.CritId))},
        Collect(colScoresCS,
            { CritId:  c.CritId,
              Score:   If(IsBlank(e), Blank(), e.Score),
              Comment: Coalesce(e.Comment, "") })));

// Start the reviewer on the first criterion. locCritIndex is the positional
// index (1..N) that Prev/Next increments — locCurrentCritCS is the derived
// CritId that every downstream LookUp uses. Kept in sync by the buttons.
UpdateContext({
    locCritIndex:     1,
    locCurrentCritCS:
        First(SortByColumns(colCritsCS, "Order", SortOrder.Ascending)).CritId
})
