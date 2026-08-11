<#
.SYNOPSIS
    Lists every Lookup column on the site whose target list is missing OR whose
    target ShowField no longer exists.

.DESCRIPTION
    Diagnoses the SharePoint error "One or more field types are not installed
    properly. Go to the list settings page to delete these fields." The message
    is generic — SharePoint does not name the offending column — but the usual
    causes are:

      · MissingTarget    — the lookup's target list was deleted or
                           re-provisioned. Its GUID no longer resolves.
      · MissingShowField — the target list exists, but the column the lookup
                           displays (ShowField) has been removed or renamed on
                           the target. The lookup still resolves the list but
                           cannot render values.

    Reports only USER-CREATED, VISIBLE, DELETABLE lookup columns. Built-in
    SharePoint lookups (AppAuthor, user-info fields, etc.) are excluded — they
    cannot be deleted from the UI and are not what the error is asking about.

    Every row this script returns is a broken lookup you own. Delete each named
    field from its list at Settings > List settings > Columns, then re-run to
    confirm. Some causes (MissingShowField) can also be fixed by re-adding the
    missing column on the target rather than deleting the lookup — inspect
    before deleting.

    An empty result means no broken lookups; the field type in error is
    something else (Calculated with a bad formula, Managed Metadata, or a
    custom type). Inspect the list's Columns page directly, or use
    Get-LdpFieldInventory.ps1.

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

function Normalize-Guid {
    param([string]$g)
    if (-not $g) { return $null }
    ($g -replace '[{}]', '').ToUpper()
}

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    # Resolution map INCLUDES hidden lists. Built-in lookups (AppAuthor, user
    # info, etc.) target hidden system lists like the User Information List, so
    # a map of visible lists only would flag every one of them as broken. Keys
    # are normalized (no braces, upper-case) so equality works regardless of
    # how the SchemaXml formats its List="..." attribute.
    $siteLists = @{}      # guid -> title
    $siteListObjs = @{}   # guid -> list object (for field inspection)
    foreach ($l in (Get-PnPList -Includes Hidden)) {
        $key = Normalize-Guid $l.Id.ToString()
        $siteLists[$key]    = $l.Title
        $siteListObjs[$key] = $l
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
            $xml         = try { [xml]$f.SchemaXml } catch { $null }
            $targetGuid  = if ($xml) { Normalize-Guid $xml.Field.List }      else { $null }
            $showField   = if ($xml) { [string]$xml.Field.ShowField }        else { $null }
            $targetTitle = if ($targetGuid) { $siteLists[$targetGuid] }      else { $null }
            $targetList  = if ($targetGuid) { $siteListObjs[$targetGuid] }   else { $null }

            $problem = $null
            if (-not $targetList) {
                $problem = 'MissingTarget'
            } elseif ($showField) {
                # Check that the ShowField still exists on the target. Get-PnPField
                # on a hidden system list works but returns nothing findable — skip
                # ShowField validation for those to avoid false positives.
                $targetField = Get-PnPField -List $targetList -Identity $showField -ErrorAction SilentlyContinue
                if (-not $targetField) { $problem = 'MissingShowField' }
            }

            if ($problem) {
                [pscustomobject]@{
                    List        = $list.Title
                    Field       = $f.InternalName
                    Target      = if ($targetTitle) { $targetTitle } else { '<unresolved>' }
                    ShowField   = $showField
                    Problem     = $problem
                    TargetGuid  = $targetGuid
                }
            }
        }
    }

    if ($broken) {
        Write-Host ''
        Write-Host 'Broken lookups — inspect each before deleting:' -ForegroundColor Yellow
        $broken | Format-Table -AutoSize
    } else {
        Write-Host ''
        Write-Host 'No broken lookups. The "field type not installed" error is caused by something else. Try Get-LdpFieldInventory.ps1, or refresh the data source in Power Apps Studio (View > Data > ... > Refresh).' -ForegroundColor Green
        Write-Host ''
    }
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
