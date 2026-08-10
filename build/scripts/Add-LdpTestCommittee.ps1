<#
.SYNOPSIS
    Creates an Active COMMITTEES row so the Committee Queue / Committee Score
    screens have data to show. Optionally advances test applicants to
    ReviewStage = Committee Review.

.DESCRIPTION
    Idempotent. If a committee already exists for (Program, Cycle), it is
    left alone. If -AdvanceApplicants is passed, every @ldptest.invalid
    applicant in the specified cycle who has a choice for the committee's
    program AND whose current ReviewStage is Pending DTD Validation is
    advanced to Committee Review (so the Queue Screen's "To score" gallery
    is populated).

    A committee needs three things to exist first:
      · the target PROGRAM
      · a CYCLE (any state)
      · one Published RATING_SHEETS row for that program

    The script fails loudly if the rating sheet is missing — that's a Scoring
    Rubrics Screen job, not this one's.

.PARAMETER SiteUrl
    Target site.

.PARAMETER ClientId
    Entra ID app registration client ID.

.PARAMETER ProgramCode
    Which program the committee scores. Defaults to the first program with a
    Published rating sheet. Matches on the code in parentheses in
    PROGRAMS.ProgramName ("High Potential Program (HPP)" -> "HPP") or on
    the whole name.

.PARAMETER CycleName
    Which cycle to attach to. Defaults to the Open cycle; fails if there
    isn't exactly one Open.

.PARAMETER AdvanceApplicants
    Also advance test applicants (@ldptest.invalid) to Committee Review if
    they have a choice for the committee's program.

.PARAMETER Remove
    Deletes the committee row (and, if -AdvanceApplicants, reverts those
    applicants back to Pending DTD Validation).

.EXAMPLE
    ./Add-LdpTestCommittee.ps1 -SiteUrl https://... -ClientId <guid>

.EXAMPLE
    ./Add-LdpTestCommittee.ps1 -SiteUrl https://... -ClientId <guid> -ProgramCode HPP -AdvanceApplicants
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [string]$ProgramCode,

    [string]$CycleName,

    [switch]$AdvanceApplicants,

    [switch]$Remove
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:TestDomain = '@ldptest.invalid'

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m (exists)" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

