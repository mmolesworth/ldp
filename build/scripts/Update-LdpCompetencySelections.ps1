<#
.SYNOPSIS
    Migrates off the three free-text competency columns on APPLICATIONS to the
    APPLICATION_COMPETENCIES join list, and seeds the per-type selection limit
    so it is data rather than code. See build/lists/APPLICATION_COMPETENCIES.md.

.DESCRIPTION
    APPLICATIONS carried OPMCompetencies, TechnicalCompetencies and ECQs as
    "Multiple lines of text" — one column per competency type. That cannot
    survive the types being data-driven: the Competencies admin screen lets DTD
    add a fourth type, and there is no column for it. Same defect that
    APPLICATION_PROGRAM_CHOICES had one table over, and the same fix.

    APPLICATION_COMPETENCIES itself, its two lookups, and the SelectionCount
    column on COMPETENCY_TYPES are provisioned by New-LdpSharePointLists.ps1.
    This script assumes those already exist and handles only the migration:

      1. LIMITS   seed COMPETENCY_TYPES.SelectionCount — OPM 3, Technical 3,
                  ECQ 4, per RQ006/RQ007/RQ008. A MAXIMUM, not a required
                  count; no requirement states a minimum.
      2. CHECK    report any application still holding text in the old columns.
      3. REMOVE   drop the three text columns — ONLY with -RemoveOldColumns.

    WHY PHASE 2 REPORTS RATHER THAN MIGRATES:
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
    [switch]$SkipLimits
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# RQ006 three OPM, RQ007 three technical, RQ008 four ECQ. Keyed on TypeName as
# seeded from the workbook. A type not listed here is left alone and reported —
# better than defaulting a limit nobody chose.
$script:Limits = @{ 'OPM' = 3; 'Technical' = 3; 'ECQ' = 4 }

$script:OldColumns = @('OPMCompetencies', 'TechnicalCompetencies', 'ECQs')

$script:Tally = [ordered]@{
    LimitColumnCreated = 0; LimitsSeeded = 0; LimitsUnmapped = 0
    RowsWithLegacyText = 0; ColumnsRemoved = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

Write-Host ''
Write-Host 'Competency selections — data-driven limits, retire text columns' -ForegroundColor Cyan
Write-Host "  Site        : $SiteUrl"
Write-Host "  Old columns : $(if ($RemoveOldColumns) { ($script:OldColumns -join ', ') + ' WILL BE REMOVED' } else { 'kept' })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    # --- 1. per-type limits -------------------------------------------------
    if (-not $SkipLimits) {
        Write-Host 'PHASE 1/3  COMPETENCY_TYPES.SelectionCount' -ForegroundColor Cyan
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

    # --- 2. anything in the old columns? ------------------------------------
    Write-Host 'PHASE 2/3  Legacy text' -ForegroundColor Cyan
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

    # --- 3. drop the old columns -------------------------------------------
    Write-Host 'PHASE 3/3  Old columns' -ForegroundColor Cyan
    if (-not $RemoveOldColumns) {
        Write-Held 'kept — pass -RemoveOldColumns once the screens no longer read them'
    } elseif ($script:Tally.RowsWithLegacyText -gt 0) {
        throw "Refusing to drop the columns: $($script:Tally.RowsWithLegacyText) application(s) still hold text. Re-enter those selections first."
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
