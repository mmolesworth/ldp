// ScoringRubricsScreen — the SCREEN's OnVisible.
//
// Paste into the SCREEN's OnVisible property. No leading '=' — Studio's
// formula bar supplies it. Delete these // lines before pasting.

ClearCollect(colPrograms, PROGRAMS);
ClearCollect(colCatalog, CRITERION_CATALOG);
ClearCollect(colSheets, RATING_SHEETS);
ClearCollect(colRatingCrit, RATING_CRITERIA);
UpdateContext({
    locProgram: First(Sort(Filter(colPrograms, State.Value = "Active"), ProgramName)),
    locNewDraft: false,
    locDirty: false,
    locWarn: false,
    locWarnTitle: "",
    locWarnMsg: ""
});
UpdateContext({
    locVersion: First(SortByColumns(Filter(colSheets, ProgramID.Id = locProgram.ID, State.Value = "Published"), "SheetVersion", SortOrder.Descending))
});
ClearCollect(colSheetCrit,
    ForAll(Filter(colRatingCrit, RatingSheetID.Id = locVersion.ID) As rc,
        { CritID: rc.CatalogCriterionID.Id,
          CritName: LookUp(colCatalog, ID = rc.CatalogCriterionID.Id).CriterionName,
          CritEnd: LookUp(colCatalog, ID = rc.CatalogCriterionID.Id).EndDate,
          SortOrder: rc.DisplayOrder }))
