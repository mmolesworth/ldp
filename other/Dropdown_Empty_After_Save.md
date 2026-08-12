# Fix: program dropdown goes empty after Save

**Symptom.** On the Application Screen, the applicant picks a program, clicks
Save, the row and its `APPLICATION_PROGRAM_CHOICES` write to SharePoint
correctly — but the dropdown control shows blank text. No error is raised. To
the applicant it looks like nothing happened.

**Root cause.** The dropdown's `Default` reads a LookUp against
`APPLICATION_PROGRAM_CHOICES`. When Save runs, `locApp` changes AND the choice
rows are Removed and re-Patched inside the same handler. Power Apps
re-evaluates `Default` when its dependencies change *and* writes the new
Default value back into the control's displayed value. During the destructive
save the LookUp returns Blank momentarily, and if the local data-source cache
does not refresh after the re-write, the dropdown stays blank.

Ranks 2 and 3 already have a `locDropRank2` / `locDropRank3` guard for this
exact reason. Rank 1 does not.

---

## Step 1 — Confirm which of the three modes you are in

Add a temporary Label anywhere on the screen and set its `Text`:

    =Coalesce(drpProgram1AP.Default, "<blank>") & "  |  " &
     CountRows(Filter(APPLICATION_PROGRAM_CHOICES, ApplicationID.Id = locApp.ID))

Save, then read the label:

| What the label says | What it means | Go to |
|---|---|---|
| `<blank>  \|  0` | Local cache did not pick up the write | Step 2 |
| `<blank>  \|  1` (or higher) | LookUp finds the row but `.ProgramID.Value` is empty | Step 3 |
| `MDP  \|  1` (a program name, plus a count) but the dropdown is still blank | Items and Default match on different columns | Step 4 |

Delete the label once you know which branch you are in.

---

## Step 2 — Cache lag (most common)

Force a re-read after the choices are written.

1. Open `btnSaveAP.OnSelect` (the Save Draft button).
2. Find `Set(gblFormDirty, false);` — it sits after the `ForAll(..., Patch(APPLICATION_PROGRAM_CHOICES, ...))` block.
3. Immediately before that line, add:

        Refresh(APPLICATION_PROGRAM_CHOICES);
        Refresh(APPLICATIONS);

4. Do the same on `btnSubmitAP.OnSelect` — same pattern, same location, same two lines.
5. Save the screen and preview. Pick a program, click Save. The dropdown text should now stay visible.

If the dropdown still blanks intermittently on rank 1, continue to Step 5 (the guard-flag fix). Ranks 2 and 3 are already protected.

---

## Step 3 — `.ProgramID.Value` is coming back empty

The Patch is not populating the lookup column's display value.

1. Open `btnSaveAP.OnSelect`.
2. Find the `ProgramID:` block inside the `Patch(APPLICATION_PROGRAM_CHOICES, ...)` call.
3. Confirm it looks like this — both `Id` and `Value` set:

        ProgramID: {
          '@odata.type': "#Microsoft.Azure.Connectors.SharePoint.SPListExpandedReference",
          Id: ch.PrgId,
          Value: ch.PrgName
        }

4. `ch.PrgName` must be `drpProgram1AP.Selected.Value` (a text). If it is Blank at write time, the row is written without a display value and `.Value` reads back empty.
5. If your `APPLICATION_PROGRAM_CHOICES.ProgramID` column has `ShowField` set to something other than `ProgramName` in SharePoint, either change the `ShowField` to `ProgramName` or change the Default expression to read the column your `ShowField` points at.
6. Repeat on `btnSubmitAP.OnSelect`.

---

## Step 4 — Dropdown display column does not match Default

Classic/DropDown auto-picks which column of `Items` it displays. If `Items` is a table of records, Studio can pick a column that is not the one Default returns.

1. Select `drpProgram1AP` in the tree.
2. Confirm `Items` is exactly:

        =ForAll(
          Sort(Filter(PROGRAMS, State.Value <> "Retired"), ProgramName),
          ProgramName)

   The `ForAll(..., ProgramName)` projection collapses the table to a single
   text column. With one column there is nothing for Studio to auto-pick
   wrong.
3. If your `Items` is `=Filter(PROGRAMS, State.Value <> "Retired")` (a table of full records) — replace it with the ForAll form above.
4. Repeat on `drpProgram2AP` and `drpProgram3AP`.

---

## Step 5 — Add the rank 1 guard (if Step 2 alone did not stick)

Mirror the pattern already used for ranks 2 and 3.

1. In the SCREEN's `OnVisible`, add `locDropRank1: false` to the `UpdateContext({...})` block that already sets `locDropRank2` and `locDropRank3`.
2. Open `drpProgram1AP.Default` and wrap it:

        =If(locDropRank1, Blank(),
          LookUp(APPLICATION_PROGRAM_CHOICES,
            And(ApplicationID.Id = locApp.ID, Rank = 1)).ProgramID.Value)

3. Open `drpOption1AP.Default` and wrap the same way:

        =If(locDropRank1, Blank(),
          LookUp(APPLICATION_PROGRAM_CHOICES,
            And(ApplicationID.Id = locApp.ID, Rank = 1)).ProgramOptionID.Value)

4. In `btnSaveAP.OnSelect` and `btnSubmitAP.OnSelect`, at the very top before the `UpdateContext({ locApp: Patch(...) })` line, add:

        UpdateContext({ locDropRank1: true });

5. Do NOT clear `locDropRank1` in the Save handler. It clears on the next screen visit via OnVisible. This is the same rule the comment at line ~2968 of the YAML explains for ranks 2/3.
6. Save the screen and preview end-to-end: fresh application, pick program, Save, then Submit.

---

## Verify

- Fresh applicant, no draft yet → picks MDP → Save → dropdown still shows "MDP".
- Same applicant returns → dropdown shows "MDP" (Default finds the saved row).
- Changes to NEXT → Save → dropdown shows "NEXT".
- Submit → navigates to Application Status Screen. Return to Application Screen → dropdown shows "NEXT".
