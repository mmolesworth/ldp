<#
.SYNOPSIS
    Loads PROGRAM_OPTIONS from build/scripts/program-options.csv and backfills
    any blank State.

.DESCRIPTION
    Two jobs, each independently skippable:

      1. LOAD      the options in the CSV (HPP, at time of writing).
      2. BACKFILL  State = Active on rows created before that column existed
                   (PROGRAM_OPTIONS.State was added 2026-07-26; earlier rows
                   have it blank, which is not Active and so invisible to every
                   applicant-facing picker).

    PLACEHOLDER ROWS ARE GONE (2026-07-31). This script used to create one
    "N/A" option per program that had none, because
    APPLICATION_PROGRAM_CHOICES.ProgramOptionID was a REQUIRED lookup and an
    applicant therefore could not rank a program with no options. That was a
    schema constraint inventing data to satisfy itself. The choice list now
    records ProgramID directly and the option is optional, so MDP and NEXT need
    nothing fabricated. Run Update-LdpProgramChoices.ps1 -RemovePlaceholders to
    delete any that are still there.

    Idempotent throughout: matches on program + option name and skips what is
    already there, so a re-run tops up rather than duplicating.

.PARAMETER SkipLoad / -SkipBackfill
    Run only the parts you want.

.EXAMPLE
    ./Add-LdpProgramOptions.ps1 -SiteUrl https://... -ClientId <guid> -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [string]$DataPath = $PSScriptRoot,

    [switch]$SkipLoad,
    [switch]$SkipBackfill
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Tally = [ordered]@{
    OptionsCreated = 0; OptionsExisting = 0
    StateBackfilled = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m (exists)" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

$csv = Join-Path $DataPath 'program-options.csv'
if (-not $SkipLoad -and -not (Test-Path $csv)) {
    throw "Seed file not found: $csv. Run build/scripts/Convert-ProgramOptionsWorkbook.py first, and copy the .csv alongside this script."
}

Write-Host ''
Write-Host 'LDP program options' -ForegroundColor Cyan
Write-Host "  Site : $SiteUrl"
Write-Host "  Data : $(if ($SkipLoad) { 'load skipped' } else { $csv })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    # PnP returns a CHOICE as a plain string and a LOOKUP as an object — the
    # mirror image of Power Fx. See build/CONVENTIONS.md.
    $programs = @(Get-PnPListItem -List PROGRAMS -PageSize 500)
    if ($programs.Count -eq 0) { throw 'PROGRAMS is empty — create the programs first.' }

    $options = @(Get-PnPListItem -List PROGRAM_OPTIONS -PageSize 500)

    # --- 2. backfill blank State -------------------------------------------
    # Done FIRST so that everything downstream sees the states we wrote, and
    # because a blank State is invisible to every applicant-facing picker.
    if (-not $SkipBackfill) {
        Write-Host 'Backfill State' -ForegroundColor Cyan
        $blank = @($options | Where-Object { -not [string]$_['State'] })
        if ($blank.Count -eq 0) {
            Write-Host '  nothing blank' -ForegroundColor DarkGray
        }
        foreach ($o in $blank) {
            $name = [string]$o['OptionName']
            if ($PSCmdlet.ShouldProcess("PROGRAM_OPTIONS/$name", 'Set State = Active')) {
                Set-PnPListItem -List PROGRAM_OPTIONS -Identity $o.Id -Values @{ State = 'Active' } | Out-Null
                Write-Made "$name -> Active"
                $script:Tally.StateBackfilled++
            }
        }
        # Re-read: later steps must see the states we just wrote.
        $options = @(Get-PnPListItem -List PROGRAM_OPTIONS -PageSize 500)
        Write-Host ''
    }

    # --- 1. load from CSV ---------------------------------------------------
    if (-not $SkipLoad) {
        Write-Host 'Load options' -ForegroundColor Cyan
        foreach ($row in (Import-Csv $csv)) {
            $programName = $row.Program.Trim()
            $optionName  = $row.OptionName.Trim()
            if (-not $optionName) { continue }

            # The workbook uses the short code (HPP); PROGRAMS stores the full
            # title with the code in parentheses — "High Potential Program
            # (HPP)". Try an exact match first, then the parenthesised code, so
            # the CSV does not have to carry the full title and stay in sync
            # with it.
            $program = $programs | Where-Object { [string]$_['ProgramName'] -eq $programName } | Select-Object -First 1
            if (-not $program) {
                $program = $programs | Where-Object { [string]$_['ProgramName'] -like "*($programName)" } | Select-Object -First 1
                if ($program) { Write-Host "    ('$programName' -> '$([string]$program['ProgramName'])')" -ForegroundColor DarkGray }
            }
            if (-not $program) {
                Write-Held "no program matches '$programName' — '$optionName' skipped"
                continue
            }

            $already = $options | Where-Object {
                $_['ProgramID'].LookupId -eq $program.Id -and [string]$_['OptionName'] -eq $optionName
            }
            if ($already) {
                Write-Kept "$programName / $optionName"
                $script:Tally.OptionsExisting++
                continue
            }

            if ($PSCmdlet.ShouldProcess("PROGRAM_OPTIONS/$programName/$optionName", 'Add')) {
                $values = @{
                    ProgramID  = $program.Id
                    OptionName = $optionName
                    State      = 'Active'
                }
                # Only send columns that actually carry a value — an empty
                # string on a blank cell is not the same as leaving it unset.
                foreach ($f in 'Description','Vendor','GradeLevel','CourseLength','Competency','Requirements','Website') {
                    $v = ($row.$f).Trim()
                    if ($v) { $values[$f] = $v }
                }
                Add-PnPListItem -List PROGRAM_OPTIONS -Values $values | Out-Null
                Write-Made "$programName / $optionName"
                $script:Tally.OptionsCreated++
            }
        }
        $options = @(Get-PnPListItem -List PROGRAM_OPTIONS -PageSize 500)
        Write-Host ''
    }

    Write-Host 'Summary' -ForegroundColor Cyan
    foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-20} {1}" -f $k, $script:Tally[$k]) }
    Write-Host ''
    Write-Host 'Refresh the PROGRAM_OPTIONS data source in Power Apps Studio afterwards,' -ForegroundColor Yellow
    Write-Host 'or the app keeps its cached copy and the new rows will not appear.' -ForegroundColor Yellow
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
