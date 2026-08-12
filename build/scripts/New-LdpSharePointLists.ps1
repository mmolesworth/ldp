#Requires -Version 7.2
<#
.SYNOPSIS
    Provisions the 17 SharePoint lists for the LDP Application (Phase I).

.DESCRIPTION
    Creates every list, column, lookup relationship, and index defined in
    build/lists/*.md. Idempotent: existing lists and columns are detected and
    left alone, so the script is safe to re-run after a partial failure.

    Runs in four passes, because SharePoint cannot create a lookup column
    before its target list exists:
      1. Lists
      2. Simple columns (text, note, number, choice, date)
      3. Lookup columns   (build/lists/_RELATIONSHIPS_AND_INDEXES.md)
      4. Indexes          (Constitution III — delegation)

.PARAMETER SiteUrl
    Target site, e.g. <site-url>

.PARAMETER ClientId
    Entra ID app registration client ID used for interactive sign-in.
    PnP.PowerShell 2.0+ has no built-in client ID — see the runbook in
    build/scripts/README.md for how to create one.

.PARAMETER IncludeProposed
    Also create the columns and choice values marked [PROPOSED] in the specs.
    OFF by default: Constitution I forbids transcribing proposed items until
    DTD confirms them. See $script:ProposedItems for exactly what this adds.

.PARAMETER SkipIndexes
    Create lists and columns but skip pass 4.

.PARAMETER ShowInNavigation
    Add the lists to the site's left-hand navigation. Off by default — these are a
    backing store for the app, not pages users browse. Without it they are still
    reachable at Settings > Site contents.

.EXAMPLE
    ./New-LdpSharePointLists.ps1 -SiteUrl <site-url> -ClientId <your-client-id> -WhatIf

.EXAMPLE
    ./New-LdpSharePointLists.ps1 -SiteUrl <site-url> -ClientId <your-client-id>

.NOTES
    Source of truth: build/lists/*.md. If a definition changes there, change it
    here too — this script is not generated from those files.

    Yes/No columns are deliberately CHOICE columns, not SharePoint's native
    Yes/No type. The Power Fx already written against them reads `.Value`
    (e.g. locSelected.State.Value), which a boolean column does not provide.

    The ID column is not created: SharePoint supplies it automatically.

    EMPLOYEE_DIRECTORY was removed 2026-07-26. Personnel data comes from an
    existing system (D-1); the interim list is not part of the design. This
    script no longer creates or manages it. If the list already exists in
    SharePoint it is left alone — removing it from here does NOT delete it.

    KNOWN LIMITATION — collisions with built-in fields are silent.
    Get-ExistingField matches by display name, and SharePoint ships hidden system
    fields with human display names. If a definition below asks for a column whose
    display name a built-in already occupies, the check finds the built-in, reports
    "= exists", and never creates the real column. Nothing errors; the column is
    simply absent, and Power Fx fails later with an unresolvable field name.
    This happened with RATING_SHEETS.Version (built-in _UIVersionString is titled
    "Version"), which is why that column is now named SheetVersion.
    Reserved display names to avoid: Version, Created, Modified, Created By,
    Modified By, Title, Attachments, Content Type, Edit, Type.
    To audit: run with -WhatIf. Every "What if: Create ... column" line is a column
    genuinely missing from SharePoint.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [switch]$SeedCompetencies,

    # Skip provisioning entirely and run only the competency seed. For when the
    # lists already exist and you just want the data in.
    [switch]$SeedOnly,

    # Defaults to the script's own directory. The CSVs are deliberately siblings
    # of this file: it gets copied out of WSL to a Windows path to run, and a
    # sibling data/ folder does not come with it.
    [string]$DataPath = $PSScriptRoot,

    [switch]$IncludeProposed,

    [switch]$SkipIndexes,

    [switch]$ShowInNavigation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# [PROPOSED] items — gated behind -IncludeProposed (Constitution I)
# ---------------------------------------------------------------------------
$script:ProposedItems = @(
    'APPLICATIONS.AlternateSecondLineEmail (column)              — FR-012a'
    'APPLICATIONS.ReviewStage → "Needs Supervisor Assigned"      — FR-012a'
    'SUPERVISOR_ENDORSEMENTS.SupervisorLevel → "Alternate Second Line" — FR-012a'
    'CHANGE_HISTORY.ChangeType → "Alternate Designation"         — FR-012a'
)

# ---------------------------------------------------------------------------
# PASS 1 + 2 DEFINITIONS — lists and their non-lookup columns
# Type: Text | Note | Number | Choice | Date | DateTime
# ---------------------------------------------------------------------------
$script:Lists = [ordered]@{

    'CYCLES' = @{
        Description = 'Application cycles — state and key dates. Scopes applications, rating sheets, placements.'
        Fields      = @(
            @{ Name = 'CycleName';            Type = 'Text';   Required = $true }
            @{ Name = 'State';                Type = 'Choice'; Required = $true; Choices = @('Scheduled', 'Open', 'Closed', 'In Review') }
            @{ Name = 'OpenDate';             Type = 'Date';   Required = $true }
            @{ Name = 'CloseDate';            Type = 'Date';   Required = $true }
            @{ Name = 'ExpectedDecisionDate'; Type = 'Date';   Required = $true }
        )
    }

    'PROGRAMS' = @{
        Description = 'The three program groupings (NEXT, MDP, HPP). Parent of PROGRAM_OPTIONS; scored at this level.'
        Fields      = @(
            @{ Name = 'ProgramName';  Type = 'Text'; Required = $true }
            # Short label for tight UI (tab bars, chips). Required so nothing
            # displays a blank tab; backfill existing rows before re-running.
            @{ Name = 'Abbreviation'; Type = 'Text'; Required = $true }
            @{ Name = 'Description';  Type = 'Note' }
            @{ Name = 'State';        Type = 'Choice'; Required = $true; Choices = @('Active', 'Retired') }
        )
    }

    'PROGRAM_OPTIONS' = @{
        Description = 'Selectable options under a program. Applicants rank options; DTD places into one.'
        Fields      = @(
            @{ Name = 'OptionName';   Type = 'Text'; Required = $true }
            @{ Name = 'Description';  Type = 'Note' }
            @{ Name = 'Vendor';       Type = 'Text' }
            @{ Name = 'GradeLevel';   Type = 'Text' }
            @{ Name = 'CourseLength'; Type = 'Text' }
            @{ Name = 'Competency';   Type = 'Note' }
            @{ Name = 'Requirements'; Type = 'Note' }
            @{ Name = 'Website';      Type = 'Text' }
            @{ Name = 'State';        Type = 'Choice'; Required = $true; Choices = @('Active', 'Retired') }
        )
    }

    # COMPETENCY_TYPES is a LIST, not a Choice column on COMPETENCIES, so that a
    # new type is DATA rather than a schema change. A choice column can only be
    # extended in SharePoint's column settings by someone with list-design
    # rights; a lookup list can be extended from the Competencies admin screen
    # by DTD. Same parent/child shape as PROGRAMS -> PROGRAM_OPTIONS.
    'COMPETENCY_TYPES' = @{
        Description = 'Groupings of competency (OPM, ECQ, Technical). Parent of COMPETENCIES; extend by adding rows, not columns.'
        Fields      = @(
            @{ Name = 'TypeName';    Type = 'Text';   Required = $true }
            @{ Name = 'Description'; Type = 'Note' }
            @{ Name = 'SortOrder';   Type = 'Number' }
            # MAXIMUM selections of this type on one application — RQ006 three
            # OPM, RQ007 three technical, RQ008 four ECQ. A column rather than a
            # constant in two screens, because the type list is data-driven and
            # a fourth type would otherwise need a YAML edit to be usable.
            @{ Name = 'SelectionCount'; Type = 'Number' }
            @{ Name = 'State';       Type = 'Choice'; Required = $true; Choices = @('Active', 'Retired') }
        )
    }

    'COMPETENCIES' = @{
        Description = 'The competency catalogue. Seeded from docs/competencies.xlsx via build/scripts/competencies.csv.'
        Fields      = @(
            @{ Name = 'CompetencyName'; Type = 'Text'; Required = $true }
            @{ Name = 'Description';    Type = 'Note' }
            @{ Name = 'State';          Type = 'Choice'; Required = $true; Choices = @('Active', 'Retired') }
        )
    }

    'APPLICATIONS' = @{
        Description = 'The central application record. Supporting documents are native SharePoint attachments. Final placement lives on PlacementProgramID / PlacementOptionID (see the lookups section) — no separate PLACEMENTS list.'
        Fields      = @(
            @{ Name = 'ApplicantEmail';           Type = 'Text';   Required = $true }
            @{ Name = 'ApplicantName';            Type = 'Text';   Required = $true }
            @{ Name = 'Location';                 Type = 'Text' }
            @{ Name = 'Grade';                    Type = 'Text' }
            @{ Name = 'JobSeries';                Type = 'Text' }
            @{ Name = 'JobTitle';                 Type = 'Text' }
            # Type pending Appendix B (D-2) — may become multi-select Choice.
            @{ Name = 'ListedOnIDP';              Type = 'Choice'; Choices = @('Yes', 'No') }
            @{ Name = 'LatestPerformanceRating';  Type = 'Number' }
            @{ Name = 'AttendedInfoSession';      Type = 'Choice'; Choices = @('Yes', 'No') }
            @{ Name = 'InfoSessionDate';          Type = 'Date' }
            @{ Name = 'NCUAStartDate';            Type = 'Date' }
            @{ Name = 'ServiceComputationDate';   Type = 'Date' }
            # OPMCompetencies / TechnicalCompetencies / ECQs removed 2026-07-31.
            # One text column per competency type cannot survive the type list
            # being data-driven — DTD can add a fourth type and there would be
            # no column for it. Selections live in APPLICATION_COMPETENCIES.
            # One column became three on 2026-07-31 — see build/lists/_CHOICES.md.
            # Each is owned by a different party and advances on its own clock;
            # sharing a column meant every advance destroyed the last answer.
            # Draft -> Submitted -> Validated is one linear progression, so a
            # later value implies the earlier ones: Validated means submitted
            # and accepted by DTD. An edit to a validated application drops it
            # back to Submitted, which is a backward transition in the machine,
            # not a separate flag. Withdrawn is terminal from anywhere.
            @{ Name = 'ApplicationStatus';        Type = 'Choice'; Required = $true; Choices = @('Draft', 'Submitted', 'Validated', 'Withdrawn') }
            @{ Name = 'PlacementOutcome';         Type = 'Choice'; Required = $true; Choices = @('Pending', 'Placed', 'Not Selected', 'Declined') }
            @{ Name = 'FirstLineSupervisorEmail'; Type = 'Text' }
            @{ Name = 'SecondLineSupervisorEmail'; Type = 'Text' }
            @{ Name = 'AlternateSecondLineEmail'; Type = 'Text'; Proposed = $true }
            # Linear, with ONE detour: no second-line supervisor on record sends
            # the packet to Needs Supervisor Assigned, and it rejoins at Pending
            # Second Line once DTD names someone. Nothing else forks.
            @{ Name = 'ReviewStage';              Type = 'Choice'
               Choices         = @('Pending First-Line', 'Pending Second-Line', 'Pending DTD Validation', 'Committee Review', 'Pending Placement', 'Pending Notification', 'Complete')
               ProposedChoices = @('Needs Supervisor Assigned') }
        )
    }

    'APPLICATION_COMPETENCIES' = @{
        Description = 'An application''s selected competencies (join of APPLICATIONS x COMPETENCIES). The TYPE comes from the competency''s parent and is deliberately not stored here — duplicating it would let the two disagree.'
        Fields      = @()
    }

    'APPLICATION_PROGRAM_CHOICES' = @{
        Description = 'Ranked program selections (applicant-owned) plus committee score aggregate (committee-owned). Per-criterion detail on COMMITTEE_CRITERION_SCORES.'
        Fields      = @(
            @{ Name = 'Rank';              Type = 'Number'; Required = $true }
            # Committee-owned columns, written on submit from the Committee
            # Score Screen. Blank until then. See build/lists/APPLICATION_PROGRAM_CHOICES.md
            # (revised 2026-08-07) for the split of ownership on this row.
            @{ Name = 'FinalScore';        Type = 'Number' }
            @{ Name = 'PercentOfPossible'; Type = 'Number' }
            @{ Name = 'ScoredBy';          Type = 'Text' }
            @{ Name = 'ScoredDate';        Type = 'Date' }
        )
    }

    'SUPERVISOR_ENDORSEMENTS' = @{
        Description = 'Supervisor endorsement decisions, statements, and advisory program recommendations.'
        Fields      = @(
            @{ Name = 'SupervisorEmail';      Type = 'Text';   Required = $true }
            @{ Name = 'SupervisorLevel';      Type = 'Choice'; Required = $true
               Choices         = @('First Line', 'Second Line')
               ProposedChoices = @('Alternate Second Line') }
            @{ Name = 'Decision';             Type = 'Choice'; Required = $true; Choices = @('Recommend', 'Not Recommend') }
            @{ Name = 'DispositionStatement'; Type = 'Note';   Required = $true }
            @{ Name = 'RecommendedOptions';   Type = 'Note' }
            @{ Name = 'DecisionDate';         Type = 'Date';   Required = $true }
        )
    }

    'CRITERION_CATALOG' = @{
        Description = 'Shared master set of scoring criteria, reusable across programs and cycles.'
        Fields      = @(
            @{ Name = 'CriterionName'; Type = 'Text';   Required = $true }
            @{ Name = 'Description';   Type = 'Note';   Required = $true }
            @{ Name = 'State';         Type = 'Choice'; Required = $true; Choices = @('Draft', 'Published', 'Retired') }
            @{ Name = 'StartDate';     Type = 'Date' }
            @{ Name = 'EndDate';       Type = 'Date' }
        )
    }

    'CRITERION_ANCHORS' = @{
        Description = 'The four scoring anchors (0/1/3/5) for a catalog criterion.'
        Fields      = @(
            @{ Name = 'Score';       Type = 'Number'; Required = $true }
            @{ Name = 'AnchorText';  Type = 'Note';   Required = $true }
            @{ Name = 'ExampleText'; Type = 'Note' }
        )
    }

    'RATING_SHEETS' = @{
        Description = 'Committee rating sheets — immutably versioned, per program. Reused across cycles until replaced (R3).'
        Fields      = @(
            @{ Name = 'SheetVersion'; Type = 'Number'; Required = $true }
            # Draft -> Published -> Superseded. At most ONE Published per
            # program: that is the sheet in use. Publishing vN supersedes the
            # one it replaces, which is what makes a separate IsCurrent
            # redundant — two columns for one lifecycle can disagree.
            @{ Name = 'State';       Type = 'Choice'; Required = $true; Choices = @('Draft', 'Published', 'Superseded') }
            @{ Name = 'CreatedBy';   Type = 'Text';   Required = $true }
            @{ Name = 'CreatedDate'; Type = 'Date';   Required = $true }
        )
    }

    'RATING_CRITERIA' = @{
        Description = 'Criteria selected onto a rating-sheet version. Criterion text lives on CRITERION_CATALOG.'
        Fields      = @(
            @{ Name = 'DisplayOrder'; Type = 'Number' }
        )
    }

    # COMMITTEE_SCORES was deprecated 2026-08-07. Aggregate moved to
    # APPLICATION_PROGRAM_CHOICES; per-criterion detail moved to a new
    # COMMITTEE_CRITERION_SCORES list. Never populated in any environment.
    # If the list exists in SharePoint from an earlier run, delete manually.

    'COMMITTEES' = @{
        Description = 'A committee formed to score applicants for a program in a cycle. Pins the rubric version being scored against. See build/lists/COMMITTEES.md.'
        Fields      = @(
            @{ Name = 'CommitteeName'; Type = 'Text';   Required = $true }
            @{ Name = 'State';         Type = 'Choice'; Required = $true; Choices = @('Active', 'Ranked') }
            @{ Name = 'FormedDate';    Type = 'Date';   Required = $true }
        )
    }

    'COMMITTEE_CRITERION_SCORES' = @{
        Description = 'Per-criterion score and comment for an applicant''s program choice. One row per (choice x criterion). Aggregate on APPLICATION_PROGRAM_CHOICES.'
        Fields      = @(
            @{ Name = 'Score';   Type = 'Number'; Required = $true }
            @{ Name = 'Comment'; Type = 'Note' }
        )
    }

    # PLACEMENTS deprecated 2026-08-11. One placement per applicant is 1:1 with
    # APPLICATIONS, so the placement is now two lookups on APPLICATIONS
    # (PlacementProgramID + PlacementOptionID) plus the existing
    # PlacementOutcome choice. PlacedBy / PlacedDate / IsFinalized were dropped
    # as unneeded per DTD. If the PLACEMENTS list exists in SharePoint from an
    # earlier run, delete manually — nothing writes to it.

    'NOTIFICATIONS' = @{
        Description = 'Append-only log of notifications sent. ApplicationID is a Number, not a Lookup, by design.'
        Fields      = @(
            @{ Name = 'ApplicationID';    Type = 'Number';   Required = $true }
            @{ Name = 'RecipientEmail';   Type = 'Text';     Required = $true }
            @{ Name = 'NotificationType'; Type = 'Choice';   Required = $true; Choices = @('Pending Action', 'Advance', 'Reminder', 'Disposition') }
            @{ Name = 'SendOutcome';      Type = 'Choice';   Required = $true; Choices = @('Sent', 'Failed') }
            @{ Name = 'SentDate';         Type = 'DateTime'; Required = $true }
        )
    }

    'CHANGE_HISTORY' = @{
        Description = 'Append-only audit trail. ApplicationID is a Number, not a Lookup, to preserve the trail.'
        Fields      = @(
            @{ Name = 'ApplicationID'; Type = 'Number';   Required = $true }
            @{ Name = 'ChangeType';    Type = 'Choice';   Required = $true
               Choices         = @('Program Recommendation', 'Completeness Determination', 'Notification Sent', 'Placement', 'Post-Submission Modification')
               ProposedChoices = @('Alternate Designation') }
            @{ Name = 'ChangedBy';     Type = 'Text';     Required = $true }
            @{ Name = 'ChangedDate';   Type = 'DateTime'; Required = $true }
            @{ Name = 'Details';       Type = 'Note' }
        )
    }
}

# ---------------------------------------------------------------------------
# PASS 3 — lookup columns (_RELATIONSHIPS_AND_INDEXES.md)
# ShowField is the human-readable column of the target list. Power Fx still
# reads the key as .Id regardless, so display choice costs nothing.
# ---------------------------------------------------------------------------
$script:Lookups = @(
    @{ List = 'PROGRAM_OPTIONS';             Name = 'ProgramID';          Target = 'PROGRAMS';           ShowField = 'ProgramName';   Required = $true }
    @{ List = 'COMPETENCIES';                Name = 'CompetencyTypeID';   Target = 'COMPETENCY_TYPES';   ShowField = 'TypeName';      Required = $true }
    @{ List = 'APPLICATIONS';                Name = 'CycleID';            Target = 'CYCLES';             ShowField = 'CycleName';     Required = $true }
    @{ List = 'APPLICATION_COMPETENCIES';    Name = 'ApplicationID';      Target = 'APPLICATIONS';       ShowField = 'ApplicantEmail'; Required = $true }
    @{ List = 'APPLICATION_COMPETENCIES';    Name = 'CompetencyID';       Target = 'COMPETENCIES';       ShowField = 'CompetencyName'; Required = $true }
    @{ List = 'APPLICATION_PROGRAM_CHOICES'; Name = 'ApplicationID';      Target = 'APPLICATIONS';       ShowField = 'ApplicantEmail'; Required = $true }
    # The PROGRAM is what the applicant chooses. The OPTION is an extra detail
    # that only some programs have — HPP today, none tomorrow if it changes.
    # Requiring the option is what forced fabricated "N/A" rows for MDP and
    # NEXT, since neither can be chosen without one. See 2026-07-31.
    @{ List = 'APPLICATION_PROGRAM_CHOICES'; Name = 'ProgramID';                 Target = 'PROGRAMS';                    ShowField = 'ProgramName';   Required = $true }
    @{ List = 'APPLICATION_PROGRAM_CHOICES'; Name = 'ProgramOptionID';           Target = 'PROGRAM_OPTIONS';             ShowField = 'OptionName';    Required = $false }
    @{ List = 'APPLICATION_PROGRAM_CHOICES'; Name = 'CommitteeID';               Target = 'COMMITTEES';                  ShowField = 'CommitteeName'; Required = $false }
    @{ List = 'SUPERVISOR_ENDORSEMENTS';     Name = 'ApplicationID';             Target = 'APPLICATIONS';                ShowField = 'ApplicantEmail'; Required = $true }
    @{ List = 'RATING_SHEETS';               Name = 'ProgramID';                 Target = 'PROGRAMS';                    ShowField = 'ProgramName';   Required = $true }
    @{ List = 'RATING_CRITERIA';             Name = 'RatingSheetID';             Target = 'RATING_SHEETS';               ShowField = 'ID';            Required = $true }
    @{ List = 'RATING_CRITERIA';             Name = 'CatalogCriterionID';        Target = 'CRITERION_CATALOG';           ShowField = 'CriterionName'; Required = $true }
    @{ List = 'CRITERION_ANCHORS';           Name = 'CatalogCriterionID';        Target = 'CRITERION_CATALOG';           ShowField = 'CriterionName'; Required = $true }
    @{ List = 'COMMITTEES';                  Name = 'ProgramID';                 Target = 'PROGRAMS';                    ShowField = 'ProgramName';   Required = $true }
    @{ List = 'COMMITTEES';                  Name = 'CycleID';                   Target = 'CYCLES';                      ShowField = 'CycleName';     Required = $true }
    @{ List = 'COMMITTEES';                  Name = 'RatingSheetID';             Target = 'RATING_SHEETS';               ShowField = 'ID';            Required = $true }
    @{ List = 'COMMITTEE_CRITERION_SCORES';  Name = 'ApplicationProgramChoiceID'; Target = 'APPLICATION_PROGRAM_CHOICES'; ShowField = 'ID';            Required = $true }
    @{ List = 'COMMITTEE_CRITERION_SCORES';  Name = 'RatingCriterionID';         Target = 'RATING_CRITERIA';             ShowField = 'ID';            Required = $true }
    # Final placement lives on APPLICATIONS as of 2026-08-11. Both optional:
    # blank means no decision yet; PlacementOutcome = "Not Selected" is set
    # without either lookup.
    @{ List = 'APPLICATIONS';                Name = 'PlacementProgramID'; Target = 'PROGRAMS';           ShowField = 'ProgramName';   Required = $false }
    @{ List = 'APPLICATIONS';                Name = 'PlacementOptionID';  Target = 'PROGRAM_OPTIONS';    ShowField = 'OptionName';    Required = $false }
)

# ---------------------------------------------------------------------------
# PASS 4 — indexes (Constitution III)
# ---------------------------------------------------------------------------
$script:Indexes = [ordered]@{
    'APPLICATIONS'                = @('CycleID', 'ApplicantEmail', 'ApplicationStatus', 'ReviewStage', 'PlacementOutcome', 'PlacementProgramID')
    'APPLICATION_COMPETENCIES'    = @('ApplicationID', 'CompetencyID')
    'APPLICATION_PROGRAM_CHOICES' = @('ApplicationID', 'ProgramID', 'ProgramOptionID', 'CommitteeID')
    'SUPERVISOR_ENDORSEMENTS'     = @('ApplicationID')
    'RATING_SHEETS'               = @('ProgramID', 'State')
    'RATING_CRITERIA'             = @('RatingSheetID')
    'CRITERION_CATALOG'           = @('State')
    'CRITERION_ANCHORS'           = @('CatalogCriterionID')
    'COMMITTEES'                  = @('ProgramID', 'CycleID', 'State')
    'COMMITTEE_CRITERION_SCORES'  = @('ApplicationProgramChoiceID', 'RatingCriterionID')
    'NOTIFICATIONS'               = @('ApplicationID')
    'CHANGE_HISTORY'              = @('ApplicationID')
    'CYCLES'                      = @('State')
    'PROGRAM_OPTIONS'             = @('ProgramID', 'State')
    'PROGRAMS'                    = @('State')
    'COMPETENCY_TYPES'            = @('State')
    'COMPETENCIES'                = @('CompetencyTypeID', 'State')
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
$script:Tally = [ordered]@{ ListsCreated = 0; ListsExisting = 0; FieldsCreated = 0; FieldsExisting = 0; LookupsCreated = 0; IndexesSet = 0; ItemsSeeded = 0; ItemsExisting = 0; Skipped = 0 }

function Write-Step { param([string]$Message) Write-Host "  $Message" -ForegroundColor DarkGray }
function Write-Made { param([string]$Message) Write-Host "  + $Message" -ForegroundColor Green }
function Write-Kept { param([string]$Message) Write-Host "  = $Message (exists)" -ForegroundColor DarkGray }
function Write-Held { param([string]$Message) Write-Host "  ~ $Message" -ForegroundColor Yellow }

function Get-ExistingList {
    param([string]$Title)
    try { return Get-PnPList -Identity $Title -ErrorAction SilentlyContinue } catch { return $null }
}

function Get-ExistingField {
    param([string]$ListTitle, [string]$InternalName)
    try { return Get-PnPField -List $ListTitle -Identity $InternalName -ErrorAction SilentlyContinue } catch { return $null }
}

function New-LdpList {
    param([string]$Title, [string]$Description)

    if (Get-ExistingList -Title $Title) {
        Write-Kept "list $Title"
        $script:Tally.ListsExisting++
        return
    }
    if (-not $PSCmdlet.ShouldProcess($Title, 'Create list')) { return }

    New-PnPList -Title $Title -Template GenericList -OnQuickLaunch:$ShowInNavigation | Out-Null
    Set-PnPList -Identity $Title -Description $Description | Out-Null

    # Title is unused by every list here — make it optional so writes from Power Fx
    # do not fail on a column the app never populates.
    Set-PnPField -List $Title -Identity 'Title' -Values @{ Required = $false } -UpdateExistingLists:$false | Out-Null

    Write-Made "list $Title"
    $script:Tally.ListsCreated++
}

function New-LdpField {
    param([string]$ListTitle, [hashtable]$Field)

    $name = $Field.Name

    if ($Field.ContainsKey('Proposed') -and $Field.Proposed -and -not $IncludeProposed) {
        Write-Held "$ListTitle.$name skipped — [PROPOSED], needs DTD confirmation"
        $script:Tally.Skipped++
        return
    }
    if (Get-ExistingField -ListTitle $ListTitle -InternalName $name) {
        Write-Kept "$ListTitle.$name"
        $script:Tally.FieldsExisting++
        return
    }
    if (-not $PSCmdlet.ShouldProcess("$ListTitle.$name", "Create $($Field.Type) column")) { return }

    $required = $Field.ContainsKey('Required') -and $Field.Required
    $common = @{ List = $ListTitle; DisplayName = $name; InternalName = $name; AddToDefaultView = $true }
    if ($required) { $common['Required'] = $true }

    switch ($Field.Type) {
        'Text'   { Add-PnPField @common -Type Text   | Out-Null }
        'Number' { Add-PnPField @common -Type Number | Out-Null }

        'Note' {
            Add-PnPField @common -Type Note | Out-Null
            # Plain text, not rich text: Details holds JSON, and rich text wraps
            # values in markup that Power Fx would have to strip.
            Set-PnPField -List $ListTitle -Identity $name -Values @{ RichText = $false; AppendOnly = $false } | Out-Null
        }

        'Choice' {
            $choices = @($Field.Choices)
            if ($Field.ContainsKey('ProposedChoices')) {
                if ($IncludeProposed) {
                    $choices += $Field.ProposedChoices
                } else {
                    Write-Held "$ListTitle.$name omits [PROPOSED] value(s): $($Field.ProposedChoices -join ', ')"
                    $script:Tally.Skipped++
                }
            }
            Add-PnPField @common -Type Choice -Choices $choices | Out-Null
        }

        'Date' {
            Add-PnPField @common -Type DateTime | Out-Null
            Set-PnPField -List $ListTitle -Identity $name -Values @{ DisplayFormat = 0 } | Out-Null   # 0 = DateOnly
        }

        'DateTime' {
            Add-PnPField @common -Type DateTime | Out-Null
            Set-PnPField -List $ListTitle -Identity $name -Values @{ DisplayFormat = 1 } | Out-Null   # 1 = DateTime
        }

        default { throw "Unknown field type '$($Field.Type)' for $ListTitle.$name" }
    }

    Write-Made "$ListTitle.$name ($($Field.Type)$(if ($required) { ', required' }))"
    $script:Tally.FieldsCreated++
}

function New-LdpLookup {
    param([hashtable]$Lookup)

    $listTitle = $Lookup.List
    $name      = $Lookup.Name

    if (Get-ExistingField -ListTitle $listTitle -InternalName $name) {
        Write-Kept "$listTitle.$name -> $($Lookup.Target)"
        $script:Tally.FieldsExisting++
        return
    }
    if (-not $PSCmdlet.ShouldProcess("$listTitle.$name", "Create lookup to $($Lookup.Target)")) { return }

    $target = Get-ExistingList -Title $Lookup.Target
    if (-not $target) { throw "Lookup target list '$($Lookup.Target)' does not exist — cannot create $listTitle.$name" }

    # Lookups must be created from schema XML: Add-PnPField has no way to set the
    # target list and ShowField together.
    $required = if ($Lookup.Required) { 'TRUE' } else { 'FALSE' }
    $xml = @"
<Field Type="Lookup"
       DisplayName="$name"
       Name="$name"
       StaticName="$name"
       List="{$($target.Id)}"
       ShowField="$($Lookup.ShowField)"
       Required="$required" />
"@

    Add-PnPFieldFromXml -List $listTitle -FieldXml $xml | Out-Null

    # Add-PnPFieldFromXml has no -AddToDefaultView, so a lookup created this way is
    # invisible in the SharePoint UI even though it exists and is queryable. Add it
    # explicitly, or every lookup column looks "missing" when you open the list.
    #
    # Set-PnPView -Fields REPLACES the view's column list; there is no append.
    # So read the current fields, add ours, and write the whole set back — and
    # bail out if the read comes back empty, because writing @($name) alone
    # would wipe every other column off the default view.
    #
    # (Add-PnPViewField does not exist in PnP.PowerShell — it was a cmdlet in the
    # retired SharePointPnPPowerShellOnline module.)
    #
    # This is cosmetic. It must never abort provisioning: the lookup is already
    # created and queryable by the time we get here.
    try {
        $defaultView = Get-PnPView -List $listTitle | Where-Object { $_.DefaultView } | Select-Object -First 1
        if ($defaultView) {
            $current = @($defaultView.ViewFields)
            if ($current.Count -eq 0) {
                Write-Held "$listTitle.$name - default view fields unreadable, column not added to the view"
            } elseif ($current -notcontains $name) {
                Set-PnPView -List $listTitle -Identity $defaultView.Title -Fields ($current + $name) | Out-Null
            }
        }
    } catch {
        Write-Held "$listTitle.$name created, but adding it to the default view failed: $($_.Exception.Message)"
    }

    Write-Made "$listTitle.$name -> $($Lookup.Target).$($Lookup.ShowField)"
    $script:Tally.LookupsCreated++
}

function Set-LdpIndex {
    param([string]$ListTitle, [string]$FieldName)

    $field = Get-ExistingField -ListTitle $ListTitle -InternalName $FieldName
    if (-not $field) {
        Write-Held "index $ListTitle.$FieldName skipped — column not present"
        $script:Tally.Skipped++
        return
    }
    if ($field.Indexed) {
        Write-Kept "index $ListTitle.$FieldName"
        return
    }
    if (-not $PSCmdlet.ShouldProcess("$ListTitle.$FieldName", 'Add index')) { return }

    Set-PnPField -List $ListTitle -Identity $FieldName -Values @{ Indexed = $true } | Out-Null
    Write-Made "index $ListTitle.$FieldName"
    $script:Tally.IndexesSet++
}

# ---------------------------------------------------------------------------
# PASS 5 — seed COMPETENCY_TYPES and COMPETENCIES from CSV
# ---------------------------------------------------------------------------
# Idempotent by NAME: types by TypeName, competencies by type + CompetencyName.
# Re-running adds what is missing and touches nothing else, so a partial run is
# safe to repeat.
#
# Seeding is NOT a sync. A description edited in the CSV will not overwrite the
# row already in SharePoint. Edit it in SharePoint, or delete the row and
# re-seed.
#
# The CSVs are generated from docs/competencies.xlsx by
# build/scripts/Convert-CompetencyWorkbook.py, which repairs three known defects
# in the workbook. Do not hand-edit the CSVs — fix the workbook and re-convert,
# or the next conversion silently discards the edit.
function Import-LdpCompetencies {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path)

    $typesCsv = Join-Path $Path 'competency-types.csv'
    $compsCsv = Join-Path $Path 'competencies.csv'
    foreach ($f in @($typesCsv, $compsCsv)) {
        if (-not (Test-Path $f)) {
            throw "Seed file not found: $f. Run build/scripts/Convert-CompetencyWorkbook.py first."
        }
    }

    # --- types ---
    $existingTypes = @{}
    foreach ($item in (Get-PnPListItem -List 'COMPETENCY_TYPES' -PageSize 500)) {
        $existingTypes[[string]$item['TypeName']] = $item.Id
    }

    foreach ($row in (Import-Csv $typesCsv)) {
        $name = $row.TypeName.Trim()
        if ($existingTypes.ContainsKey($name)) {
            Write-Kept "COMPETENCY_TYPES/$name"
            $script:Tally.ItemsExisting++
            continue
        }
        if ($PSCmdlet.ShouldProcess("COMPETENCY_TYPES/$name", 'Add item')) {
            $values = @{ TypeName = $name; State = 'Active' }
            if ($row.SortOrder) { $values['SortOrder'] = [int]$row.SortOrder }
            Add-PnPListItem -List 'COMPETENCY_TYPES' -Values $values | Out-Null
            Write-Made "COMPETENCY_TYPES/$name"
            $script:Tally.ItemsSeeded++
        }
    }

    # Re-read the types from the list rather than trusting the .Id on the object
    # Add-PnPListItem returned. CSOM populates that lazily, so a type created in
    # THIS run can hand back an Id that is not there yet — which then goes into
    # the lookup and fails the write with a transport-level error that names
    # neither the field nor the reason.
    $existingTypes = @{}
    foreach ($item in (Get-PnPListItem -List 'COMPETENCY_TYPES' -PageSize 500)) {
        $existingTypes[[string]$item['TypeName']] = $item.Id
    }
    Write-Step "types resolved: $(($existingTypes.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', ')"

    # --- competencies ---
    # Keyed on type + name: a name is only unique WITHIN a type.
    $existingComps = @{}
    foreach ($item in (Get-PnPListItem -List 'COMPETENCIES' -PageSize 500)) {
        $lookup = $item['CompetencyTypeID']
        $typeName = if ($lookup) { [string]$lookup.LookupValue } else { '' }
        $existingComps["$typeName|$([string]$item['CompetencyName'])"] = $item.Id
    }

    $added = 0
    $failed = 0
    foreach ($row in (Import-Csv $compsCsv)) {
        $type = $row.Type.Trim()
        $name = $row.Name.Trim()

        if ($existingComps.ContainsKey("$type|$name")) {
            $script:Tally.ItemsExisting++
            continue
        }
        if (-not $existingTypes.ContainsKey($type)) {
            # -WhatIf never creates the types, so an unresolved type is expected
            # there and is a genuine error anywhere else.
            if ($WhatIfPreference) { continue }
            throw "Competency '$name' names type '$type', which is not in competency-types.csv."
        }
        if ($PSCmdlet.ShouldProcess("COMPETENCIES/$type/$name", 'Add item')) {
            $values = @{
                CompetencyName   = $name
                CompetencyTypeID = $existingTypes[$type]
                State            = 'Active'
            }
            if ($row.Description) { $values['Description'] = $row.Description }

            # Per row, so one bad record reports itself and the run continues.
            # A single throw here previously killed the whole seed at item 1 and
            # told us nothing about which field it objected to.
            try {
                Add-PnPListItem -List 'COMPETENCIES' -Values $values | Out-Null
                $script:Tally.ItemsSeeded++
                $added++
            } catch {
                $failed++
                if ($failed -le 3) {
                    Write-Held "COMPETENCIES/$type/$name failed: $($_.Exception.Message)"
                    Write-Held "  name $($name.Length) chars, description $(($row.Description).Length) chars, typeId '$($values.CompetencyTypeID)'"
                }
            }
        }
    }
    if ($added)  { Write-Made "COMPETENCIES - $added item(s)" }
    if ($failed) {
        Write-Held "COMPETENCIES - $failed item(s) FAILED"
        $script:Tally.Skipped += $failed
        if ($failed -gt 3) { Write-Held "  (only the first 3 errors are shown)" }
    }
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
$module = Get-Module -ListAvailable -Name 'PnP.PowerShell' | Select-Object -First 1
if (-not $module) {
    throw "PnP.PowerShell is not installed. Run: Install-Module PnP.PowerShell -Scope CurrentUser"
}

Write-Host ''
Write-Host "LDP SharePoint provisioning" -ForegroundColor Cyan
Write-Host "  Site           : $SiteUrl"
Write-Host "  PnP.PowerShell : $($module.Version)"
Write-Host "  Proposed items : $(if ($IncludeProposed) { 'INCLUDED' } else { 'skipped (Constitution I)' })"
Write-Host "  Competency seed: $(if ($SeedCompetencies -or $SeedOnly) { $DataPath } else { 'skipped (pass -SeedCompetencies)' })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    $web = Get-PnPWeb
    Write-Host "Connected to '$($web.Title)'" -ForegroundColor Cyan
    Write-Host ''

    if ($SeedOnly) {
        Write-Host 'PASSES 1-4 SKIPPED (-SeedOnly)' -ForegroundColor Yellow
    } else {

    Write-Host 'PASS 1/5  Lists' -ForegroundColor Cyan
    foreach ($listTitle in $script:Lists.Keys) {
        New-LdpList -Title $listTitle -Description $script:Lists[$listTitle].Description
    }

    Write-Host ''
    Write-Host 'PASS 2/5  Columns' -ForegroundColor Cyan
    foreach ($listTitle in $script:Lists.Keys) {
        Write-Step "$listTitle"
        foreach ($field in $script:Lists[$listTitle].Fields) {
            New-LdpField -ListTitle $listTitle -Field $field
        }
    }

    Write-Host ''
    Write-Host 'PASS 3/5  Lookups' -ForegroundColor Cyan
    foreach ($lookup in $script:Lookups) {
        New-LdpLookup -Lookup $lookup
    }

    Write-Host ''
    if ($SkipIndexes) {
        Write-Host 'PASS 4/5  Indexes — SKIPPED (-SkipIndexes)' -ForegroundColor Yellow
    } else {
        Write-Host 'PASS 4/5  Indexes' -ForegroundColor Cyan
        foreach ($listTitle in $script:Indexes.Keys) {
            foreach ($fieldName in $script:Indexes[$listTitle]) {
                Set-LdpIndex -ListTitle $listTitle -FieldName $fieldName
            }
        }
    }

    }   # end of the -SeedOnly bypass

    Write-Host ''
    if ($SeedCompetencies -or $SeedOnly) {
        Write-Host 'PASS 5/5  Competency data' -ForegroundColor Cyan
        Import-LdpCompetencies -Path $DataPath
    } else {
        Write-Host 'PASS 5/5  Competency data - SKIPPED (pass -SeedCompetencies)' -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host 'Summary' -ForegroundColor Cyan
    foreach ($key in $script:Tally.Keys) {
        Write-Host ("  {0,-16} {1}" -f $key, $script:Tally[$key])
    }

    if (-not $IncludeProposed) {
        Write-Host ''
        Write-Host 'Not created — [PROPOSED], pending DTD confirmation (Constitution I):' -ForegroundColor Yellow
        foreach ($item in $script:ProposedItems) { Write-Host "  - $item" -ForegroundColor Yellow }
        Write-Host '  Re-run with -IncludeProposed once DTD signs off.' -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host 'Still to do by hand:' -ForegroundColor Cyan
    Write-Host '  - Seed PROGRAMS with NEXT / MDP / HPP (DTD-populated per PROGRAMS.md).'
    Write-Host '  - CHANGE_HISTORY must be withheld from applicants via SharePoint permissions,'
    Write-Host '    not hidden controls (Constitution VI / OI-7).'
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
