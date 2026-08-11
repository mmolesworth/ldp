// AdminDashboardScreen — the SCREEN's OnVisible.
//
// Paste into the SCREEN's OnVisible property. No leading '=' — Studio's
// formula bar supplies it. Delete these // lines before pasting.

UpdateContext({
    locCycleAD: LookUp(CYCLES, State.Value = "Open")
})
