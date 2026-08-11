// CriterionCatalogScreen — the SCREEN's OnVisible.
//
// Paste into the SCREEN's OnVisible property. No leading '=' — Studio's
// formula bar supplies it. Delete these // lines before pasting.

ClearCollect(colCrit, CRITERION_CATALOG);
ClearCollect(colAnchors, CRITERION_ANCHORS);
ClearCollect(colRatingCrit, RATING_CRITERIA);
ClearCollect(colSheets, RATING_SHEETS);
UpdateContext({
    locCrit: Blank(),
    locCatSort: "CriterionName",
    locCatAsc: true,
    locCatTab: 1,
    locCatModal: false,
    locConfirmCat: false,
    locRetireCrit: Blank()
})
