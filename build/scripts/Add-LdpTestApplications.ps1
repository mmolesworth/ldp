<#
.SYNOPSIS
    Inserts five test applications, their ranked program choices, and some
    committee scores — enough to exercise every state on the DTD Applications
    Screen.

.DESCRIPTION
    Eight applicants spread across the lifecycle so every status, stage and
    outcome on the DTD Applications screen has something to show:

      1. Draft                                    no choices
      2. Submitted   Pending First-Line           HPP + MDP + NEXT
      3. Submitted   Pending Second-Line          MDP + NEXT   (no options at all)
      4. Submitted   Committee Review             HPP x2 + MDP, partly scored
      5. Validated   Pending DTD Validation       HPP + NEXT
      6. Submitted   Pending Notification         MDP, Not Selected
      7. Submitted   Complete + Placed            NEXT + HPP + MDP, fully scored
      8. Withdrawn   no stage                     HPP

    PROGRAMS ARE THE CHOICE, options are a detail only HPP has. Picks are
    declared per person rather than taken as "the first N options", which is
    what made every applicant choose HPP and nothing else once the fabricated
    "N/A" options for MDP and NEXT were deleted.

    Applicant 4 ranks HPP TWICE with different options — legal since
    2026-07-31, and the case that proves uniqueness is on the (program, option)
    pair rather than on the program.

    COMPETENCIES are seeded too, up to COMPETENCY_TYPES.SelectionCount per type
    (OPM 3, Technical 3, ECQ 4). Each applicant gets a different slice of the
    catalogue so no two look alike, and two are given FEWER than the maximum —
    the count is a ceiling, not a quota, and a screen that assumes a full set
    per type would render wrong for them.

    Written against the THREE-column model (ApplicationStatus / ReviewStage /
    PlacementOutcome). The single Status column it originally used no longer
    exists — see build/lists/_CHOICES.md, 2026-07-31.

    TEST DATA ONLY. Every applicant email is @ldptest.invalid — a reserved TLD
    that can never resolve — so these rows are impossible to confuse with real
    applicants and trivial to find later. -Remove deletes exactly those rows.

    Idempotent: an applicant that already exists in the cycle is skipped, so a
    re-run tops up whatever is missing rather than duplicating.

.PARAMETER CycleName
    Which cycle to attach to. Defaults to the Open cycle, and fails if there
    isn't exactly one.

.PARAMETER Remove
    Deletes the test rows instead of creating them. Children first.

.EXAMPLE
    ./Add-LdpTestApplications.ps1 -SiteUrl https://... -ClientId <guid>

.EXAMPLE
    ./Add-LdpTestApplications.ps1 -SiteUrl https://... -ClientId <guid> -Remove
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [string]$CycleName,

    [switch]$Remove
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Reserved TLD (RFC 2606) — guaranteed never to resolve, so these can never
# be mistaken for real applicants and are a safe key for -Remove.
$script:TestDomain = '@ldptest.invalid'

