# Allow reapplication after withdrawal

**Problem.** An applicant can withdraw an application (added recently) but
cannot then submit a new one in the same cycle. The dialog copy was walked
back to hide this, but the underlying block remains. This is OI-STAT-4 item 2.

**Rule to enforce.** One application per applicant per cycle, EXCLUDING
withdrawn applications. Withdrawn rows are retained (audit / retention); a
new application is a distinct record.

**Where the block lives.** `build/screens/ApplicationScreen.OnVisible.fx:24-26`
— the returning-applicant lookup:

    locApp: LookUp(APPLICATIONS,
              And(CycleID.Id = locCycle.ID, ApplicantEmail = User().Email))

Nothing filters on `ApplicationStatus`, so a Withdrawn row from the same
cycle comes back. Once `locApp` is non-blank, the ~26 DisplayMode gates
across steps 1–5 (all shaped `locApp.ApplicationStatus.Value <> "Draft"`)
lock every input, and the form opens read-only.

---

## Step 1 — Exclude Withdrawn from the OnVisible lookup

Change `ApplicationScreen.OnVisible.fx:24-26` to:

    locApp: LookUp(APPLICATIONS,
              And(CycleID.Id = locCycle.ID,
                  ApplicantEmail = User().Email,
                  ApplicationStatus.Value <> "Withdrawn"))

A returning applicant with only a Withdrawn row now gets `locApp = Blank()`,
the DisplayMode gates open, and the Save/Submit handlers already do the
right thing:

    Patch(APPLICATIONS, If(IsBlank(locApp), Defaults(APPLICATIONS), locApp), { ... })

`Defaults()` mints a new row. Existing draft/submitted rows still load and
edit as today.

## Step 2 — Mirror the change in the header comment

`ApplicationScreen.yaml:52` shows the same OnVisible expression as reference.
Update it or the `.OnVisible.fx` and the yaml header drift apart.

## Step 3 — Ripple through other screens

Every screen whose OnVisible resolves `locApp` (or filters APPLICATIONS) by
`(CycleID, ApplicantEmail)` needs the same filter — otherwise a Withdrawn
row shows up in reviewer queues.

- **ApplicationStatusScreen** — the applicant's own timeline. Should still
  show Withdrawn (they need to see the outcome of the app they just
  withdrew). If we exclude Withdrawn here, the new blank application shows
  nothing until they save. Compromise: show the *most recent* row regardless
  of status; the new draft becomes the newest after first save.
- **SupervisorEndorsementScreen**, **DTDApplicationsScreen**,
  **CommitteeScoreScreen**, **PlacementScreen** — reviewers should NOT see
  Withdrawn rows. Add `ApplicationStatus.Value <> "Withdrawn"` to each
  screen's APPLICATIONS filter.

Grep `ApplicantEmail = User().Email` and `Filter(APPLICATIONS,` across the
screens folder before committing to make sure nothing was missed.

## Step 4 — Enforce "one non-withdrawn per cycle" explicitly on Submit

The OnVisible filter enforces the rule implicitly for the common case, but
it's a soft rule — two browser tabs open at once, or a race with the
Withdraw button, could still write a duplicate. OI-APP-5 already flagged
this class of bug (nothing enforces FR-011 today).

Cheap defensive check on `btnSubmitAP.OnSelect` BEFORE the Patch:

    If(!IsBlank(LookUp(APPLICATIONS,
         And(CycleID.Id = locCycle.ID,
             ApplicantEmail = User().Email,
             ApplicationStatus.Value <> "Withdrawn",
             ID <> Coalesce(locApp.ID, -1)))),
       Notify("You already have an active application for this cycle.", NotificationType.Error);
       Exit(),
       /* proceed with the current Patch chain */
    )

The `ID <> locApp.ID` guard is what lets legitimate re-saves through
(updating your own draft) while still catching a duplicate created behind
your back.

## Step 5 — Landing screen tile

Whichever button on the Landing screen navigates to `ApplicationScreen`,
its label/logic needs to key off the same filter — otherwise the button
reads "Continue" and takes the applicant to a Withdrawn form they can't
edit. After withdraw with no new application yet, the tile should read
"Start a new application" and navigate to the same screen.

## Step 6 — Testing

Two paths worth walking end-to-end:

1. Applicant submits → withdraws → returns to Application screen → sees
   blank form → picks a program → saves draft → confirms a new
   APPLICATIONS row is created (Withdrawn row still present in SharePoint,
   both visible).
2. Applicant submits → withdraws → submits new application → attempts to
   submit again while the second is Draft → the Step 4 guard fires.
   Withdraws the second → returns → blank form again.

## Housekeeping

- **OI-STAT-4 item 2** in `build/OPEN_ISSUES.md` should close (or move to
  CLOSED with a date and the two file references). The false-promise copy
  in the withdraw dialog can be restored to something like *"If you
  withdraw by mistake, you can start a new application."*
- **OI-APP-5** stays open until step 4 lands. The guard fixes the
  concurrent-withdraw race but does not fix the broader "two tabs"
  duplicate-creation problem OI-APP-5 describes. Note that when writing the
  fix.
- **No data model changes.** The Withdrawn row is preserved (retention
  satisfied) and the new row is a distinct record. Reviewer queues and
  placement views naturally ignore Withdrawn once step 3 is done.
