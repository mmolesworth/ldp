<#
.SYNOPSIS
    Renames the ReviewStage and PlacementOutcome choice values to their explicit
    forms, and adds the Pending Notification stage.
    See build/lists/_CHOICES.md (2026-07-31, second revision).

.DESCRIPTION
    Three phases, in this order and for this reason:

      1. WIDEN    set each column's choices to the UNION of old and new. Every
                  existing row stays valid while the rewrite happens.
      2. REWRITE  map each row's old value to its new one.
      3. NARROW   set the choices to the final set, dropping the old values.

    Doing it the other way round — final choices first — leaves every existing
    row holding a value the column no longer accepts. SharePoint keeps the text
    but the item is invalid, and Power Apps then refuses to save it.

    ApplicationStatus is UNCHANGED (Draft / Submitted / Withdrawn). "Submitted"
    under a column headed "Application status" already says what it means; the
    prefix would only cost width in every pill, filter and list view.

    Idempotent: a row already holding a new value is skipped, so a re-run
    finishes an interrupted migration.

.EXAMPLE
    ./Update-LdpStatusLabels.ps1 -SiteUrl https://... -ClientId <guid> -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [switch]$IncludeProposed
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Every historical value -> the current one. Two rounds of renaming happened,
# so a row may hold EITHER the original wording or the intermediate one that
# was briefly published before the names were shortened. Both are mapped, so a
# list that is half-migrated lands correctly whichever state each row is in.
$script:StageMap = [ordered]@{
    # original set, created by Update-LdpApplicationStatus.ps1
    'Pending First Line'              = 'Pending First-Line'
    'Pending Second Line'             = 'Pending Second-Line'
    'Pending Validation'              = 'Pending DTD Validation'
    'In Committee'                    = 'Committee Review'
    'Pending Decision'                = 'Pending Placement'
    'Closed'                          = 'Complete'
    'Held For Alternate'              = 'Needs Supervisor Assigned'
    # intermediate set, from the first build of THIS script
    'Pending First-Line Endorsement'  = 'Pending First-Line'
    'Pending Second-Line Endorsement' = 'Pending Second-Line'
    'In Committee Review'             = 'Committee Review'
    'Pending Placement Decision'      = 'Pending Placement'
    'Needs Reviewer Assigned'         = 'Needs Supervisor Assigned'
}
$script:OutcomeMap = [ordered]@{
    'Pending'  = 'Decision Pending'
    'Declined' = 'Placement Declined'
}

# Pending Notification is NEW — no old value maps to it. It sits between the
# decision and the close, because DTD cannot notify an applicant without
# knowing what they are being told, and "decided but not yet notified" is a
# queue that otherwise lives in somebody's head.
$script:StageFinal = @(
    'Pending First-Line'
    'Pending Second-Line'
    'Pending DTD Validation'
    'Committee Review'
    'Pending Placement'
    'Pending Notification'
    'Complete'
)
if ($IncludeProposed) { $script:StageFinal += 'Needs Supervisor Assigned' }

$script:OutcomeFinal = @('Decision Pending', 'Placed', 'Not Selected', 'Placement Declined')