# Picks are ordered — index 0 is rank 1. Program is matched on the code in
# parentheses ("High Potential Program (HPP)") or on the whole name. Option is
# a 1-based index into that program's ACTIVE options, or $null for a program
# that has none; an index against a program with no options is simply ignored,
# so these stay valid if MDP or NEXT ever gains one.
$script:People = @(
    @{ Name = 'Dana Whitfield'; Email = "dana.whitfield$script:TestDomain"
       AppStatus = 'Draft';     Stage = $null;                   Outcome = 'Decision Pending'
       Location = 'Alexandria, VA'; Grade = 'CU-12'; Series = '0570'; Title = 'Credit Union Examiner'
       Picks = @(); Comps = 'none'; Scores = 0 }

    @{ Name = 'Marcus Bell';    Email = "marcus.bell$script:TestDomain"
       AppStatus = 'Submitted'; Stage = 'Pending First-Line';     Outcome = 'Decision Pending'
       Location = 'Austin, TX';     Grade = 'CU-12'; Series = '0570'; Title = 'Credit Union Examiner'
       Picks = @(
         @{ Program = 'HPP';  Option = 1 }
         @{ Program = 'MDP';  Option = $null }
         @{ Program = 'NEXT'; Option = $null })
       Comps = 'full'
       Scores = 0 }

    # No options anywhere on this one — the case that used to be impossible to
    # record without inventing an "N/A" row.
    @{ Name = 'Priya Raman';    Email = "priya.raman$script:TestDomain"
       AppStatus = 'Submitted'; Stage = 'Pending Second-Line';    Outcome = 'Decision Pending'
       Location = 'Chicago, IL';    Grade = 'CU-13'; Series = '0570'; Title = 'Senior Examiner'
       Picks = @(
         @{ Program = 'MDP';  Option = $null }
         @{ Program = 'NEXT'; Option = $null })
       Comps = 'full'
       Scores = 0 }

    # HPP twice, different options. Two choice rows, ONE program to score.
    @{ Name = 'Tomas Okafor';   Email = "tomas.okafor$script:TestDomain"
       AppStatus = 'Submitted'; Stage = 'Committee Review';       Outcome = 'Decision Pending'
       Location = 'Atlanta, GA';    Grade = 'CU-13'; Series = '0301'; Title = 'Program Analyst'
       Picks = @(
         @{ Program = 'HPP';  Option = 1 }
         @{ Program = 'HPP';  Option = 2 }
         @{ Program = 'MDP';  Option = $null })
       Comps = 'full'
       Scores = 1 }

    @{ Name = 'Rosa Delgado';   Email = "rosa.delgado$script:TestDomain"
       AppStatus = 'Validated'; Stage = 'Pending DTD Validation'; Outcome = 'Decision Pending'
       Location = 'Phoenix, AZ';    Grade = 'CU-12'; Series = '0570'; Title = 'Credit Union Examiner'
       Picks = @(
         @{ Program = 'HPP';  Option = 3 }
         @{ Program = 'NEXT'; Option = $null })
       Comps = 'partial'
       Scores = 0 }

    @{ Name = 'Aaron Feld';     Email = "aaron.feld$script:TestDomain"
       AppStatus = 'Submitted'; Stage = 'Pending Notification';   Outcome = 'Not Selected'
       Location = 'Boston, MA';     Grade = 'CU-11'; Series = '0301'; Title = 'Management Analyst'
       Picks = @(
         @{ Program = 'MDP';  Option = $null })
       Comps = 'full'
       Scores = 1 }

    @{ Name = 'Helen Nakamura'; Email = "helen.nakamura$script:TestDomain"
       AppStatus = 'Submitted'; Stage = 'Complete';               Outcome = 'Placed'
       Location = 'Denver, CO';     Grade = 'CU-14'; Series = '0301'; Title = 'Supervisory Analyst'
       Picks = @(
         @{ Program = 'NEXT'; Option = $null }
         @{ Program = 'HPP';  Option = 2 }
         @{ Program = 'MDP';  Option = $null })
       Comps = 'full'
       Scores = 3 }

    @{ Name = 'Ivan Petrov';    Email = "ivan.petrov$script:TestDomain"
       AppStatus = 'Withdrawn'; Stage = $null;                    Outcome = 'Decision Pending'
       Location = 'Seattle, WA';    Grade = 'CU-13'; Series = '0570'; Title = 'Senior Examiner'
       Picks = @(
         @{ Program = 'HPP';  Option = 1 })
       Comps = 'partial'
       Scores = 0 }
)

