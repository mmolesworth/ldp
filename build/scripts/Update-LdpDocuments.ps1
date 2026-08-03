<#
.SYNOPSIS
    Creates APPLICATION_DOCUMENTS — one row per required supporting document,
    each holding that document as its own attachment. See
    build/lists/APPLICATION_DOCUMENTS.md.

.DESCRIPTION
    APPLICATIONS item attachments are a single unnamed collection: there is no
    way to tell a resume from a statement of interest, so DTD cannot report
    which of the three is missing and an applicant cannot replace one without
    touching the others. A row per type gives each slot an identity.

      1. LIST      create APPLICATION_DOCUMENTS, make the built-in Title column
                   optional, add DocumentType and the ApplicationID lookup, and
                   INDEX both.
      2. BACKFILL  give every existing application its three rows, so the
                   Attachments controls have something to bind to.

    TITLE IS MADE OPTIONAL. GenericList ships a REQUIRED Title column that
    nothing here populates, so every Patch from Power Fx would fail validation.
    That is what cost the competencies on 2026-07-31.

    INDEXED AT CREATION, not later. Adding an index to a list already past 5,000
    items is painful and sometimes requires emptying it. At 200 applications a
    year this list reaches ~4,200 rows over the seven-year retention period.

    Idempotent throughout — an application that already has a row of a given
    type is skipped, so a re-run tops up rather than duplicating.

.PARAMETER SkipBackfill
    Create the list without giving existing applications their rows.

.EXAMPLE
    ./Update-LdpDocuments.ps1 -SiteUrl https://... -ClientId <guid> -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [switch]$SkipBackfill
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:List  = 'APPLICATION_DOCUMENTS'
$script:Types = @('Resume', 'Statement of Interest', 'Performance Appraisal')

$script:Tally = [ordered]@{
    ListCreated = 0; ListExisting = 0; TitleRelaxed = 0
    ColumnsCreated = 0; IndexesSet = 0
    RowsCreated = 0; RowsExisting = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

Write-Host ''
Write-Host 'Supporting documents — one row per document type' -ForegroundColor Cyan
Write-Host "  Site  : $SiteUrl"
Write-Host "  Types : $($script:Types -join ', ')"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    # --- 1. the list ---------------------------------------------------------
    Write-Host 'PHASE 1/2  List and columns' -ForegroundColor Cyan
    $exists = $null -ne (Get-PnPList -Identity $script:List -ErrorAction SilentlyContinue)
    if ($exists) {
        Write-Kept "$script:List (exists)"
        $script:Tally.ListExisting++
    } elseif ($PSCmdlet.ShouldProcess($script:List, 'Create list')) {
        New-PnPList -Title $script:List -Template GenericList -OnQuickLaunch:$false | Out-Null
        Set-PnPList -Identity $script:List `
                    -Description 'One row per required supporting document, each holding that document as its own attachment. A row per type gives each slot an identity that a single attachment collection cannot.' | Out-Null
        Write-Made $script:List
        $script:Tally.ListCreated++
        $exists = $true
    }

    if ($exists) {
        # Outside the creation branch on purpose, so a re-run repairs a list
        # made before this step existed.
        $title = Get-PnPField -List $script:List -Identity 'Title' -ErrorAction SilentlyContinue
        if ($title -and $title.Required) {
            if ($PSCmdlet.ShouldProcess("$script:List.Title", 'Set NOT Required')) {
                Set-PnPField -List $script:List -Identity 'Title' `
                             -Values @{ Required = $false } -UpdateExistingLists:$false | Out-Null
                Write-Made 'Title is no longer required'
                $script:Tally.TitleRelaxed++
            }
        } else {
            Write-Kept 'Title already optional'
        }

        $have = @{}
        foreach ($f in (Get-PnPField -List $script:List)) { $have[$f.InternalName] = $f }

        if ($have.ContainsKey('DocumentType')) {
            Write-Kept 'DocumentType'
        } elseif ($PSCmdlet.ShouldProcess("$script:List.DocumentType", 'Add choice column')) {
            Add-PnPField -List $script:List -DisplayName 'DocumentType' -InternalName 'DocumentType' `
                         -Type Choice -Choices $script:Types -AddToDefaultView | Out-Null
            Set-PnPField -List $script:List -Identity 'DocumentType' -Values @{ Required = $true } | Out-Null
            Write-Made "DocumentType  [$($script:Types -join ' | ')]"
            $script:Tally.ColumnsCreated++
        }

        if ($have.ContainsKey('ApplicationID')) {
            Write-Kept 'ApplicationID'
        } elseif ($PSCmdlet.ShouldProcess("$script:List.ApplicationID", 'Add lookup to APPLICATIONS')) {
            Add-PnPField -List $script:List -DisplayName 'ApplicationID' -InternalName 'ApplicationID' `
                         -Type Lookup -AddToDefaultView | Out-Null
            Set-PnPField -List $script:List -Identity 'ApplicationID' `
                         -Values @{ LookupList  = (Get-PnPList -Identity APPLICATIONS).Id.ToString()
                                    LookupField = 'ApplicantEmail'
                                    Required    = $true } | Out-Null
            Write-Made 'ApplicationID -> APPLICATIONS.ApplicantEmail'
            $script:Tally.ColumnsCreated++
        }

        # INDEX NOW. Past 5,000 items this becomes a project.
        foreach ($c in 'ApplicationID', 'DocumentType') {
            if ($PSCmdlet.ShouldProcess("$script:List.$c", 'Index')) {
                Set-PnPField -List $script:List -Identity $c -Values @{ Indexed = $true } | Out-Null
                Write-Made "index $c"
                $script:Tally.IndexesSet++
            }
        }
    }
    Write-Host ''

    # --- 2. three rows per application --------------------------------------
    if (-not $SkipBackfill) {
        Write-Host 'PHASE 2/2  Rows for existing applications' -ForegroundColor Cyan
        if (-not $exists) {
            Write-Held 'list does not exist yet — expected under -WhatIf'
        } else {
            $apps = @(Get-PnPListItem -List APPLICATIONS -PageSize 500)
            $docs = @(Get-PnPListItem -List $script:List -PageSize 5000)

            # (applicationId, type) pairs already present
            $seen = @{}
            foreach ($d in $docs) {
                $aid = $d['ApplicationID']
                if ($aid) { $seen["$([int]$aid.LookupId)|$([string]$d['DocumentType'])"] = $true }
            }

            foreach ($a in $apps) {
                $who = [string]$a['ApplicantName']
                foreach ($t in $script:Types) {
                    if ($seen.ContainsKey("$($a.Id)|$t")) { $script:Tally.RowsExisting++; continue }
                    if ($PSCmdlet.ShouldProcess("$script:List/$who/$t", 'Add row')) {
                        Add-PnPListItem -List $script:List -Values @{
                            ApplicationID = $a.Id
                            DocumentType  = $t
                        } | Out-Null
                        $script:Tally.RowsCreated++
                    }
                }
                Write-Made "$who : 3 document slots"
            }
        }
        Write-Host ''
    }

    Write-Host 'Summary' -ForegroundColor Cyan
    foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-18} {1}" -f $k, $script:Tally[$k]) }
    Write-Host ''
    Write-Host 'Then: add APPLICATION_DOCUMENTS as a data source in Power Apps Studio,' -ForegroundColor Yellow
    Write-Host 'and build the three Attachments controls by hand — see the step 5' -ForegroundColor Yellow
    Write-Host 'comment block in build/screens/ApplicationScreen.yaml.' -ForegroundColor Yellow
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
