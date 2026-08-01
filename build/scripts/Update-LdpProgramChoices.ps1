<#
.SYNOPSIS
    Makes the PROGRAM the thing an applicant chooses, and the OPTION an extra
    detail that only some programs have. Touches APPLICATION_PROGRAM_CHOICES
    and PLACEMENTS. See build/lists/APPLICATION_PROGRAM_CHOICES.md, 2026-07-31.

.DESCRIPTION
    Both lists recorded only ProgramOptionID, and required it. MDP and NEXT
    have no options, so an applicant could not choose them at all until
    Add-LdpProgramOptions.ps1 invented an "N/A" option per program purely to
    satisfy the constraint. This script records what was actually chosen and
    then removes the invention.

      1. ADD       ProgramID to both lists, unrequired.
      2. BACKFILL  ProgramID = the parent program of the row's existing option.
      3. DETACH    blank ProgramOptionID on rows pointing at a placeholder.
                   The program is now recorded directly, so the pointer is
                   noise; and nothing may reference a row we are about to
                   delete.
      4. TIGHTEN   ProgramID Required + indexed; ProgramOptionID NOT required.
      5. REMOVE    delete the placeholder option rows — ONLY with
                   -RemovePlaceholders.

    Unrequired-then-tighten for the usual reason: a Required column added to a
    list with existing rows leaves every one of them invalid, and Power Apps
    then refuses to save them.

    Idempotent — a row that already has a ProgramID is skipped, so a re-run
    finishes an interrupted migration.

    WHAT THIS DELIBERATELY DOES NOT DO:
    It does not touch RATING_SHEETS or COMMITTEE_SCORES. Both already key on
    ProgramID and were always right; they are the reason the choice rows had to
    be dereferenced through their option to be joined at all.

.PARAMETER PlaceholderName
    OptionName that marks a fabricated row. Must match whatever
    Add-LdpProgramOptions.ps1 was run with. Defaults to 'N/A'.

.PARAMETER RemovePlaceholders
    Deletes the placeholder option rows. Separate on purpose, and it is the
    only destructive step here: run the rest, re-paste the screens, confirm
    the choices still read correctly, then come back for this.

.EXAMPLE
    ./Update-LdpProgramChoices.ps1 -SiteUrl https://... -ClientId <guid> -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [string]$PlaceholderName = 'N/A',

    [switch]$RemovePlaceholders,
    [switch]$SkipAddColumns,
    [switch]$SkipBackfill,
    [switch]$SkipTighten
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Both lists get the same treatment; PLACEMENTS is the same defect one table over.
$script:Targets = @(
    @{ List = 'APPLICATION_PROGRAM_CHOICES'; Label = 'ApplicationID' }
    @{ List = 'PLACEMENTS';                  Label = 'ApplicationID' }
)

