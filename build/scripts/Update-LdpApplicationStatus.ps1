<#
.SYNOPSIS
    Migrates APPLICATIONS from one Status column to three: ApplicationStatus,
    ReviewStage and PlacementOutcome. See build/lists/_CHOICES.md (2026-07-31).

.DESCRIPTION
    Five phases, each independently skippable so a partial run can be resumed:

      1. ADD       the three new columns, NOT required.
      2. POPULATE  them from the old Status / RoutingStage, per the map below.
      3. REQUIRE   set ApplicationStatus and PlacementOutcome to Required.
      4. INDEX     ApplicationStatus, ReviewStage, PlacementOutcome.
      5. REMOVE    the old Status and RoutingStage — ONLY with -RemoveOldColumns.

    WHY THE COLUMNS ARE ADDED UNREQUIRED AND TIGHTENED LATER:
    A Required column added to a list that already has rows leaves every one of
    those rows invalid, and SharePoint will then refuse edits to them through
    the app. Adding unrequired, filling every row, and only then setting
    Required means the constraint is never true-but-violated.

    THE MAP (build/lists/APPLICATIONS.md):

      Old Status     ApplicationStatus  PlacementOutcome  ReviewStage
      ------------   -----------------  ----------------  --------------------
      Draft          Draft              Decision Pending  (blank)
      Submitted      Submitted          Decision Pending  copy RoutingStage
      Complete       Submitted          Decision Pending  copy RoutingStage
      Incomplete     Submitted          Decision Pending  copy RoutingStage
      Placed         Submitted          Placed            Complete
      Not Selected   Submitted          Not Selected      Complete

    Complete and Incomplete both become Submitted: neither described the
    applicant's progress, which is all ApplicationStatus now means.

    Idempotent. A column that exists is left alone; a row already carrying an
    ApplicationStatus is not rewritten, so re-running finishes an interrupted
    migration rather than trampling hand-corrected rows.

.PARAMETER RemoveOldColumns
    Drops Status and RoutingStage. DESTRUCTIVE, and separate on purpose — the
    Power Apps screens still read them until they are re-pasted. Run the rest
    first, update the app, confirm, then come back for this.

.PARAMETER IncludeProposed
    Adds 'Needs Supervisor Assigned' to ReviewStage. [PROPOSED — FR-012a],
    withheld by default (Constitution I).

.EXAMPLE
    ./Update-LdpApplicationStatus.ps1 -SiteUrl https://... -ClientId <guid> -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [switch]$IncludeProposed,
    [switch]$RemoveOldColumns,

    [switch]$SkipAddColumns,
    [switch]$SkipPopulate,
    [switch]$SkipRequired,
    [switch]$SkipIndexes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ReviewStageChoices = @(
    'Pending First-Line', 'Pending Second-Line', 'Pending DTD Validation',
    'Committee Review', 'Pending Placement', 'Pending Notification', 'Complete'
)
if ($IncludeProposed) { $script:ReviewStageChoices += 'Needs Supervisor Assigned' }

$script:NewColumns = @(
    @{ Name = 'ApplicationStatus'; Choices = @('Draft', 'Submitted', 'Withdrawn'); Require = $true }
    @{ Name = 'PlacementOutcome';  Choices = @('Decision Pending', 'Placed', 'Not Selected', 'Placement Declined'); Require = $true }
    @{ Name = 'ReviewStage';       Choices = $script:ReviewStageChoices; Require = $false }
)