Write-Host ''
Write-Host 'LDP test committee' -ForegroundColor Cyan
Write-Host "  Site : $SiteUrl"
Write-Host "  Mode : $(if ($Remove) { 'REMOVE' } else { 'CREATE' })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    # --- resolve the cycle -------------------------------------------------
    $cycles = Get-PnPListItem -List CYCLES -PageSize 500
    if ($CycleName) {
        $cycle = $cycles | Where-Object { [string]$_['CycleName'] -eq $CycleName } | Select-Object -First 1
        if (-not $cycle) { throw "No cycle named '$CycleName'." }
    } else {
        $open = @($cycles | Where-Object { [string]$_['State'] -eq 'Open' })
        if ($open.Count -eq 0) { throw "No Open cycle. Pass -CycleName to choose one explicitly." }
        if ($open.Count -gt 1) { throw "More than one Open cycle. Pass -CycleName." }
        $cycle = $open[0]
    }
    Write-Host "Cycle: $($cycle['CycleName']) (id $($cycle.Id))" -ForegroundColor Cyan

    # --- resolve the program (via a Published rating sheet) ----------------
    $sheets = @(Get-PnPListItem -List RATING_SHEETS -PageSize 500 |
                Where-Object { [string]$_['State'] -eq 'Published' })
    if ($sheets.Count -eq 0) {
        throw "No Published RATING_SHEETS row exists. Publish a rubric via the Scoring Rubrics Screen first."
    }

    $programs = Get-PnPListItem -List PROGRAMS -PageSize 500
    if ($ProgramCode) {
        $program = $programs | Where-Object {
            [string]$_['ProgramName'] -match "\($([Regex]::Escape($ProgramCode))\)" -or
            [string]$_['ProgramName'] -eq $ProgramCode
        } | Select-Object -First 1
        if (-not $program) { throw "No program matching '$ProgramCode'." }
        $sheet = $sheets | Where-Object { $_['ProgramID'].LookupId -eq $program.Id } | Select-Object -First 1
        if (-not $sheet) { throw "Program '$($program['ProgramName'])' has no Published rating sheet." }
    } else {
        $sheet = $sheets[0]
        $program = $programs | Where-Object { $_.Id -eq $sheet['ProgramID'].LookupId } | Select-Object -First 1
        if (-not $program) { throw "Published rating sheet references a missing program (id $($sheet['ProgramID'].LookupId))." }
    }
    Write-Host "Program: $($program['ProgramName']) (id $($program.Id))" -ForegroundColor Cyan
    Write-Host "Rating sheet: v$($sheet['SheetVersion']) (id $($sheet.Id))" -ForegroundColor Cyan
    Write-Host ''

    # --- find/create/remove the committee row ------------------------------
    $existing = Get-PnPListItem -List COMMITTEES -PageSize 500 |
                Where-Object {
                    $_['ProgramID'].LookupId -eq $program.Id -and
                    $_['CycleID'].LookupId -eq $cycle.Id
                } | Select-Object -First 1

    if ($Remove) {
        if ($existing) {
            if ($PSCmdlet.ShouldProcess("committee id $($existing.Id)", 'delete')) {
                Remove-PnPListItem -List COMMITTEES -Identity $existing.Id -Force
                Write-Made "removed committee id $($existing.Id)"
            }
        } else {
            Write-Held "no committee to remove for ($($program['ProgramName']), $($cycle['CycleName']))"
        }
    } else {
        if ($existing) {
            Write-Kept "committee for ($($program['ProgramName']), $($cycle['CycleName'])) (id $($existing.Id))"
            $committee = $existing
        } else {
            $name = "$($program['ProgramName']) · $($cycle['CycleName'])"
            if ($PSCmdlet.ShouldProcess($name, 'create COMMITTEES row')) {
                $committee = Add-PnPListItem -List COMMITTEES -Values @{
                    CommitteeName = $name
                    ProgramID     = $program.Id
                    CycleID       = $cycle.Id
                    RatingSheetID = $sheet.Id
                    State         = 'Active'
                    FormedDate    = (Get-Date)
                }
                Write-Made "created COMMITTEES: $name (id $($committee.Id))"
            }
        }
    }

    # --- optionally advance test applicants to Committee Review -----------
    if ($AdvanceApplicants) {
        Write-Host ''
        Write-Host 'Advancing test applicants…' -ForegroundColor Cyan

        $apps = @(Get-PnPListItem -List APPLICATIONS -PageSize 500 |
                  Where-Object {
                      [string]$_['ApplicantEmail'] -like "*$script:TestDomain" -and
                      $_['CycleID'].LookupId -eq $cycle.Id
                  })
        $choices = @(Get-PnPListItem -List APPLICATION_PROGRAM_CHOICES -PageSize 500 |
                     Where-Object { $_['ProgramID'].LookupId -eq $program.Id })
        $appsWithChoice = $apps | Where-Object {
            $appId = $_.Id
            @($choices | Where-Object { $_['ApplicationID'].LookupId -eq $appId }).Count -gt 0
        }

        foreach ($a in $appsWithChoice) {
            $currentStage = [string]$a['ReviewStage']
            $email = [string]$a['ApplicantEmail']
            if ($Remove) {
                if ($currentStage -eq 'Committee Review') {
                    if ($PSCmdlet.ShouldProcess("app $($a.Id) ($email)", 'revert to Pending DTD Validation')) {
                        Set-PnPListItem -List APPLICATIONS -Identity $a.Id -Values @{
                            ReviewStage = 'Pending DTD Validation'
                        } | Out-Null
                        Write-Made "reverted $email -> Pending DTD Validation"
                    }
                } else {
                    Write-Held "skipped $email (stage: $currentStage)"
                }
            } else {
                if ($currentStage -eq 'Committee Review') {
                    Write-Kept "$email (already Committee Review)"
                } elseif ($currentStage -eq 'Pending DTD Validation' -or $currentStage -eq 'Pending Second-Line' -or $currentStage -eq 'Pending First-Line') {
                    if ($PSCmdlet.ShouldProcess("app $($a.Id) ($email)", 'advance to Committee Review')) {
                        Set-PnPListItem -List APPLICATIONS -Identity $a.Id -Values @{
                            ReviewStage = 'Committee Review'
                        } | Out-Null
                        Write-Made "advanced $email -> Committee Review"
                    }
                } else {
                    Write-Held "skipped $email (stage: $currentStage)"
                }
            }
        }
    }

    Write-Host ''
    Write-Host 'Done.' -ForegroundColor Green
} finally {
    Disconnect-PnPOnline
}
