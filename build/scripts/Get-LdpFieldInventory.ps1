<#
.SYNOPSIS
    Dumps every user-visible, user-deletable field on one or more lists with
    its type — for tracking down "field type not installed properly" errors.

.DESCRIPTION
    Power Apps reads every column's schema for any list it queries. A single
    column with an unrecognized type (Calculated with a broken formula,
    Managed Metadata when the Term Store is not set up, or a custom type)
    breaks all reads from that list, even if nothing in the app touches that
    column.

    Filters out built-in SharePoint fields (Author, Created, etc.) so the
    output is only columns you own and can act on. For each column, prints its
    InternalName, Type, and — for Calculated columns — the Formula, since
    that is where the failure usually lives.

    Default target is APPLICATIONS and APPLICATION_PROGRAM_CHOICES, the two
    lists the Committee Queue Screen queries. Override with -List.

    READ-ONLY. Nothing is modified.

.PARAMETER List
    One or more list titles to inspect. Defaults to APPLICATIONS and
    APPLICATION_PROGRAM_CHOICES.

.EXAMPLE
    ./Get-LdpFieldInventory.ps1 -SiteUrl https://... -ClientId <guid>

.EXAMPLE
    ./Get-LdpFieldInventory.ps1 -SiteUrl https://... -ClientId <guid> -List COMMITTEES, RATING_SHEETS
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [string[]]$List = @('APPLICATIONS', 'APPLICATION_PROGRAM_CHOICES')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Types the provisioning + migration scripts create. Anything else on an LDP
# list came from somewhere outside this repo (a manual SharePoint UI edit, a
# Flow, a solution package) and is a candidate for the source of the error.
$script:KnownTypes = @('Text', 'Note', 'Number', 'Choice', 'DateTime', 'Lookup', 'Boolean', 'Counter', 'Computed')

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    foreach ($listTitle in $List) {
        $listObj = Get-PnPList -Identity $listTitle -ErrorAction SilentlyContinue
        if (-not $listObj) {
            Write-Host ''
            Write-Host "$listTitle - list not found" -ForegroundColor Red
            continue
        }

        Write-Host ''
        Write-Host "=== $listTitle ===" -ForegroundColor Cyan

        $custom = Get-PnPField -List $listTitle | Where-Object {
            -not $_.Hidden -and -not $_.FromBaseType -and $_.CanBeDeleted
        }

        $rows = foreach ($f in $custom) {
            $formula = if ($f.TypeAsString -eq 'Calculated') {
                try { ([xml]$f.SchemaXml).Field.Formula } catch { '<unreadable>' }
            } else { '' }

            $suspicious = $f.TypeAsString -notin $script:KnownTypes

            [pscustomobject]@{
                InternalName = $f.InternalName
                Type         = $f.TypeAsString
                Suspicious   = if ($suspicious) { 'YES' } else { '' }
                Formula      = $formula
            }
        }

        if (-not $rows) {
            Write-Host '  (no custom fields)' -ForegroundColor DarkGray
            continue
        }

        $rows | Format-Table -AutoSize

        $flagged = @($rows | Where-Object Suspicious -eq 'YES')
        if ($flagged) {
            Write-Host "  ^ $($flagged.Count) field(s) with unfamiliar type — likely culprits." -ForegroundColor Yellow
        }
    }
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