$script:Tally = [ordered]@{
    ColumnsCreated = 0; ColumnsExisting = 0
    RowsMigrated = 0; RowsAlreadyDone = 0; RowsUnmapped = 0
    RequiredSet = 0; IndexesSet = 0; ColumnsRemoved = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m (exists)" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

# The map, keyed by the old Status value.
function Get-Mapping {
    param([string]$OldStatus, [string]$OldStage)

    switch ($OldStatus) {
        'Draft'        { return @{ App = 'Draft';     Placement = 'Decision Pending'; Stage = '' } }
        'Submitted'    { return @{ App = 'Submitted'; Placement = 'Decision Pending'; Stage = $OldStage } }
        'Complete'     { return @{ App = 'Submitted'; Placement = 'Decision Pending'; Stage = $OldStage } }
        'Incomplete'   { return @{ App = 'Submitted'; Placement = 'Decision Pending'; Stage = $OldStage } }
        'Placed'       { return @{ App = 'Submitted'; Placement = 'Placed';           Stage = 'Complete' } }
        'Not Selected' { return @{ App = 'Submitted'; Placement = 'Not Selected';     Stage = 'Complete' } }
        default        { return $null }
    }
}

Write-Host ''
Write-Host 'APPLICATIONS status migration' -ForegroundColor Cyan
Write-Host "  Site           : $SiteUrl"
Write-Host "  Proposed value : $(if ($IncludeProposed) { 'Needs Supervisor Assigned INCLUDED' } else { 'withheld (Constitution I)' })"
Write-Host "  Old columns    : $(if ($RemoveOldColumns) { 'WILL BE REMOVED' } else { 'kept' })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    $fields = Get-PnPField -List APPLICATIONS
    $have   = @{}
    foreach ($f in $fields) { $have[$f.InternalName] = $f }

    # --- 1. add the columns, unrequired -------------------------------------
    if (-not $SkipAddColumns) {
        Write-Host 'PHASE 1/5  Columns' -ForegroundColor Cyan
        foreach ($c in $script:NewColumns) {
            if ($have.ContainsKey($c.Name)) {
                Write-Kept $c.Name
                $script:Tally.ColumnsExisting++
                continue
            }
            if ($PSCmdlet.ShouldProcess("APPLICATIONS.$($c.Name)", 'Add choice column')) {
                Add-PnPField -List APPLICATIONS -DisplayName $c.Name -InternalName $c.Name `
                             -Type Choice -Choices $c.Choices -AddToDefaultView | Out-Null
                Write-Made "$($c.Name)  [$($c.Choices -join ', ')]"
                $script:Tally.ColumnsCreated++
            }
        }
        $fields = Get-PnPField -List APPLICATIONS
        $have   = @{}
        foreach ($f in $fields) { $have[$f.InternalName] = $f }
        Write-Host ''
    }

    # Under -WhatIf phase 1 did NOT really add the columns, so nothing below
    # may read them off a row — CSOM throws "property or field has not been
    # initialized" for a field the list does not have. Every later phase checks
    # this rather than assuming phase 1 succeeded.
    $newColumnsExist = $have.ContainsKey('ApplicationStatus')

    # --- 2. populate --------------------------------------------------------
    if (-not $SkipPopulate) {
        Write-Host 'PHASE 2/5  Rows' -ForegroundColor Cyan

        if (-not $newColumnsExist -and -not $WhatIfPreference) {
            throw 'ApplicationStatus does not exist. Run phase 1 first (drop -SkipAddColumns).'
        }
        if (-not $newColumnsExist) {
            Write-Held 'columns not created in a dry run — showing the plan from Status alone'
        }

        if (-not $have.ContainsKey('Status')) {
            Write-Held 'Status column is already gone — nothing to migrate from'
        } else {
            $items = Get-PnPListItem -List APPLICATIONS -PageSize 500
            if ($items.Count -eq 0) { Write-Host '  no rows' -ForegroundColor DarkGray }

            foreach ($item in $items) {
                # A row that already has an ApplicationStatus was migrated on an
                # earlier run, or corrected by hand. Either way, leave it.
                # Only ask when the column is actually there.
                if ($newColumnsExist -and [string]$item['ApplicationStatus']) {
                    $script:Tally.RowsAlreadyDone++
                    continue
                }

                # PnP returns a Choice as a plain STRING (a Lookup is an object).
                # See build/CONVENTIONS.md — the mirror image of Power Fx.
                $oldStatus = [string]$item['Status']
                $oldStage  = if ($have.ContainsKey('RoutingStage')) { [string]$item['RoutingStage'] } else { '' }

                $map = Get-Mapping -OldStatus $oldStatus -OldStage $oldStage
                if (-not $map) {
                    Write-Held "row $($item.Id) has Status '$oldStatus' — not in the map, left untouched"
                    $script:Tally.RowsUnmapped++
                    continue
                }

                $values = @{
                    ApplicationStatus = $map.App
                    PlacementOutcome  = $map.Placement
                }
                # An empty ReviewStage is legitimate — it is what a Draft has —
                # so only write the column when there is something to write.
                if ($map.Stage) { $values['ReviewStage'] = $map.Stage }

                $who = [string]$item['ApplicantName']
                if ($PSCmdlet.ShouldProcess("APPLICATIONS/$who", "Migrate '$oldStatus'")) {
                    Set-PnPListItem -List APPLICATIONS -Identity $item.Id -Values $values | Out-Null
                    Write-Made "$who : $oldStatus -> $($map.App) / $($map.Placement)$(if ($map.Stage) { " / $($map.Stage)" })"
                    $script:Tally.RowsMigrated++
                }
            }
        }
        Write-Host ''
    }

    # --- 3. tighten to Required ---------------------------------------------
    # AFTER populating, never before: a Required column on rows that do not yet
    # satisfy it leaves them invalid and blocks edits through the app.
    if (-not $SkipRequired) {
        Write-Host 'PHASE 3/5  Required' -ForegroundColor Cyan
        # NOT  $blank = if (...) { @() } else { @() }
        # A statement block that emits an EMPTY collection assigns $null, not an
        # empty array — so $blank.Count then throws under Set-StrictMode. Direct
        # assignment keeps the array.
        $blank = @()
        if ($newColumnsExist) {
            $blank = @(Get-PnPListItem -List APPLICATIONS -PageSize 500 |
                       Where-Object { -not [string]$_['ApplicationStatus'] })
        }

        if (-not $newColumnsExist) {
            Write-Held 'columns do not exist yet — nothing to tighten (expected under -WhatIf)'
        } elseif ($blank.Count -gt 0) {
            Write-Held "$($blank.Count) row(s) still have no ApplicationStatus — Required NOT set"
            Write-Held 'Fix those rows first, then re-run with -SkipAddColumns -SkipPopulate'
        } else {
            foreach ($c in $script:NewColumns | Where-Object { $_.Require }) {
                if ($PSCmdlet.ShouldProcess("APPLICATIONS.$($c.Name)", 'Set Required')) {
                    Set-PnPField -List APPLICATIONS -Identity $c.Name -Values @{ Required = $true } | Out-Null
                    Write-Made "$($c.Name) is now Required"
                    $script:Tally.RequiredSet++
                }
            }
        }
        Write-Host ''
    }

    # --- 4. indexes ---------------------------------------------------------
    if (-not $SkipIndexes) {
        Write-Host 'PHASE 4/5  Indexes' -ForegroundColor Cyan
        if (-not $newColumnsExist) { Write-Held 'columns do not exist yet — skipped' }
        foreach ($n in $(if ($newColumnsExist) { 'ApplicationStatus', 'ReviewStage', 'PlacementOutcome' } else { @() })) {
            if ($PSCmdlet.ShouldProcess("APPLICATIONS.$n", 'Set Indexed')) {
                Set-PnPField -List APPLICATIONS -Identity $n -Values @{ Indexed = $true } | Out-Null
                Write-Made "index $n"
                $script:Tally.IndexesSet++
            }
        }
        Write-Host ''
    }

    # --- 5. drop the old columns -------------------------------------------
    Write-Host 'PHASE 5/5  Old columns' -ForegroundColor Cyan
    if (-not $RemoveOldColumns) {
        Write-Held 'kept — pass -RemoveOldColumns once the app no longer reads them'
    } else {
        if (-not $newColumnsExist) {
            throw 'Refusing to remove Status: the replacement columns do not exist yet.'
        }
        $stillBlank = @(Get-PnPListItem -List APPLICATIONS -PageSize 500 |
                        Where-Object { -not [string]$_['ApplicationStatus'] })
        if ($stillBlank.Count -gt 0) {
            throw "Refusing to remove Status: $($stillBlank.Count) row(s) have no ApplicationStatus. Their old value would be lost with nothing to recover it from."
        }
        foreach ($n in 'Status', 'RoutingStage') {
            if (-not $have.ContainsKey($n)) { Write-Kept "$n already removed"; continue }
            if ($PSCmdlet.ShouldProcess("APPLICATIONS.$n", 'Remove column')) {
                Remove-PnPField -List APPLICATIONS -Identity $n -Force | Out-Null
                Write-Made "removed $n"
                $script:Tally.ColumnsRemoved++
            }
        }
    }

    Write-Host ''
    Write-Host 'Summary' -ForegroundColor Cyan
    foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-18} {1}" -f $k, $script:Tally[$k]) }

    Write-Host ''
    Write-Host 'Next:' -ForegroundColor Cyan
    Write-Host '  1. Refresh the APPLICATIONS data source in Power Apps Studio. Without this the'
    Write-Host '     app keeps its cached schema and will not see the new columns.'
    Write-Host '  2. Update the screens that still write Status / RoutingStage (Application Screen)'
    Write-Host '     and read them (DTD Applications Screen).'
    Write-Host '  3. Only then re-run with -RemoveOldColumns.'
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