$script:Tally = [ordered]@{
    ApplicationsCreated = 0; ApplicationsExisting = 0
    ChoicesCreated = 0; CompetenciesCreated = 0
    ScoresCreated = 0; ScoresSkipped = 0; Removed = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m (exists)" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'LDP test applications' -ForegroundColor Cyan
Write-Host "  Site : $SiteUrl"
Write-Host "  Mode : $(if ($Remove) { 'REMOVE' } else { 'CREATE' })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    # --- the cycle ---------------------------------------------------------
    # NOTE: PnP returns a CHOICE column as a plain string. It is LOOKUP columns
    # that come back as objects (.LookupId / .LookupValue). That is the mirror
    # image of Power Fx, where a choice needs .Value and a lookup needs .Id —
    # so a formula translated straight from a screen fails here.
    $cycles = Get-PnPListItem -List CYCLES -PageSize 500
    if ($CycleName) {
        $cycle = $cycles | Where-Object { [string]$_['CycleName'] -eq $CycleName } | Select-Object -First 1
        if (-not $cycle) { throw "No cycle named '$CycleName'." }
    } else {
        $open = @($cycles | Where-Object { [string]$_['State'] -eq 'Open' })
        if ($open.Count -eq 0) { throw "No Open cycle. Pass -CycleName to choose one explicitly." }
        if ($open.Count -gt 1) { throw "More than one Open cycle — that should not happen (FR-040). Pass -CycleName." }
        $cycle = $open[0]
    }
    Write-Host "Cycle: $($cycle['CycleName']) (id $($cycle.Id))" -ForegroundColor Cyan
    Write-Host ''

    # --- remove mode -------------------------------------------------------
    if ($Remove) {
        $apps = @(Get-PnPListItem -List APPLICATIONS -PageSize 500 |
                  Where-Object { [string]$_['ApplicantEmail'] -like "*$script:TestDomain" })
        if ($apps.Count -eq 0) { Write-Host '  nothing to remove' -ForegroundColor DarkGray }

        foreach ($a in $apps) {
            # Children first — a choice or score whose parent is gone is an
            # orphan nothing can reach or clean up later.
            foreach ($listName in 'APPLICATION_PROGRAM_CHOICES', 'APPLICATION_COMPETENCIES', 'COMMITTEE_SCORES') {
                $kids = @(Get-PnPListItem -List $listName -PageSize 500 |
                          Where-Object { $_['ApplicationID'].LookupId -eq $a.Id })
                foreach ($k in $kids) {
                    if ($PSCmdlet.ShouldProcess("$listName/$($k.Id)", 'Remove')) {
                        Remove-PnPListItem -List $listName -Identity $k.Id -Force | Out-Null
                        $script:Tally.Removed++
                    }
                }
            }
            if ($PSCmdlet.ShouldProcess("APPLICATIONS/$($a['ApplicantName'])", 'Remove')) {
                Remove-PnPListItem -List APPLICATIONS -Identity $a.Id -Force | Out-Null
                Write-Made "removed $($a['ApplicantName'])"
                $script:Tally.Removed++
            }
        }
        Write-Host ''
        foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-20} {1}" -f $k, $script:Tally[$k]) }
        Write-Host ''
        return
    }

    # --- reference data ----------------------------------------------------
    $programs = @(Get-PnPListItem -List PROGRAMS -PageSize 500 |
                  Where-Object { [string]$_['State'] -ne 'Retired' })
    if ($programs.Count -eq 0) { throw 'PROGRAMS is empty — create NEXT, MDP and HPP first.' }

    $allOptions = @(Get-PnPListItem -List PROGRAM_OPTIONS -PageSize 500)
    $options    = @($allOptions | Where-Object { [string]$_['State'] -eq 'Active' })

    # Active options grouped by parent program. A program with none is absent
    # from the table, which is now a legal and common state rather than an
    # error — MDP and NEXT are both like this.
    # NOT $pid — that is an automatic read-only variable (the process id) and
    # assigning to it is a hard error, not a shadowing warning.
    $optionsByProgram = @{}
    foreach ($o in $options) {
        $parentId = [int]$o['ProgramID'].LookupId
        if (-not $optionsByProgram.ContainsKey($parentId)) { $optionsByProgram[$parentId] = @() }
        $optionsByProgram[$parentId] += $o
    }

    # Match the short code in parentheses first — PROGRAMS stores the full
    # title, "High Potential Program (HPP)" — then fall back to the whole name.
    function Resolve-Program {
        param([string]$Code)
        $hit = $programs | Where-Object { [string]$_['ProgramName'] -like "*($Code)" } | Select-Object -First 1
        if (-not $hit) {
            $hit = $programs | Where-Object { [string]$_['ProgramName'] -eq $Code } | Select-Object -First 1
        }
        return $hit
    }

    Write-Host 'Programs:' -ForegroundColor Cyan
    foreach ($pg in $programs) {
        $c = if ($optionsByProgram.ContainsKey([int]$pg.Id)) { $optionsByProgram[[int]$pg.Id].Count } else { 0 }
        Write-Host ("  {0,-40} {1} active option(s)" -f [string]$pg['ProgramName'], $c)
    }
    Write-Host ''

    # No options at all is no longer fatal — an MDP or NEXT application needs
    # none, and every hard stop here used to be about ProgramOptionID being a
    # required lookup. Still worth saying, because "none active" has two very
    # different causes: PROGRAM_OPTIONS.State was added 2026-07-26 and every
    # row created before that has a BLANK State, which is not Active.
    if ($options.Count -lt 1) {
        if ($allOptions.Count -eq 0) {
            Write-Held 'PROGRAM_OPTIONS is empty — HPP picks will have no option.'
        }
        $blank = @($allOptions | Where-Object { -not [string]$_['State'] })
        if ($blank.Count -gt 0) {
            Write-Host ''
            Write-Host "  $($blank.Count) of $($allOptions.Count) options have a BLANK State." -ForegroundColor Yellow
            Write-Host '  State was added 2026-07-26; rows created before it were never set.' -ForegroundColor Yellow
            Write-Host '  Backfill them with:' -ForegroundColor Yellow
            Write-Host ''
            Write-Host "    Get-PnPListItem -List PROGRAM_OPTIONS -PageSize 500 |" -ForegroundColor DarkGray
            Write-Host "      Where-Object { -not [string]`$_['State'] } |" -ForegroundColor DarkGray
            Write-Host "      ForEach-Object { Set-PnPListItem -List PROGRAM_OPTIONS -Identity `$_.Id -Values @{ State = 'Active' } }" -ForegroundColor DarkGray
            Write-Host ''
        }
        # Not fatal any more. HPP picks lose their option; MDP and NEXT never
        # had one. The applications are still worth creating.
        Write-Held "No Active PROGRAM_OPTIONS ($($allOptions.Count) row(s) exist, none Active) — HPP picks will have no option."
    }

    # Competency catalogue grouped by type, with each type's ceiling read from
    # the list rather than hardcoded 3/3/4 — the type set is data-driven and a
    # fourth type must work without a code change.
    $compTypes = @(Get-PnPListItem -List COMPETENCY_TYPES -PageSize 500 |
                   Where-Object { [string]$_['State'] -ne 'Retired' })
    $compsByType = @{}
    foreach ($c in (Get-PnPListItem -List COMPETENCIES -PageSize 500 |
                    Where-Object { [string]$_['State'] -eq 'Active' })) {
        $ctid = [int]$c['CompetencyTypeID'].LookupId
        if (-not $compsByType.ContainsKey($ctid)) { $compsByType[$ctid] = @() }
        $compsByType[$ctid] += $c
    }

    Write-Host 'Competency types:' -ForegroundColor Cyan
    if ($compTypes.Count -eq 0) { Write-Held 'COMPETENCY_TYPES is empty — no competencies will be seeded' }
    foreach ($ct in $compTypes) {
        $avail = if ($compsByType.ContainsKey([int]$ct.Id)) { $compsByType[[int]$ct.Id].Count } else { 0 }
        $lim   = if ($ct['SelectionCount']) { [int]$ct['SelectionCount'] } else { 0 }
        Write-Host ("  {0,-14} {1,3} available, max {2} per application" -f [string]$ct['TypeName'], $avail, $lim)
        if ($lim -le 0) {
            Write-Held "  '$([string]$ct['TypeName'])' has no SelectionCount — run Update-LdpCompetencySelections.ps1 first"
        }
    }
    Write-Host ''

    $sheets = @(Get-PnPListItem -List RATING_SHEETS -PageSize 500 |
                Where-Object { [string]$_['State'] -eq 'Published' })

    $existing = @(Get-PnPListItem -List APPLICATIONS -PageSize 500 |
                  Where-Object { $_['CycleID'].LookupId -eq $cycle.Id })

    # Drives the per-applicant offset into each competency pool.
    $personIndex = 0

    foreach ($p in $script:People) {
        if ($existing | Where-Object { [string]$_['ApplicantEmail'] -eq $p.Email }) {
            Write-Kept $p.Name
            $script:Tally.ApplicationsExisting++
            continue
        }
        if (-not $PSCmdlet.ShouldProcess("APPLICATIONS/$($p.Name)", 'Add')) { continue }

        $values = @{
            CycleID                 = $cycle.Id
            ApplicantEmail          = $p.Email
            ApplicantName           = $p.Name
            Location                = $p.Location
            Grade                   = $p.Grade
            JobSeries               = $p.Series
            JobTitle                = $p.Title
            ApplicationStatus       = $p.AppStatus
            PlacementOutcome        = $p.Outcome
            ListedOnIDP             = 'Yes'
            AttendedInfoSession     = 'Yes'
            LatestPerformanceRating = 4
            NCUAStartDate           = (Get-Date).AddYears(-6)
            ServiceComputationDate  = (Get-Date).AddYears(-8)
        }
        if ($p.Stage) { $values['ReviewStage'] = $p.Stage }
        # Only a submitted application has supervisors snapshotted (R1/R5).
        if ($p.AppStatus -ne 'Draft') {
            $values['FirstLineSupervisorEmail']  = "firstline$script:TestDomain"
            $values['SecondLineSupervisorEmail'] = "secondline$script:TestDomain"
        }

        $app = Add-PnPListItem -List APPLICATIONS -Values $values
        Write-Made "$($p.Name) — $($p.AppStatus)$(if ($p.Stage) { " / $($p.Stage)" })$(if ($p.Outcome -ne 'Decision Pending') { " / $($p.Outcome)" })"
        $script:Tally.ApplicationsCreated++

        # --- ranked choices ------------------------------------------------
        # ProgramID is the choice. ProgramOptionID is sent only when the
        # program actually has one — omitting the key entirely rather than
        # sending $null, so the column is left unset instead of being written
        # as an empty lookup.
        $rank = 1
        $scoreProgramIds = @()
        foreach ($pick in $p.Picks) {
            $program = Resolve-Program -Code $pick.Program
            if (-not $program) {
                Write-Held "no program matches '$($pick.Program)' — choice skipped for $($p.Name)"
                continue
            }
            $programId = [int]$program.Id

            $values = @{
                ApplicationID = $app.Id
                ProgramID     = $programId
                Rank          = $rank
            }
            $optLabel = ''
            if ($pick.Option -and $optionsByProgram.ContainsKey($programId)) {
                $avail = $optionsByProgram[$programId]
                # Wrap rather than fail: the profiles above should not have to
                # track how many options HPP happens to have this week.
                $idx = ([int]$pick.Option - 1) % $avail.Count
                $opt = $avail[$idx]
                $values['ProgramOptionID'] = $opt.Id
                $optLabel = " / $([string]$opt['OptionName'])"
            }

            Add-PnPListItem -List APPLICATION_PROGRAM_CHOICES -Values $values | Out-Null
            Write-Made "  $($p.Name) rank $rank : $($pick.Program)$optLabel"
            $script:Tally.ChoicesCreated++
            if ($scoreProgramIds -notcontains $programId) { $scoreProgramIds += $programId }
            $rank++
        }

        # --- competencies ---------------------------------------------------
        # A different slice per applicant so no two are identical: offset into
        # each type's pool by the applicant's index, wrapping. Deterministic —
        # -Remove then re-run reproduces the same data.
        if ($p.Comps -ne 'none') {
            foreach ($ct in $compTypes) {
                $ctid = [int]$ct.Id
                if (-not $compsByType.ContainsKey($ctid)) { continue }
                $pool  = $compsByType[$ctid]
                $lim   = if ($ct['SelectionCount']) { [int]$ct['SelectionCount'] } else { 0 }
                if ($lim -le 0) { continue }
                # 'partial' takes one fewer — the ceiling is not a quota.
                $take = if ($p.Comps -eq 'partial') { [math]::Max(1, $lim - 1) } else { $lim }
                if ($take -gt $pool.Count) { $take = $pool.Count }

                for ($k = 0; $k -lt $take; $k++) {
                    $comp = $pool[(($personIndex * 3) + $k) % $pool.Count]
                    if ($PSCmdlet.ShouldProcess("APPLICATION_COMPETENCIES/$($p.Name)", "Add $([string]$comp['CompetencyName'])")) {
                        Add-PnPListItem -List APPLICATION_COMPETENCIES -Values @{
                            ApplicationID = $app.Id
                            CompetencyID  = $comp.Id
                        } | Out-Null
                        $script:Tally.CompetenciesCreated++
                    }
                }
                Write-Made "  $($p.Name) : $take x $([string]$ct['TypeName'])"
            }
        }
        $personIndex++

        # --- committee scores ----------------------------------------------
        # COMMITTEE_SCORES.RatingSheetID is REQUIRED, so a score cannot exist
        # without a Published rubric for that program. Skipped rather than
        # faked — a score against no rubric is not a state the app can reach.
        #
        # Scored per DISTINCT program, not per choice row. Tomas ranks HPP
        # twice, which is two choices and one thing to score.
        $scoreTargets = @($scoreProgramIds | Select-Object -First $p.Scores)
        foreach ($programId in $scoreTargets) {
            $sheet = $sheets | Where-Object { [int]$_['ProgramID'].LookupId -eq $programId } | Select-Object -First 1
            if (-not $sheet) {
                Write-Held "no published rubric for program id $programId — score skipped for $($p.Name)"
                $script:Tally.ScoresSkipped++
                continue
            }
            $final = Get-Random -Minimum 18 -Maximum 41
            Add-PnPListItem -List COMMITTEE_SCORES -Values @{
                ApplicationID     = $app.Id
                ProgramID         = $programId
                RatingSheetID     = $sheet.Id
                FinalScore        = $final
                PercentOfPossible = [math]::Round($final / 45 * 100, 1)
                ScoredBy          = 'Test Committee'
                ScoredDate        = (Get-Date)
            } | Out-Null
            $script:Tally.ScoresCreated++
        }
    }

    Write-Host ''
    Write-Host 'Summary' -ForegroundColor Cyan
    foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-20} {1}" -f $k, $script:Tally[$k]) }

    if ($script:Tally.ScoresSkipped -gt 0) {
        Write-Host ''
        Write-Host 'Some scores were skipped: publish a rubric for those programs on the' -ForegroundColor Yellow
        Write-Host 'Scoring Rubrics screen, then re-run. Applications already created are' -ForegroundColor Yellow
        Write-Host 'skipped on a re-run, so only the missing scores get added.' -ForegroundColor Yellow
    }
    Write-Host ''
    Write-Host "Remove it all again with:  -Remove" -ForegroundColor DarkGray
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
