// PlacementScreen — the SCREEN's OnVisible.
//
// Paste into the SCREEN's OnVisible property. No leading '=' — Studio's
// formula bar supplies it. Delete these // lines before pasting.

UpdateContext({
    locCyclePL:          LookUp(CYCLES, State.Value = "Open"),
    locPlacementModalPL: false,
    locNotSelModalPL:    false,
    // Schema anchors: LookUp(TABLE, ID = -1) returns a Blank-but-typed
    // record so downstream .field access type-checks even before an
    // interaction populates the variable. Same shape as the OnSelect
    // assignments elsewhere in the tree.
    locSelectedAppPL:    LookUp(APPLICATIONS, ID = -1),
    locPlaceAppPL:       LookUp(APPLICATIONS, ID = -1),
    locPlacePlPL:        LookUp(PLACEMENTS,   ID = -1),
    locNotSelAppPL:      LookUp(APPLICATIONS, ID = -1),
    // locPlaceOptionPL — deliberately NOT initialized here; Studio's
    // type-inference cache refuses to reconcile it with the LookUp
    // assignments elsewhere. Set on first icon-click OnSelect.
    locPlaceProgIdPL:    0,
    locPlaceProgNamePL:  "",
    locNotSelNamePL:     ""
})
