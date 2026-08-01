<#
.SYNOPSIS
    Replaces the three free-text competency columns on APPLICATIONS with an
    APPLICATION_COMPETENCIES join list, and makes the per-type selection limit
    data rather than code. See build/lists/APPLICATION_COMPETENCIES.md.

.DESCRIPTION
    APPLICATIONS carried OPMCompetencies, TechnicalCompetencies and ECQs as
    "Multiple lines of text" — one column per competency type. That cannot
    survive the types being data-driven: the Competencies admin screen lets DTD
    add a fourth type, and there is no column for it. Same defect that
    APPLICATION_PROGRAM_CHOICES had one table over, and the same fix.

      1. LIMITS   add COMPETENCY_TYPES.SelectionCount and seed it — OPM 3,
                  Technical 3, ECQ 4, per RQ006/RQ007/RQ008. A MAXIMUM, not a
                  required count; no requirement states a minimum.
      2. LIST     create APPLICATION_COMPETENCIES with its two lookups and
                  indexes, and make the built-in Title column optional — a
                  GenericList requires it, nothing here populates it, and a
                  required Title makes every Power Fx write fail. Re-running
                  repairs a list created before this step existed.
      3. CHECK    report any application still holding text in the old columns.
      4. REMOVE   drop the three text columns — ONLY with -RemoveOldColumns.

    WHY PHASE 3 REPORTS RATHER THAN MIGRATES:
    Nothing has ever written those columns — step 3 of the applicant form has
    been a placeholder with no controls since it was built (blocker D-2), so
    they are empty on every row including the test data. If a row does hold
    text, matching free text back to catalogue entries is guesswork, and
    guessing here would fabricate an applicant's stated competencies. Reported
    and left for a human.

    The type is NOT stored on the join row. It is the competency's parent, and
    duplicating it would let the two disagree.

.PARAMETER RemoveOldColumns
    Drops OPMCompetencies, TechnicalCompetencies and ECQs. Separate on purpose,
    and the only destructive step.

.EXAMPLE
    ./Update-LdpCompetencySelections.ps1 -SiteUrl https://... -ClientId <guid> -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [switch]$RemoveOldColumns,
    [switch]$SkipLimits,
    [switch]$SkipList
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# RQ006 three OPM, RQ007 three technical, RQ008 four ECQ. Keyed on TypeName as
# seeded from the workbook. A type not listed here is left alone and reported —
# better than defaulting a limit nobody chose.
$script:Limits = @{ 'OPM' = 3; 'Technical' = 3; 'ECQ' = 4 }

$script:OldColumns = @('OPMCompetencies', 'TechnicalCompetencies', 'ECQs')
$script:JoinList   = 'APPLICATION_COMPETENCIES'

