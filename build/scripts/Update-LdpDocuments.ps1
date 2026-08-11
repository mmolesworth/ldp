<#
.SYNOPSIS
    Backfills APPLICATION_DOCUMENTS with one row per required supporting
    document for every existing application. See
    build/lists/APPLICATION_DOCUMENTS.md.

.DESCRIPTION
    APPLICATIONS item attachments are a single unnamed collection: there is no
    way to tell a resume from a statement of interest, so DTD cannot report
    which of the three is missing and an applicant cannot replace one without
    touching the others. A row per type gives each slot an identity.

    APPLICATION_DOCUMENTS itself (list, columns, lookup, indexes) is
    provisioned by New-LdpSharePointLists.ps1. This script assumes the list
    already exists and only backfills its rows for existing applications, so
    the Attachments controls have something to bind to.

    Idempotent — an application that already has a row of a given type is
    skipped, so a re-run tops up rather than duplicating.

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
    [string]$ClientId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:List  = 'APPLICATION_DOCUMENTS'
$script:Types = @('Resume', 'Statement of Interest', 'Performance Appraisal')

$script:Tally = [ordered]@{ RowsCreated = 0; RowsExisting = 0 }

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }

Write-Host ''
Write-Host 'Supporting documents — backfill one row per document type' -ForegroundColor Cyan
Write-Host "  Site  : $SiteUrl"
Write-Host "  Types : $($script:Types -join ', ')"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    # The list itself is provisioned by New-LdpSharePointLists.ps1. Fail fast
    # if it is missing rather than silently producing zero rows.
    if (-not (Get-PnPList -Identity $script:List -ErrorAction SilentlyContinue)) {
        throw "$script:List does not exist. Run build/scripts/New-LdpSharePointLists.ps1 first."
    }

    Write-Host 'Rows for existing applications' -ForegroundColor Cyan
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
    Write-Host ''

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