$script:Tally = [ordered]@{
    ChoicesWidened = 0; RowsRewritten = 0; RowsAlreadyNew = 0; RowsUnmapped = 0; ChoicesNarrowed = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

Write-Host ''
Write-Host 'APPLICATIONS status label migration' -ForegroundColor Cyan
Write-Host "  Site           : $SiteUrl"
Write-Host "  Proposed value : $(if ($IncludeProposed) { 'Needs Supervisor Assigned INCLUDED' } else { 'withheld (Constitution I)' })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    $have = @{}
    foreach ($f in (Get-PnPField -List APPLICATIONS)) { $have[$f.InternalName] = $f }
    foreach ($n in 'ReviewStage', 'PlacementOutcome') {
        if (-not $have.ContainsKey($n)) {
            throw "$n does not exist. Run Update-LdpApplicationStatus.ps1 first."
        }
    }

    # --- 1. widen ----------------------------------------------------------
    Write-Host 'PHASE 1/3  Widen choices' -ForegroundColor Cyan
    $stageUnion   = @($script:StageMap.Keys) + $script:StageFinal | Select-Object -Unique
    $outcomeUnion = @($script:OutcomeMap.Keys) + $script:OutcomeFinal | Select-Object -Unique

    foreach ($pair in @(
        @{ Name = 'ReviewStage';      Union = $stageUnion },
        @{ Name = 'PlacementOutcome'; Union = $outcomeUnion })) {
        if ($PSCmdlet.ShouldProcess("APPLICATIONS.$($pair.Name)", 'Widen choices')) {
            Set-PnPField -List APPLICATIONS -Identity $pair.Name `
                         -Values @{ Choices = [string[]]$pair.Union } | Out-Null
            Write-Made "$($pair.Name) accepts $($pair.Union.Count) value(s) during the rewrite"
            $script:Tally.ChoicesWidened++
        }
    }
    Write-Host ''

    # --- 2. rewrite ---------------------------------------------------------
    Write-Host 'PHASE 2/3  Rows' -ForegroundColor Cyan
    $items = Get-PnPListItem -List APPLICATIONS -PageSize 500
    if ($items.Count -eq 0) { Write-Host '  no rows' -ForegroundColor DarkGray }

    foreach ($item in $items) {
        $stage   = [string]$item['ReviewStage']
        $outcome = [string]$item['PlacementOutcome']
        $values  = @{}

        if ($stage -and $script:StageMap.Contains($stage)) {
            $values['ReviewStage'] = $script:StageMap[$stage]
        } elseif ($stage -and $script:StageFinal -notcontains $stage) {
            Write-Held "row $($item.Id): ReviewStage '$stage' is not in the map — left alone"
            $script:Tally.RowsUnmapped++
        }

        if ($outcome -and $script:OutcomeMap.Contains($outcome)) {
            $values['PlacementOutcome'] = $script:OutcomeMap[$outcome]
        } elseif ($outcome -and $script:OutcomeFinal -notcontains $outcome) {
            Write-Held "row $($item.Id): PlacementOutcome '$outcome' is not in the map — left alone"
            $script:Tally.RowsUnmapped++
        }

        if ($values.Count -eq 0) {
            $script:Tally.RowsAlreadyNew++
            continue
        }

        $who = [string]$item['ApplicantName']
        if ($PSCmdlet.ShouldProcess("APPLICATIONS/$who", 'Rewrite choice values')) {
            Set-PnPListItem -List APPLICATIONS -Identity $item.Id -Values $values | Out-Null
            $shown = ($values.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
            Write-Made "$who : $shown"
            $script:Tally.RowsRewritten++
        }
    }
    Write-Host ''

    # --- 3. narrow ----------------------------------------------------------
    Write-Host 'PHASE 3/3  Narrow choices' -ForegroundColor Cyan
    $leftOver = @(Get-PnPListItem -List APPLICATIONS -PageSize 500 | Where-Object {
        ([string]$_['ReviewStage']      -and $script:StageFinal   -notcontains [string]$_['ReviewStage']) -or
        ([string]$_['PlacementOutcome'] -and $script:OutcomeFinal -notcontains [string]$_['PlacementOutcome'])
    })
    if ($leftOver.Count -gt 0) {
        Write-Held "$($leftOver.Count) row(s) still hold an old value — choices NOT narrowed"
        Write-Held 'Fix those rows, then re-run. Narrowing now would leave them invalid.'
    } else {
        foreach ($pair in @(
            @{ Name = 'ReviewStage';      Final = $script:StageFinal },
            @{ Name = 'PlacementOutcome'; Final = $script:OutcomeFinal })) {
            if ($PSCmdlet.ShouldProcess("APPLICATIONS.$($pair.Name)", 'Narrow to the final choices')) {
                Set-PnPField -List APPLICATIONS -Identity $pair.Name `
                             -Values @{ Choices = [string[]]$pair.Final } | Out-Null
                Write-Made "$($pair.Name) -> $($pair.Final -join ' | ')"
                $script:Tally.ChoicesNarrowed++
            }
        }
    }

    Write-Host ''
    Write-Host 'Summary' -ForegroundColor Cyan
    foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-16} {1}" -f $k, $script:Tally[$k]) }
    Write-Host ''
    Write-Host 'Then: refresh APPLICATIONS in Power Apps Studio and re-paste both screens.' -ForegroundColor Yellow
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