$script:Tally = [ordered]@{
    LimitColumnCreated = 0; LimitsSeeded = 0; LimitsUnmapped = 0
    ListCreated = 0; ListExisting = 0; TitleRelaxed = 0; LookupsCreated = 0; IndexesSet = 0
    RowsWithLegacyText = 0; ColumnsRemoved = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

Write-Host ''
Write-Host 'Competency selections — join list, data-driven limits' -ForegroundColor Cyan
Write-Host "  Site        : $SiteUrl"
Write-Host "  Old columns : $(if ($RemoveOldColumns) { ($script:OldColumns -join ', ') + ' WILL BE REMOVED' } else { 'kept' })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    # --- 1. per-type limits -------------------------------------------------
    if (-not $SkipLimits) {
        Write-Host 'PHASE 1/4  COMPETENCY_TYPES.SelectionCount' -ForegroundColor Cyan
        $typeFields = @{}
        foreach ($f in (Get-PnPField -List COMPETENCY_TYPES)) { $typeFields[$f.InternalName] = $f }

        if ($typeFields.ContainsKey('SelectionCount')) {
            Write-Kept 'SelectionCount (exists)'
        } elseif ($PSCmdlet.ShouldProcess('COMPETENCY_TYPES.SelectionCount', 'Add number column')) {
            Add-PnPField -List COMPETENCY_TYPES -DisplayName 'SelectionCount' -InternalName 'SelectionCount' `
                         -Type Number -AddToDefaultView | Out-Null
            Write-Made 'SelectionCount'
            $script:Tally.LimitColumnCreated++
        }

        # -WhatIf leaves the column uncreated, so nothing below may read it.
        $canSeed = $typeFields.ContainsKey('SelectionCount') -or -not $WhatIfPreference
        foreach ($t in (Get-PnPListItem -List COMPETENCY_TYPES -PageSize 500)) {
            $name = [string]$t['TypeName']
            if (-not $script:Limits.ContainsKey($name)) {
                Write-Held "type '$name' has no limit in RQ006-008 — SelectionCount left unset"
                $script:Tally.LimitsUnmapped++
                continue
            }
            $want = $script:Limits[$name]
            if ($canSeed -and $typeFields.ContainsKey('SelectionCount')) {
                $have = $t['SelectionCount']
                if ($have -and [int]$have -eq $want) { Write-Kept "$name = $want"; continue }
            }
            if ($PSCmdlet.ShouldProcess("COMPETENCY_TYPES/$name", "Set SelectionCount = $want")) {
                Set-PnPListItem -List COMPETENCY_TYPES -Identity $t.Id -Values @{ SelectionCount = $want } | Out-Null
                Write-Made "$name -> $want"
                $script:Tally.LimitsSeeded++
            }
        }
        Write-Host ''
    }

    # --- 2. the join list ---------------------------------------------------
    if (-not $SkipList) {
        Write-Host "PHASE 2/4  $script:JoinList" -ForegroundColor Cyan
        $exists = $null -ne (Get-PnPList -Identity $script:JoinList -ErrorAction SilentlyContinue)
        if ($exists) {
            Write-Kept "$script:JoinList (exists)"
            $script:Tally.ListExisting++
        } elseif ($PSCmdlet.ShouldProcess($script:JoinList, 'Create list')) {
            New-PnPList -Title $script:JoinList -Template GenericList -OnQuickLaunch:$false | Out-Null
            Set-PnPList -Identity $script:JoinList `
                        -Description 'An application''s selected competencies (join of APPLICATIONS x COMPETENCIES). The TYPE comes from the competency''s parent and is deliberately not stored here.' | Out-Null
            Write-Made $script:JoinList
            $script:Tally.ListCreated++
            $exists = $true
        }

        if ($exists) {
            # GenericList ships a REQUIRED Title column. Nothing in this app
            # populates it, so every Patch from Power Fx fails validation —
            # and because the screen deletes before it rewrites, a failed write
            # loses the lot. New-LdpSharePointLists.ps1 does this for every list
            # it creates; this script did not, which is how it was missed.
            #
            # Outside the creation branch on purpose, so re-running repairs a
            # list that was created before this step existed.
            $titleField = Get-PnPField -List $script:JoinList -Identity 'Title' -ErrorAction SilentlyContinue
            if ($titleField -and $titleField.Required) {
                if ($PSCmdlet.ShouldProcess("$script:JoinList.Title", 'Set NOT Required')) {
                    Set-PnPField -List $script:JoinList -Identity 'Title' `
                                 -Values @{ Required = $false } -UpdateExistingLists:$false | Out-Null
                    Write-Made 'Title is no longer required'
                    $script:Tally.TitleRelaxed++
                }
            } else {
                Write-Kept 'Title already optional'
            }

            $have = @{}
            foreach ($f in (Get-PnPField -List $script:JoinList)) { $have[$f.InternalName] = $f }

            foreach ($lk in @(
                @{ Name = 'ApplicationID'; Target = 'APPLICATIONS'; ShowField = 'ApplicantEmail' },
                @{ Name = 'CompetencyID';  Target = 'COMPETENCIES'; ShowField = 'CompetencyName' })) {

                if ($have.ContainsKey($lk.Name)) { Write-Kept "$($lk.Name) (exists)"; continue }
                if ($PSCmdlet.ShouldProcess("$script:JoinList.$($lk.Name)", "Add lookup to $($lk.Target)")) {
                    Add-PnPField -List $script:JoinList -DisplayName $lk.Name -InternalName $lk.Name `
                                 -Type Lookup -AddToDefaultView | Out-Null
                    Set-PnPField -List $script:JoinList -Identity $lk.Name `
                                 -Values @{ LookupList  = (Get-PnPList -Identity $lk.Target).Id.ToString()
                                            LookupField = $lk.ShowField
                                            Required    = $true } | Out-Null
                    Write-Made "$($lk.Name) -> $($lk.Target).$($lk.ShowField)"
                    $script:Tally.LookupsCreated++
                }
                if ($PSCmdlet.ShouldProcess("$script:JoinList.$($lk.Name)", 'Index')) {
                    Set-PnPField -List $script:JoinList -Identity $lk.Name -Values @{ Indexed = $true } | Out-Null
                    $script:Tally.IndexesSet++
                }
            }
        }
        Write-Host ''
    }

    # --- 3. anything in the old columns? ------------------------------------
    Write-Host 'PHASE 3/4  Legacy text' -ForegroundColor Cyan
    $appFields = @{}
    foreach ($f in (Get-PnPField -List APPLICATIONS)) { $appFields[$f.InternalName] = $f }
    $present = @($script:OldColumns | Where-Object { $appFields.ContainsKey($_) })

    if ($present.Count -eq 0) {
        Write-Kept 'the three text columns are already gone'
    } else {
        foreach ($item in (Get-PnPListItem -List APPLICATIONS -PageSize 500)) {
            $filled = @($present | Where-Object { [string]$item[$_] })
            if ($filled.Count -eq 0) { continue }
            Write-Held "$([string]$item['ApplicantName']) has text in: $($filled -join ', ') — NOT migrated, re-enter it in the app"
            $script:Tally.RowsWithLegacyText++
        }
        if ($script:Tally.RowsWithLegacyText -eq 0) {
            Write-Kept 'no application holds competency text — nothing would be lost'
        }
    }
    Write-Host ''

    # --- 4. drop the old columns -------------------------------------------
    Write-Host 'PHASE 4/4  Old columns' -ForegroundColor Cyan
    if (-not $RemoveOldColumns) {
        Write-Held 'kept — pass -RemoveOldColumns once the screens no longer read them'
    } elseif ($script:Tally.RowsWithLegacyText -gt 0) {
        throw "Refusing to drop the columns: $($script:Tally.RowsWithLegacyText) application(s) still hold text. Re-enter those selections first, or re-run with -SkipList to see them again."
    } else {
        foreach ($c in $present) {
            if ($PSCmdlet.ShouldProcess("APPLICATIONS.$c", 'Remove column')) {
                Remove-PnPField -List APPLICATIONS -Identity $c -Force | Out-Null
                Write-Made "removed $c"
                $script:Tally.ColumnsRemoved++
            }
        }
    }

    Write-Host ''
    Write-Host 'Summary' -ForegroundColor Cyan
    foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-22} {1}" -f $k, $script:Tally[$k]) }
    Write-Host ''
    Write-Host 'Then: add APPLICATION_COMPETENCIES as a data source in Power Apps Studio,' -ForegroundColor Yellow
    Write-Host 'refresh COMPETENCY_TYPES, and re-run Add-LdpTestApplications.ps1 to seed' -ForegroundColor Yellow
    Write-Host 'competency selections for the test applications.' -ForegroundColor Yellow
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
