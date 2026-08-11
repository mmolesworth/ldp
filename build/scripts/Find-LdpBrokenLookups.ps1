<#
.SYNOPSIS
    Lists every Lookup column on the site whose target list no longer exists.

.DESCRIPTION
    Diagnoses the SharePoint error "One or more field types are not installed
    properly. Go to the list settings page to delete these fields." The message
    is generic — SharePoint does not name the offending column — but the usual
    cause is a Lookup whose target list was deleted or re-provisioned, leaving
    the lookup pointing at a GUID that no longer resolves.

    Every row this script returns is a broken lookup. Delete each named field
    from its list at Settings > List settings > Columns, then re-run to
    confirm.

    An empty result means no broken lookups; the field type in error is
    something else (Calculated with a bad formula, Managed Metadata, or a
    custom type). Inspect the list's Columns page directly.

    READ-ONLY. Nothing is modified.

.EXAMPLE
    ./Find-LdpBrokenLookups.ps1 -SiteUrl https://... -ClientId <guid>
#>
[CmdletBinding()]
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

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    # Map every list ID on the site so we can resolve each lookup's target.
    # Built once, outside the per-list loop.
    $siteLists = @{}
    foreach ($l in (Get-PnPList)) {
        $siteLists[$l.Id.ToString('B').ToUpper()] = $l.Title
    }

    # Only walk the LDP lists (UPPER_SNAKE_CASE names) and skip hidden system
    # lists — SharePoint ships plenty of its own that we do not care about.
    $ldpLists = Get-PnPList | Where-Object { -not $_.Hidden -and $_.Title -cmatch '^[A-Z_]+$' }

    $broken = foreach ($list in $ldpLists) {
        foreach ($f in (Get-PnPField -List $list | Where-Object TypeAsString -eq 'Lookup')) {
            $targetGuid = try { ([xml]$f.SchemaXml).Field.List } catch { $null }
            $targetOk   = $targetGuid -and $siteLists.ContainsKey($targetGuid.ToUpper())
            if (-not $targetOk) {
                [pscustomobject]@{
                    List        = $list.Title
                    Field       = $f.InternalName
                    TargetGuid  = $targetGuid
                    TargetFound = $targetOk
                }
            }
        }
    }

    if ($broken) {
        Write-Host ''
        Write-Host 'Broken lookups — delete each field from its list:' -ForegroundColor Yellow
        $broken | Format-Table -AutoSize
    } else {
        Write-Host ''
        Write-Host 'No broken lookups. The "field type not installed" error is caused by something else (Calculated formula, Managed Metadata, or a custom type). Inspect the list Columns page directly.' -ForegroundColor Green
        Write-Host ''
    }
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
