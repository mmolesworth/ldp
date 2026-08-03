<#
.SYNOPSIS
    Renames SUPERVISOR_ENDORSEMENTS.Decision values from Approve/Disapprove to
    Recommend/Not Recommend. See build/lists/SUPERVISOR_ENDORSEMENTS.md, 2026-08-02.

.DESCRIPTION
    A supervisor does not approve anything. They have no authority to grant a
    place in the programme — DTD and the selection committee decide that. RQ021
    already says the packet advances whichever way the supervisor votes, which
    means "Disapprove" never blocked anything: the column has always held a
    RECOMMENDATION wearing a word that overstates it.

      1. ADD       both new choices alongside the old two, so no row is invalid
                   at any point.
      2. MIGRATE   Approve -> Recommend, Disapprove -> Not Recommend.
      3. PRUNE     remove the old two choices — ONLY with -RemoveOldChoices,
                   and only once nothing still uses them.

    ADD-BEFORE-MIGRATE-BEFORE-PRUNE, for the usual SharePoint reason: replacing
    a Choice column's values outright leaves every existing row holding a value
    the column no longer offers, and Power Apps then refuses to save them.

    Idempotent — a row already holding a new value is skipped, so a re-run
    finishes an interrupted migration.

    NO SCREEN READS THIS COLUMN YET (checked 2026-08-02: no *.yaml in
    build/screens references SUPERVISOR_ENDORSEMENTS). That is why this is
    cheap now and would not be later.

.PARAMETER RemoveOldChoices
    Drops "Approve" and "Disapprove" from the column. Separate on purpose, and
    the only destructive step: run the rest, confirm every row migrated, then
    come back for this.

.EXAMPLE
    ./Update-LdpEndorsementDecision.ps1 -SiteUrl https://... -ClientId <guid> -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [switch]$RemoveOldChoices
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:List = 'SUPERVISOR_ENDORSEMENTS'
$script:Map  = [ordered]@{ 'Approve' = 'Recommend'; 'Disapprove' = 'Not Recommend' }

$script:Tally = [ordered]@{
    ChoicesAdded = 0; RowsMigrated = 0; RowsAlreadyNew = 0; RowsUnknown = 0
    ChoicesRemoved = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

Write-Host ''
Write-Host 'Endorsement decision — a recommendation, not an approval' -ForegroundColor Cyan
Write-Host "  Site        : $SiteUrl"
foreach ($k in $script:Map.Keys) { Write-Host "  Rename      : $k -> $($script:Map[$k])" }
Write-Host "  Old choices : $(if ($RemoveOldChoices) { 'WILL BE REMOVED' } else { 'kept' })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    $field = Get-PnPField -List $script:List -Identity 'Decision'
    [xml]$schema = $field.SchemaXml
    $current = @($schema.Field.CHOICES.CHOICE)
    Write-Host "  Current choices: $($current -join ', ')"
    Write-Host ''

    # --- 1. both vocabularies coexist ---------------------------------------
    Write-Host 'PHASE 1/3  Add the new choices' -ForegroundColor Cyan
    $wanted = @($current) + @($script:Map.Values | Where-Object { $_ -notin $current })
    if ($wanted.Count -eq $current.Count) {
        Write-Kept 'both new choices already present'
    } elseif ($PSCmdlet.ShouldProcess("$script:List.Decision", "Add $($script:Map.Values -join ', ')")) {
        Set-PnPField -List $script:List -Identity 'Decision' -Values @{ Choices = $wanted } | Out-Null
        Write-Made "choices are now: $($wanted -join ', ')"
        $script:Tally.ChoicesAdded++
    }
    Write-Host ''

    # --- 2. move the rows ----------------------------------------------------
    Write-Host 'PHASE 2/3  Migrate existing rows' -ForegroundColor Cyan
    $items = @(Get-PnPListItem -List $script:List -PageSize 500)
    if ($items.Count -eq 0) { Write-Kept 'no rows' }
    foreach ($i in $items) {
        $value = [string]$i['Decision']
        if ($value -in $script:Map.Values) { $script:Tally.RowsAlreadyNew++; continue }
        if (-not $script:Map.Contains($value)) {
            Write-Held "row $($i.Id): unrecognised value '$value' — left for a human"
            $script:Tally.RowsUnknown++
            continue
        }
        $new = $script:Map[$value]
        if ($PSCmdlet.ShouldProcess("$script:List/row $($i.Id)", "$value -> $new")) {
            Set-PnPListItem -List $script:List -Identity $i.Id -Values @{ Decision = $new } | Out-Null
            Write-Made "row $($i.Id): $value -> $new"
            $script:Tally.RowsMigrated++
        }
    }
    Write-Host ''

    # --- 3. drop the old vocabulary -----------------------------------------
    Write-Host 'PHASE 3/3  Remove the old choices' -ForegroundColor Cyan
    if (-not $RemoveOldChoices) {
        Write-Held 'kept — pass -RemoveOldChoices once every row shows a new value'
    } else {
        $stillOld = @(Get-PnPListItem -List $script:List -PageSize 500 |
                      Where-Object { [string]$_['Decision'] -in $script:Map.Keys })
        if ($stillOld.Count -gt 0) {
            Write-Held "$($stillOld.Count) row(s) still hold an old value — NOT removing the choices"
        } elseif ($PSCmdlet.ShouldProcess("$script:List.Decision", 'Remove Approve, Disapprove')) {
            Set-PnPField -List $script:List -Identity 'Decision' `
                         -Values @{ Choices = @($script:Map.Values) } | Out-Null
            Write-Made "choices are now: $($script:Map.Values -join ', ')"
            $script:Tally.ChoicesRemoved++
        }
    }

    Write-Host ''
    Write-Host 'Summary' -ForegroundColor Cyan
    foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-18} {1}" -f $k, $script:Tally[$k]) }
    Write-Host ''
    Write-Host 'Then: refresh SUPERVISOR_ENDORSEMENTS in Power Apps Studio.' -ForegroundColor Yellow
    Write-Host 'RQ018 still says "approve or disapprove" — that wording is now stale;' -ForegroundColor Yellow
    Write-Host 'see OI-SUP-1 in build/OPEN_ISSUES.md.' -ForegroundColor Yellow
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
