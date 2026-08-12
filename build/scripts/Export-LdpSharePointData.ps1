<#
.SYNOPSIS
    Exports every LDP SharePoint list to a CSV under build/scripts/exports/.

.DESCRIPTION
    Reads all 17 lists that make up the LDP schema (as provisioned by
    New-LdpSharePointLists.ps1) and dumps each to its own CSV. Lookup and
    choice values are flattened to their display strings so the file is
    human-readable and diffable against the spec .md files.

    Two uses:
      1. VERIFY   — compare the exported column set of each list against the
                    matching build/lists/*.md spec to catch drift.
      2. SEED     — hand-select rows to use as sample data when standing up a
                    new tenant. Reference-data lists (CYCLES, PROGRAMS,
                    PROGRAM_OPTIONS, COMPETENCY_TYPES, COMPETENCIES,
                    CRITERION_CATALOG, CRITERION_ANCHORS) are the ones you
                    typically want to carry over verbatim.

    Read-only. Never writes to SharePoint. Idempotent — a re-run overwrites the
    exports/ files in place.

.PARAMETER SiteUrl
    Full URL of the SharePoint site containing the LDP lists.

.PARAMETER ClientId
    App registration client ID with permission to read the site.

.PARAMETER ExportPath
    Directory to write the CSVs to. Defaults to ./exports (relative to the
    current working directory, i.e. wherever you invoke the script). Created
    if missing. Missing intermediate directories are created too.

.PARAMETER Lists
    Optional filter — only export the named lists. Handy for a spot-check.

.EXAMPLE
    ./Export-LdpSharePointData.ps1 -SiteUrl https://tenant.sharepoint.com/sites/ldp -ClientId <guid>

.EXAMPLE
    # Just the reference tables:
    ./Export-LdpSharePointData.ps1 -SiteUrl ... -ClientId ... `
        -Lists CYCLES,PROGRAMS,PROGRAM_OPTIONS,COMPETENCY_TYPES,COMPETENCIES
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [string]$ExportPath = './exports',

    [string[]]$Lists
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Dependency-safe order. Parents first, children after. Useful when the CSVs
# are later fed back into a new tenant — CYCLES and PROGRAMS have to exist
# before APPLICATIONS can reference them, and so on.
$AllLists = @(
    'CYCLES',
    'PROGRAMS',
    'COMPETENCY_TYPES',
    'CRITERION_CATALOG',
    'PROGRAM_OPTIONS',
    'COMPETENCIES',
    'CRITERION_ANCHORS',
    'APPLICATIONS',
    'APPLICATION_COMPETENCIES',
    'APPLICATION_PROGRAM_CHOICES',
    'SUPERVISOR_ENDORSEMENTS',
    'RATING_SHEETS',
    'RATING_CRITERIA',
    'COMMITTEES',
    'COMMITTEE_CRITERION_SCORES',
    'NOTIFICATIONS',
    'CHANGE_HISTORY'
)

$Targets = if ($Lists) { $AllLists | Where-Object { $Lists -contains $_ } } else { $AllLists }

if (-not (Test-Path $ExportPath)) {
    New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
}
$ExportPath = (Resolve-Path $ExportPath).Path

Write-Host ''
Write-Host 'LDP SharePoint export' -ForegroundColor Cyan
Write-Host "  Site   : $SiteUrl"
Write-Host "  Output : $ExportPath"
Write-Host "  Lists  : $($Targets.Count) of $($AllLists.Count)"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

# The columns we defined for a list. FromBaseType is false for every column
# added via Add-PnPField / Add-PnPFieldFromXml, so this excludes SharePoint's
# built-in noise (Title, Author, Modified, _UIVersion, ComplianceAssetId,
# Attachments, ContentType, ...) without a hand-maintained allow-list.
function Get-LdpColumns {
    param([Parameter(Mandatory)][string]$List)
    $custom = Get-PnPField -List $List -ErrorAction Stop |
              Where-Object { -not $_.FromBaseType } |
              ForEach-Object InternalName
    @('ID') + @($custom)
}

# Flattens one item to a row of scalars for Export-Csv, projecting only the
# named columns. Lookups become their LookupValue; multi-value fields become
# semicolon-joined strings.
function Flatten-Item {
    param(
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][string[]]$Columns
    )

    $row = [ordered]@{}
    foreach ($key in $Columns) {
        $raw = if ($Item.FieldValues.ContainsKey($key)) { $Item.FieldValues[$key] } else { $null }
        $row[$key] = switch ($true) {
            { $null -eq $raw }                                             { '' ; break }
            { $raw -is [Microsoft.SharePoint.Client.FieldLookupValue] }    { $raw.LookupValue ; break }
            { $raw -is [Microsoft.SharePoint.Client.FieldLookupValue[]] }  { ($raw | ForEach-Object LookupValue) -join '; ' ; break }
            { $raw -is [Microsoft.SharePoint.Client.FieldUserValue] }      { $raw.Email ; break }
            { $raw -is [Microsoft.SharePoint.Client.FieldUserValue[]] }    { ($raw | ForEach-Object Email) -join '; ' ; break }
            { $raw -is [array] }                                           { ($raw | ForEach-Object { [string]$_ }) -join '; ' ; break }
            default                                                        { [string]$raw }
        }
    }
    [pscustomobject]$row
}

$tally = [ordered]@{}
foreach ($list in $Targets) {
    try {
        $columns = Get-LdpColumns -List $list
        $items   = @(Get-PnPListItem -List $list -PageSize 500 -ErrorAction Stop)
    } catch {
        Write-Host ("  ! {0,-30} does not exist on this site — skipped" -f $list) -ForegroundColor Yellow
        $tally[$list] = 'missing'
        continue
    }

    $rows = @($items | ForEach-Object { Flatten-Item -Item $_ -Columns $columns })
    $out  = Join-Path $ExportPath ("{0}.csv" -f $list)

    if ($rows.Count -eq 0) {
        # Export-Csv with no rows would leave an empty file. Emit a header-only
        # file so a downstream diff can still see the column set.
        ($columns -join ',') | Set-Content -Path $out -Encoding UTF8
        Write-Host ("  = {0,-30} 0 rows (header only)" -f $list) -ForegroundColor DarkGray
    } else {
        $rows | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
        Write-Host ("  + {0,-30} {1,4} rows" -f $list, $rows.Count) -ForegroundColor Green
    }
    $tally[$list] = $rows.Count
}

Write-Host ''
Write-Host 'Done.' -ForegroundColor Cyan
Write-Host ''
