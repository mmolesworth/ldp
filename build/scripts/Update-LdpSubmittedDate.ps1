<#
.SYNOPSIS
    Adds APPLICATIONS.SubmittedDate — when the applicant submitted, as distinct
    from when the draft row first appeared. See build/lists/APPLICATIONS.md.

.DESCRIPTION
    The Application Status screen dates the first step of its timeline. Nothing
    in APPLICATIONS could supply that date: NCUAStartDate, ServiceComputationDate
    and InfoSessionDate are all about the applicant, not the application, and
    SharePoint's built-in Created is when the DRAFT row was written — typically
    days before submission, and in a re-application, a different cycle earlier.

      1. COLUMN    add SubmittedDate (DateOnly), optional, indexed.
      2. BACKFILL  only with -BackfillFromCreated, and only where the row is
                   past Draft and has no date yet.

    OPTIONAL, NOT REQUIRED. A Draft has not been submitted and must not carry a
    submission date, so the column cannot be mandatory. Making it Required would
    also invalidate every existing row and block saves from Power Apps.

    THE BACKFILL IS AN APPROXIMATION AND IS OFF BY DEFAULT. Created is the draft
    date, so a backfilled value is wrong by however long the applicant took to
    finish — usually days. It exists to make the test data render a plausible
    screen, not to reconstruct history. Do not run it against real submissions.

.PARAMETER BackfillFromCreated
    Sets SubmittedDate = Created on submitted rows that have none. Approximate
    by construction; see above.

.EXAMPLE
    ./Update-LdpSubmittedDate.ps1 -SiteUrl https://... -ClientId <guid> -WhatIf

.EXAMPLE
    ./Update-LdpSubmittedDate.ps1 -SiteUrl https://... -ClientId <guid> -BackfillFromCreated
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [switch]$BackfillFromCreated
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:List = 'APPLICATIONS'

$script:Tally = [ordered]@{
    ColumnCreated = 0; ColumnExisting = 0; IndexSet = 0
    RowsBackfilled = 0; RowsSkipped = 0; RowsAlreadyDated = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

Write-Host ''
Write-Host 'Submission date — when the applicant actually submitted' -ForegroundColor Cyan
Write-Host "  Site     : $SiteUrl"
Write-Host "  Backfill : $(if ($BackfillFromCreated) { 'FROM Created (approximate)' } else { 'no' })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    # --- 1. the column -------------------------------------------------------
    Write-Host 'PHASE 1/2  Column' -ForegroundColor Cyan
    $have = @{}
    foreach ($f in (Get-PnPField -List $script:List)) { $have[$f.InternalName] = $f }

    $exists = $have.ContainsKey('SubmittedDate')
    if ($exists) {
        Write-Kept 'SubmittedDate (exists)'
        $script:Tally.ColumnExisting++
    } elseif ($PSCmdlet.ShouldProcess("$script:List.SubmittedDate", 'Add date column')) {
        Add-PnPField -List $script:List -DisplayName 'SubmittedDate' -InternalName 'SubmittedDate' `
                     -Type DateTime -AddToDefaultView | Out-Null
        # Date only. The time of day carries no meaning here and would show up
        # in every view as noise.
        Set-PnPField -List $script:List -Identity 'SubmittedDate' `
                     -Values @{ DisplayFormat = 0; Required = $false } | Out-Null
        Write-Made 'SubmittedDate (date only, optional)'
        $script:Tally.ColumnCreated++
        $exists = $true
    }

    if ($exists -and $PSCmdlet.ShouldProcess("$script:List.SubmittedDate", 'Index')) {
        Set-PnPField -List $script:List -Identity 'SubmittedDate' -Values @{ Indexed = $true } | Out-Null
        Write-Made 'index SubmittedDate'
        $script:Tally.IndexSet++
    }
    Write-Host ''

    # --- 2. approximate backfill --------------------------------------------
    Write-Host 'PHASE 2/2  Backfill' -ForegroundColor Cyan
    if (-not $BackfillFromCreated) {
        Write-Held 'skipped — pass -BackfillFromCreated to date existing test rows from Created'
    } elseif (-not $exists) {
        Write-Held 'column does not exist yet — expected under -WhatIf'
    } else {
        foreach ($a in (Get-PnPListItem -List $script:List -PageSize 500)) {
            $who    = [string]$a['ApplicantName']
            $status = [string]$a['ApplicationStatus']

            if ($status -eq 'Draft' -or [string]::IsNullOrEmpty($status)) {
                Write-Kept "$who : Draft — no submission date"
                $script:Tally.RowsSkipped++
                continue
            }
            if ($a['SubmittedDate']) {
                $script:Tally.RowsAlreadyDated++
                continue
            }
            $created = $a['Created']
            if (-not $created) {
                Write-Held "$who : no Created value — left for a human"
                $script:Tally.RowsSkipped++
                continue
            }
            if ($PSCmdlet.ShouldProcess("$script:List/$who", "Set SubmittedDate = $created")) {
                Set-PnPListItem -List $script:List -Identity $a.Id `
                                -Values @{ SubmittedDate = $created } | Out-Null
                Write-Made "$who : $([datetime]$created | Get-Date -Format 'yyyy-MM-dd') (approximate)"
                $script:Tally.RowsBackfilled++
            }
        }
    }
    Write-Host ''

    Write-Host 'Summary' -ForegroundColor Cyan
    foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-18} {1}" -f $k, $script:Tally[$k]) }
    Write-Host ''
    Write-Host 'Then: refresh APPLICATIONS in Power Apps Studio, re-paste the Application' -ForegroundColor Yellow
    Write-Host 'Screen (its Submit now writes SubmittedDate), and transcribe the new' -ForegroundColor Yellow
    Write-Host 'Application Status Screen.' -ForegroundColor Yellow
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
