#Requires -Version 7.2
<#
.SYNOPSIS
    Provisions the 14 SharePoint lists for the LDP Application (Phase I).

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
    Target site, e.g. https://markmolesworth.sharepoint.com/sites/leadership-development-program

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
    ./New-LdpSharePointLists.ps1 -SiteUrl https://markmolesworth.sharepoint.com/sites/leadership-development-program -ClientId <your-client-id> -WhatIf

.EXAMPLE
    ./New-LdpSharePointLists.ps1 -SiteUrl https://markmolesworth.sharepoint.com/sites/leadership-development-program -ClientId <your-client-id>

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
    'APPLICATIONS.RoutingStage → "Held For Alternate"            — R5'
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
            @{ Name = 'ProgramName'; Type = 'Text'; Required = $true }
            @{ Name = 'Description'; Type = 'Note' }
            @{ Name = 'State';       Type = 'Choice'; Required = $true; Choices = @('Active', 'Retired') }
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

    'APPLICATIONS' = @{
        Description = 'The central application record. Supporting documents are native SharePoint attachments.'
        Fields      = @(
            @{ Name = 'ApplicantEmail';           Type = 'Text';   Required = $true }
            @{ Name = 'ApplicantName';            Type = 'Text';   Required = $true }
            @{ Name = 'Location';                 Type = 'Text' }
            @{ Name = 'Grade';                    Type = 'Text' }
            @{ Name = 'JobSeries';                Type = 'Text' }
            @{ Name = 'JobTitle';                 Type = 'Text' }
            # Type pending Appendix B (D-2) — may become multi-select Choice.
            @{ Name = 'OPMCompetencies';          Type = 'Note' }
            @{ Name = 'TechnicalCompetencies';    Type = 'Note' }
            @{ Name = 'ECQs';                     Type = 'Note' }
            @{ Name = 'ListedOnIDP';              Type = 'Choice'; Choices = @('Yes', 'No') }
            @{ Name = 'LatestPerformanceRating';  Type = 'Number' }
            @{ Name = 'AttendedInfoSession';      Type = 'Choice'; Choices = @('Yes', 'No') }
            @{ Name = 'InfoSessionDate';          Type = 'Date' }
            @{ Name = 'NCUAStartDate';            Type = 'Date' }
            @{ Name = 'ServiceComputationDate';   Type = 'Date' }
            @{ Name = 'Status';                   Type = 'Choice'; Required = $true; Choices = @('Draft', 'Submitted', 'Complete', 'Incomplete', 'Placed', 'Not Selected') }
            @{ Name = 'FirstLineSupervisorEmail'; Type = 'Text' }
            @{ Name = 'SecondLineSupervisorEmail'; Type = 'Text' }
            @{ Name = 'AlternateSecondLineEmail'; Type = 'Text'; Proposed = $true }
            @{ Name = 'RoutingStage';             Type = 'Choice'
               Choices         = @('Pending First Line', 'Pending Second Line', 'Pending Validation', 'In Committee', 'Closed')
               ProposedChoices = @('Held For Alternate') }
            @{ Name = 'RevalidationFlag';         Type = 'Choice'; Choices = @('Yes', 'No') }
        )
    }

    'APPLICATION_PROGRAM_CHOICES' = @{
        Description = 'Ranked program-option selections (join of APPLICATIONS x PROGRAM_OPTIONS).'
        Fields      = @(
            @{ Name = 'Rank'; Type = 'Number'; Required = $true }
        )
    }

    'SUPERVISOR_ENDORSEMENTS' = @{
        Description = 'Supervisor endorsement decisions, statements, and advisory program recommendations.'
        Fields      = @(
            @{ Name = 'SupervisorEmail';      Type = 'Text';   Required = $true }
            @{ Name = 'SupervisorLevel';      Type = 'Choice'; Required = $true
               Choices         = @('First Line', 'Second Line')
               ProposedChoices = @('Alternate Second Line') }
            @{ Name = 'Decision';             Type = 'Choice'; Required = $true; Choices = @('Approve', 'Disapprove') }
            @{ Name = 'DispositionStatement'; Type = 'Note';   Required = $true }
            @{ Name = 'RecommendedOptions';   Type = 'Note' }
            @{ Name = 'DecisionDate';         Type = 'Date';   Required = $true }
        )
    }

    'CRITERION_CATALOG' = @{
        Description = 'Shared master set of scoring criteria, reusable across programs and cycles.'
        Fields      = @(
            @{ Name = 'CriterionCode'; Type = 'Text';   Required = $true }
            @{ Name = 'CriterionName'; Type = 'Text';   Required = $true }
            @{ Name = 'Description';   Type = 'Note';   Required = $true }
            @{ Name = 'State';         Type = 'Choice'; Required = $true; Choices = @('Draft', 'Published') }
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
        Description = 'Committee rating sheets — immutably versioned, per program per cycle. Versions are rows (R3).'
        Fields      = @(
            @{ Name = 'SheetVersion'; Type = 'Number'; Required = $true }
            @{ Name = 'State';       Type = 'Choice'; Required = $true; Choices = @('Draft', 'Published') }
            @{ Name = 'IsCurrent';   Type = 'Choice'; Required = $true; Choices = @('Yes', 'No') }
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

    'COMMITTEE_SCORES' = @{
        Description = 'Applicant score per program. FinalScore/PercentOfPossible queryable; breakdown is JSON.'
        Fields      = @(
            @{ Name = 'FinalScore';        Type = 'Number'; Required = $true }
            @{ Name = 'PercentOfPossible'; Type = 'Number' }
            @{ Name = 'CriterionScores';   Type = 'Note' }   # JSON — plain text, see Set-FieldTweak
            @{ Name = 'Rank';              Type = 'Number' }
            @{ Name = 'ScoredBy';          Type = 'Text' }
            @{ Name = 'ScoredDate';        Type = 'Date' }
        )
    }

    'PLACEMENTS' = @{
        Description = 'DTD placement of an applicant into a program option within a cycle.'
        Fields      = @(
            @{ Name = 'PlacedBy';    Type = 'Text';   Required = $true }
            @{ Name = 'PlacedDate';  Type = 'Date';   Required = $true }
            @{ Name = 'IsFinalized'; Type = 'Choice'; Required = $true; Choices = @('Yes', 'No') }
        )
    }

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
    @{ List = 'APPLICATIONS';                Name = 'CycleID';            Target = 'CYCLES';             ShowField = 'CycleName';     Required = $true }
    @{ List = 'APPLICATION_PROGRAM_CHOICES'; Name = 'ApplicationID';      Target = 'APPLICATIONS';       ShowField = 'ApplicantEmail'; Required = $true }
    @{ List = 'APPLICATION_PROGRAM_CHOICES'; Name = 'ProgramOptionID';    Target = 'PROGRAM_OPTIONS';    ShowField = 'OptionName';    Required = $true }
    @{ List = 'SUPERVISOR_ENDORSEMENTS';     Name = 'ApplicationID';      Target = 'APPLICATIONS';       ShowField = 'ApplicantEmail'; Required = $true }
    @{ List = 'RATING_SHEETS';               Name = 'CycleID';            Target = 'CYCLES';             ShowField = 'CycleName';     Required = $true }
    @{ List = 'RATING_SHEETS';               Name = 'ProgramID';          Target = 'PROGRAMS';           ShowField = 'ProgramName';   Required = $true }
    @{ List = 'RATING_CRITERIA';             Name = 'RatingSheetID';      Target = 'RATING_SHEETS';      ShowField = 'ID';            Required = $true }
    @{ List = 'RATING_CRITERIA';             Name = 'CatalogCriterionID'; Target = 'CRITERION_CATALOG';  ShowField = 'CriterionCode'; Required = $true }
    @{ List = 'CRITERION_ANCHORS';           Name = 'CatalogCriterionID'; Target = 'CRITERION_CATALOG';  ShowField = 'CriterionCode'; Required = $true }
    @{ List = 'COMMITTEE_SCORES';            Name = 'ApplicationID';      Target = 'APPLICATIONS';       ShowField = 'ApplicantEmail'; Required = $true }
    @{ List = 'COMMITTEE_SCORES';            Name = 'ProgramID';          Target = 'PROGRAMS';           ShowField = 'ProgramName';   Required = $true }
    @{ List = 'COMMITTEE_SCORES';            Name = 'RatingSheetID';      Target = 'RATING_SHEETS';      ShowField = 'ID';            Required = $true }
    @{ List = 'PLACEMENTS';                  Name = 'ApplicationID';      Target = 'APPLICATIONS';       ShowField = 'ApplicantEmail'; Required = $true }
    @{ List = 'PLACEMENTS';                  Name = 'ProgramOptionID';    Target = 'PROGRAM_OPTIONS';    ShowField = 'OptionName';    Required = $true }
    @{ List = 'PLACEMENTS';                  Name = 'CycleID';            Target = 'CYCLES';             ShowField = 'CycleName';     Required = $true }
)

# ---------------------------------------------------------------------------
# PASS 4 — indexes (Constitution III)
# ---------------------------------------------------------------------------
$script:Indexes = [ordered]@{
    'APPLICATIONS'                = @('CycleID', 'ApplicantEmail', 'Status', 'RoutingStage')
    'APPLICATION_PROGRAM_CHOICES' = @('ApplicationID', 'ProgramOptionID')
    'SUPERVISOR_ENDORSEMENTS'     = @('ApplicationID')
    'RATING_SHEETS'               = @('CycleID', 'ProgramID', 'IsCurrent')
    'RATING_CRITERIA'             = @('RatingSheetID')
    'CRITERION_CATALOG'           = @('State')
    'CRITERION_ANCHORS'           = @('CatalogCriterionID')
    'COMMITTEE_SCORES'            = @('ApplicationID', 'ProgramID', 'RatingSheetID')
    'PLACEMENTS'                  = @('ApplicationID', 'ProgramOptionID', 'CycleID')
    'NOTIFICATIONS'               = @('ApplicationID')
    'CHANGE_HISTORY'              = @('ApplicationID')
    'CYCLES'                      = @('State')
    'PROGRAM_OPTIONS'             = @('ProgramID', 'State')
    'PROGRAMS'                    = @('State')
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
$script:Tally = [ordered]@{ ListsCreated = 0; ListsExisting = 0; FieldsCreated = 0; FieldsExisting = 0; LookupsCreated = 0; IndexesSet = 0; Skipped = 0 }

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
            # Plain text, not rich text: CriterionScores/Details hold JSON, and rich
            # text wraps values in markup that Power Fx would have to strip.
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
    $defaultView = Get-PnPView -List $listTitle | Where-Object { $_.DefaultView } | Select-Object -First 1
    if ($defaultView) {
        Add-PnPViewField -List $listTitle -Identity $defaultView.Title -Field $name -ErrorAction SilentlyContinue | Out-Null
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
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    $web = Get-PnPWeb
    Write-Host "Connected to '$($web.Title)'" -ForegroundColor Cyan
    Write-Host ''

    Write-Host 'PASS 1/4  Lists' -ForegroundColor Cyan
    foreach ($listTitle in $script:Lists.Keys) {
        New-LdpList -Title $listTitle -Description $script:Lists[$listTitle].Description
    }

    Write-Host ''
    Write-Host 'PASS 2/4  Columns' -ForegroundColor Cyan
    foreach ($listTitle in $script:Lists.Keys) {
        Write-Step "$listTitle"
        foreach ($field in $script:Lists[$listTitle].Fields) {
            New-LdpField -ListTitle $listTitle -Field $field
        }
    }

    Write-Host ''
    Write-Host 'PASS 3/4  Lookups' -ForegroundColor Cyan
    foreach ($lookup in $script:Lookups) {
        New-LdpLookup -Lookup $lookup
    }

    Write-Host ''
    if ($SkipIndexes) {
        Write-Host 'PASS 4/4  Indexes — SKIPPED (-SkipIndexes)' -ForegroundColor Yellow
    } else {
        Write-Host 'PASS 4/4  Indexes' -ForegroundColor Cyan
        foreach ($listTitle in $script:Indexes.Keys) {
            foreach ($fieldName in $script:Indexes[$listTitle]) {
                Set-LdpIndex -ListTitle $listTitle -FieldName $fieldName
            }
        }
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
