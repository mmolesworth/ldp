<#
.SYNOPSIS
    Lists every Lookup column on the site whose target list no longer exists.

.DESCRIPTION
    Diagnoses the SharePoint error "One or more field types are not installed
    properly. Go to the list settings page to delete these fields." The message
    is generic — SharePoint does not name the offending column — but the usual
    cause is a Lookup whose target list was deleted or re-provisioned, leaving
    the lookup pointing at a GUID that no longer resolves.

    Reports only USER-CREATED, VISIBLE, DELETABLE lookup columns whose target
    is missing. Built-in SharePoint lookups (AppAuthor, user-info fields, etc.)
    are excluded — they cannot be deleted from the UI and are not what the
    error is asking about, even though many of them resolve to hidden system
    lists a naive check would flag as broken.

    Every row this script returns is a broken lookup you own. Delete each named
    field from its list at Settings > List settings > Columns, then re-run to
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
    # Resolution map INCLUDES hidden lists. Built-in lookups (AppAuthor, user
    # info, etc.) target hidden system lists like the User Information List, so
    # a map of visible lists only would flag every one of them as broken.
    $siteLists = @{}
    foreach ($l in (Get-PnPList -Includes Hidden)) {
        $siteLists[$l.Id.ToString('B').ToUpper()] = $l.Title
    }

    # Walk only the LDP lists (UPPER_SNAKE_CASE names).
    $ldpLists = Get-PnPList | Where-Object { -not $_.Hidden -and $_.Title -cmatch '^[A-Z_]+$' }

    # Only report fields the USER can act on. The error message says "delete
    # these fields" — a built-in field cannot be deleted from the UI, so it is
    # not what the error is asking about. Filter to visible + deletable +
    # not-inherited-from-base-type.
    $broken = foreach ($list in $ldpLists) {
        $customLookups = Get-PnPField -List $list | Where-Object {
            $_.TypeAsString -eq 'Lookup' -and
            -not $_.Hidden -and
            -not $_.FromBaseType -and
            $_.CanBeDeleted
        }
        foreach ($f in $customLookups) {
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
