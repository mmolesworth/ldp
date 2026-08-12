// CompetenciesScreen — the SCREEN's OnVisible.
//
// Paste into the SCREEN's OnVisible property. No leading '=' — Studio's
// formula bar supplies it. Delete these // lines before pasting.

ClearCollect(colComps, COMPETENCIES);
ClearCollect(colTypes, COMPETENCY_TYPES);
UpdateContext({
    locTypeID: First(SortByColumns(Filter(colTypes, State.Value = "Active"), "SortOrder", SortOrder.Ascending)).ID,
    locComp: Blank(),
    locCompSort: "CompetencyName",
    locCompAsc: true,
    locCompModal: false,
    locTypeModal: false,
    locConfirmRetire: false,
    locRetireComp: Blank()
})
