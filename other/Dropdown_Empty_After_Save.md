# Fix: program dropdown goes empty after Save

**Symptom.** On the Application Screen, the applicant picks a program, clicks
Save, the row and its `APPLICATION_PROGRAM_CHOICES` write to SharePoint
correctly — but all three program dropdowns show blank text. No error is
raised. To the applicant it looks like nothing happened.

**Root cause.** The dropdown's `Default` reads a LookUp against
`APPLICATION_PROGRAM_CHOICES`. When Save runs, `locApp` changes AND the choice
rows are Removed and re-Patched inside the same handler. Power Apps
re-evaluates `Default` when its dependencies change *and* writes the new
Default value back into the control's displayed value. If the local
data-source cache does not reflect the just-written rows, `LookUp(...)`
returns Blank, `Default` returns Blank, and the dropdown displays blank —
even though SharePoint has the row.

All three ranks fail identically because the same LookUp expression is behind
each dropdown's Default. The `locDropRank2` / `locDropRank3` flags on ranks 2
and 3 only guard the "Remove rank" button flow (they suppress Default so the
save handler doesn't re-write a removed choice) — they do not protect against
this save-clobber. There is no per-rank fix to add.

---

## Step 1 — Try the cache refresh first

This is the leading hypothesis specifically because all three ranks fail
together.

1. Open `btnSaveAP.OnSelect` (the Save Draft button).
2. Find `Set(gblFormDirty, false);` — it sits after the
   `ForAll(..., Patch(APPLICATION_PROGRAM_CHOICES, ...))` block.
3. Immediately before that line, add:

        Refresh(APPLICATION_PROGRAM_CHOICES);
        Refresh(APPLICATIONS);

4. Do the same on `btnSubmitAP.OnSelect` — same pattern, same two lines,
   right before `Set(gblFormDirty, false)`.
5. Save the screen and preview. Pick a program, click Save. Confirm all
   three dropdowns retain their selected text.

If Save now works, stop here. If any dropdown is still blank, continue to
Step 2 to narrow which of the two remaining failure modes you are in.

---

## Step 2 — Diagnose which failure mode is left

Add a temporary Label anywhere on the screen and set its `Text` to the same
LookUp the dropdown's Default uses. (`.Default` is not readable off a
Classic/DropDown at runtime, so inline the expression instead.)

    =Coalesce(
       LookUp(APPLICATION_PROGRAM_CHOICES,
         And(ApplicationID.Id = locApp.ID, Rank = 1)).ProgramID.Value,
       "<blank>") & "  |  " &
     CountRows(Filter(APPLICATION_PROGRAM_CHOICES, ApplicationID.Id = locApp.ID))

Save, then read the label:

| What the label says | What it means | Go to |
|---|---|---|
| `<blank>  \|  1` (or higher) | LookUp finds the row but `.ProgramID.Value` is empty | Step 3 |
| `MDP  \|  1` (a program name, plus a count) but the dropdown is still blank | Items and Default match on different columns | Step 4 |
| `<blank>  \|  0` | Cache still stale — Step 1 refresh not taking effect | See notes at the end |

Delete the label once you know which branch you are in.

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

4. `ch.PrgName` must be `drpProgramNAP.Selected.Value` (a text). If it is
   Blank at write time, the row is written without a display value and
   `.Value` reads back empty.
5. If your `APPLICATION_PROGRAM_CHOICES.ProgramID` column has `ShowField`
   set to something other than `ProgramName` in SharePoint, either change
   the `ShowField` to `ProgramName` or change each dropdown's Default to
   read the column your `ShowField` points at.
6. Repeat the check on `btnSubmitAP.OnSelect`.

---

## Step 4 — Dropdown display column does not match Default

Classic/DropDown auto-picks which column of `Items` it displays. If `Items`
is a table of records, Studio can pick a column that is not the one Default
returns.

1. Select `drpProgram1AP` in the tree.
2. Confirm `Items` is exactly:

        =ForAll(
          Sort(Filter(PROGRAMS, State.Value <> "Retired"), ProgramName),
          ProgramName)

   The `ForAll(..., ProgramName)` projection collapses the table to a single
   text column. With one column there is nothing for Studio to auto-pick
   wrong.
3. If your `Items` is `=Filter(PROGRAMS, State.Value <> "Retired")` (a table
   of full records) — replace it with the ForAll form above.
4. Repeat on `drpProgram2AP` and `drpProgram3AP`.

---

## Verify

- Fresh applicant, no draft yet → picks MDP for rank 1, HPP for rank 2, NEXT
  for rank 3 → Save → all three dropdowns still show their picks.
- Close the app, reopen, return to the Application Screen → all three
  dropdowns show the saved picks (Default finds the saved rows).
- Change rank 1 to NEXT → Save → dropdown shows "NEXT".
- Submit → navigates to Application Status Screen. Return to Application
  Screen → all three dropdowns show the submitted values.

---

## Notes

- If Step 2's label reads `<blank>  |  0` even after the Refresh added in
  Step 1, the writes are being made against a different data-source connection
  than the reads (rare — usually caused by having the list added twice under
  different names). Check the app's data sources for a duplicate.
- The three-mode diagnostic label is a good thing to keep handy while
  developing. Once the fix sticks in preview and reload, delete it.