$script:Tally = [ordered]@{
    ColumnsCreated = 0; ColumnsExisting = 0
    RowsBackfilled = 0; RowsAlreadyDone = 0; RowsUnresolved = 0
    OptionsDetached = 0
    RequiredSet = 0; IndexSet = 0; OptionRelaxed = 0
    PlaceholdersRemoved = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

Write-Host ''
Write-Host 'Program choices — the PROGRAM becomes the choice' -ForegroundColor Cyan
Write-Host "  Site         : $SiteUrl"
Write-Host "  Placeholder  : '$PlaceholderName'"
Write-Host "  Placeholders : $(if ($RemovePlaceholders) { 'WILL BE DELETED' } else { 'kept' })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    # option id -> parent program id. Read once; every backfill row needs it.
    $optionParent = @{}
    $placeholderIds = @()
    foreach ($o in (Get-PnPListItem -List PROGRAM_OPTIONS -PageSize 500)) {
        $parent = $o['ProgramID']
        if ($parent) { $optionParent[[int]$o.Id] = [int]$parent.LookupId }
        if ([string]$o['OptionName'] -eq $PlaceholderName) { $placeholderIds += [int]$o.Id }
    }
    Write-Host "  PROGRAM_OPTIONS : $($optionParent.Count) option(s), $($placeholderIds.Count) placeholder(s)"
    Write-Host ''

    # --- 1. columns ---------------------------------------------------------
    $hasColumn = @{}
    if (-not $SkipAddColumns) { Write-Host 'PHASE 1/5  Columns' -ForegroundColor Cyan }
    foreach ($t in $script:Targets) {
        $have = @{}
        foreach ($f in (Get-PnPField -List $t.List)) { $have[$f.InternalName] = $f }
        $hasColumn[$t.List] = $have.ContainsKey('ProgramID')

        if ($SkipAddColumns) { continue }
        if ($hasColumn[$t.List]) {
            Write-Kept "$($t.List).ProgramID (exists)"
            $script:Tally.ColumnsExisting++
        } elseif ($PSCmdlet.ShouldProcess("$($t.List).ProgramID", 'Add lookup to PROGRAMS')) {
            Add-PnPField -List $t.List -DisplayName 'ProgramID' -InternalName 'ProgramID' `
                         -Type Lookup -AddToDefaultView | Out-Null
            Set-PnPField -List $t.List -Identity 'ProgramID' `
                         -Values @{ LookupList = (Get-PnPList -Identity PROGRAMS).Id.ToString()
                                    LookupField = 'ProgramName' } | Out-Null
            Write-Made "$($t.List).ProgramID -> PROGRAMS.ProgramName"
            $script:Tally.ColumnsCreated++
            $hasColumn[$t.List] = $true
        }
    }
    if (-not $SkipAddColumns) { Write-Host '' }

    # --- 2. backfill + 3. detach placeholders -------------------------------
    if (-not $SkipBackfill) {
        Write-Host 'PHASE 2/5  Backfill ProgramID' -ForegroundColor Cyan
        foreach ($t in $script:Targets) {
            if (-not $hasColumn[$t.List]) {
                Write-Held "$($t.List): ProgramID does not exist yet — expected under -WhatIf"
                continue
            }
            $items = @(Get-PnPListItem -List $t.List -PageSize 500)
            if ($items.Count -eq 0) { Write-Kept "$($t.List): no rows"; continue }

            foreach ($item in $items) {
                $existing = $item['ProgramID']
                if ($existing) { $script:Tally.RowsAlreadyDone++; continue }

                $opt = $item['ProgramOptionID']
                if (-not $opt) {
                    Write-Held "$($t.List) row $($item.Id): no option to derive a program from — left for a human"
                    $script:Tally.RowsUnresolved++
                    continue
                }
                $optId = [int]$opt.LookupId
                if (-not $optionParent.ContainsKey($optId)) {
                    Write-Held "$($t.List) row $($item.Id): option $optId is not in PROGRAM_OPTIONS — left alone"
                    $script:Tally.RowsUnresolved++
                    continue
                }
                $programId = $optionParent[$optId]
                $isPlaceholder = $placeholderIds -contains $optId

                # One write per row: set the program, and drop the pointer at
                # the same moment if it was only ever a placeholder.
                $values = @{ ProgramID = $programId }
                if ($isPlaceholder) { $values['ProgramOptionID'] = $null }

                $what = "Set ProgramID = $programId$(if ($isPlaceholder) { ' and clear placeholder option' })"
                if ($PSCmdlet.ShouldProcess("$($t.List)/row $($item.Id)", $what)) {
                    Set-PnPListItem -List $t.List -Identity $item.Id -Values $values | Out-Null
                    Write-Made "$($t.List) row $($item.Id): program $programId$(if ($isPlaceholder) { ' (placeholder option cleared)' })"
                    $script:Tally.RowsBackfilled++
                    if ($isPlaceholder) { $script:Tally.OptionsDetached++ }
                }
            }
        }
        Write-Host ''
    }

    # --- 4. tighten ---------------------------------------------------------
    if (-not $SkipTighten) {
        Write-Host 'PHASE 3/5  Required + index' -ForegroundColor Cyan
        foreach ($t in $script:Targets) {
            if (-not $hasColumn[$t.List]) {
                Write-Held "$($t.List): skipped — ProgramID does not exist yet"
                continue
            }
            $blank = @(Get-PnPListItem -List $t.List -PageSize 500 | Where-Object { -not $_['ProgramID'] })
            if ($blank.Count -gt 0) {
                Write-Held "$($t.List): $($blank.Count) row(s) have no ProgramID — Required NOT set"
                continue
            }
            if ($PSCmdlet.ShouldProcess("$($t.List).ProgramID", 'Set Required + Indexed')) {
                Set-PnPField -List $t.List -Identity 'ProgramID' -Values @{ Required = $true } | Out-Null
                Set-PnPField -List $t.List -Identity 'ProgramID' -Values @{ Indexed = $true } | Out-Null
                Write-Made "$($t.List).ProgramID is Required and indexed"
                $script:Tally.RequiredSet++; $script:Tally.IndexSet++
            }
            # The whole point: an option is now optional, because most programs
            # do not have any.
            if ($PSCmdlet.ShouldProcess("$($t.List).ProgramOptionID", 'Set NOT Required')) {
                Set-PnPField -List $t.List -Identity 'ProgramOptionID' -Values @{ Required = $false } | Out-Null
                Write-Made "$($t.List).ProgramOptionID is optional"
                $script:Tally.OptionRelaxed++
            }
        }
        Write-Host ''
    }

    # --- 5. delete the fabricated rows --------------------------------------
    Write-Host 'PHASE 4/5  Placeholder options' -ForegroundColor Cyan
    if ($placeholderIds.Count -eq 0) {
        Write-Kept "no options named '$PlaceholderName'"
    } elseif (-not $RemovePlaceholders) {
        Write-Held "$($placeholderIds.Count) placeholder(s) kept — pass -RemovePlaceholders once the screens no longer read them"
    } else {
        foreach ($id in $placeholderIds) {
            # Refuse to orphan anything. After phase 2 nothing should point
            # here, but a row this script could not resolve still might.
            $refs = 0
            foreach ($t in $script:Targets) {
                $refs += @(Get-PnPListItem -List $t.List -PageSize 500 |
                           Where-Object { $_['ProgramOptionID'] -and [int]$_['ProgramOptionID'].LookupId -eq $id }).Count
            }
            if ($refs -gt 0) {
                Write-Held "option $id still has $refs reference(s) — NOT deleted"
                continue
            }
            if ($PSCmdlet.ShouldProcess("PROGRAM_OPTIONS/$id", 'Delete placeholder')) {
                Remove-PnPListItem -List PROGRAM_OPTIONS -Identity $id -Force | Out-Null
                Write-Made "deleted placeholder option $id"
                $script:Tally.PlaceholdersRemoved++
            }
        }
    }

    Write-Host ''
    Write-Host 'PHASE 5/5  Summary' -ForegroundColor Cyan
    foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-22} {1}" -f $k, $script:Tally[$k]) }
    Write-Host ''
    Write-Host 'Then: refresh APPLICATION_PROGRAM_CHOICES, PLACEMENTS and PROGRAM_OPTIONS' -ForegroundColor Yellow
    Write-Host 'in Power Apps Studio, and re-paste the DTD Applications screen.' -ForegroundColor Yellow
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
