<#
.SYNOPSIS
    Makes `Validated` a value of APPLICATIONS.ApplicationStatus and removes the
    separate ValidationStatus column. See build/lists/_CHOICES.md, 2026-07-31.

.DESCRIPTION
    Supersedes the earlier build of this script, which created ValidationStatus
    as its own column. It is safe to run whether or not that one was ever run:
    every phase checks what is actually on the list rather than assuming.

      1. WIDEN     add 'Validated' to ApplicationStatus. No row rewrite is
                   needed for this on its own — widening a choice list leaves
                   existing values valid.
      2. PROMOTE   any row already carrying ValidationStatus = Validated moves
                   to ApplicationStatus = Validated, so a list that ran the old
                   script does not silently lose DTD's work. Skipped entirely
                   if that column was never created.
      3. REMOVE    drop ValidationStatus, and RevalidationFlag if it is still
                   there — ONLY with -RemoveOldColumns.

    A row is promoted only if its ApplicationStatus is currently 'Submitted'.
    A validated DRAFT or a validated WITHDRAWAL is a combination the old
    two-column schema permitted and the new one cannot express; promoting
    those would rewrite history to something that was never true, so they are
    reported and left for a human.

.PARAMETER RemoveOldColumns
    Drops ValidationStatus and RevalidationFlag. Separate on purpose: run the
    rest, re-paste the screens, confirm, then come back for this.

.EXAMPLE
    ./Update-LdpValidation.ps1 -SiteUrl https://... -ClientId <guid> -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [switch]$RemoveOldColumns,
    [switch]$SkipWiden,
    [switch]$SkipPromote
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:StatusFinal = @('Draft', 'Submitted', 'Validated', 'Withdrawn')

$script:Tally = [ordered]@{
    ChoicesWidened = 0; RowsPromoted = 0; RowsAlreadyValidated = 0
    RowsNotEligible = 0; ColumnsRemoved = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

Write-Host ''
Write-Host 'APPLICATIONS — Validated becomes an ApplicationStatus' -ForegroundColor Cyan
Write-Host "  Site        : $SiteUrl"
Write-Host "  Old columns : $(if ($RemoveOldColumns) { 'ValidationStatus + RevalidationFlag WILL BE REMOVED' } else { 'kept' })"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    $have = @{}
    foreach ($f in (Get-PnPField -List APPLICATIONS)) { $have[$f.InternalName] = $f }
    if (-not $have.ContainsKey('ApplicationStatus')) {
        throw 'ApplicationStatus does not exist. Run Update-LdpApplicationStatus.ps1 first.'
    }
    $hasValidationCol = $have.ContainsKey('ValidationStatus')
    Write-Host "  ValidationStatus column: $(if ($hasValidationCol) { 'present — rows will be promoted' } else { 'absent — nothing to promote' })"
    Write-Host ''

    # --- 1. widen -----------------------------------------------------------
    if (-not $SkipWiden) {
        Write-Host 'PHASE 1/3  ApplicationStatus choices' -ForegroundColor Cyan
        $current = @($have['ApplicationStatus'].Choices)
        if ($current -contains 'Validated') {
            Write-Kept "ApplicationStatus already offers Validated"
        } elseif ($PSCmdlet.ShouldProcess('APPLICATIONS.ApplicationStatus', 'Add the Validated choice')) {
            Set-PnPField -List APPLICATIONS -Identity 'ApplicationStatus' `
                         -Values @{ Choices = [string[]]$script:StatusFinal } | Out-Null
            Write-Made "ApplicationStatus -> $($script:StatusFinal -join ' | ')"
            $script:Tally.ChoicesWidened++
        }
        Write-Host ''
    }

    # --- 2. promote ---------------------------------------------------------
    if (-not $SkipPromote) {
        Write-Host 'PHASE 2/3  Carry over existing validations' -ForegroundColor Cyan
        if (-not $hasValidationCol) {
            Write-Kept 'no ValidationStatus column — nothing to carry over'
        } else {
            # -WhatIf leaves phase 1 unexecuted, so the Validated choice may not
            # exist yet. Writing it then would fail on an invalid value.
            $canWrite = @($have['ApplicationStatus'].Choices) -contains 'Validated'
            if (-not $canWrite) {
                Write-Held 'the Validated choice does not exist yet — expected under -WhatIf'
            }
            foreach ($item in (Get-PnPListItem -List APPLICATIONS -PageSize 500)) {
                if ([string]$item['ValidationStatus'] -ne 'Validated') { continue }
                $status = [string]$item['ApplicationStatus']
                $who    = [string]$item['ApplicantName']

                if ($status -eq 'Validated') {
                    Write-Kept "$who already Validated"
                    $script:Tally.RowsAlreadyValidated++
                    continue
                }
                if ($status -ne 'Submitted') {
                    Write-Held "$who is '$status' but flagged Validated — left alone, decide by hand"
                    $script:Tally.RowsNotEligible++
                    continue
                }
                if (-not $canWrite) { continue }
                if ($PSCmdlet.ShouldProcess("APPLICATIONS/$who", 'Set ApplicationStatus = Validated')) {
                    Set-PnPListItem -List APPLICATIONS -Identity $item.Id `
                                    -Values @{ ApplicationStatus = 'Validated' } | Out-Null
                    Write-Made "$who : Submitted -> Validated"
                    $script:Tally.RowsPromoted++
                }
            }
        }
        Write-Host ''
    }

    # --- 3. drop the old columns -------------------------------------------
    Write-Host 'PHASE 3/3  Old columns' -ForegroundColor Cyan
    if (-not $RemoveOldColumns) {
        Write-Held 'kept — pass -RemoveOldColumns once the screens no longer read them'
    } else {
        foreach ($name in 'ValidationStatus', 'RevalidationFlag') {
            if (-not $have.ContainsKey($name)) {
                Write-Kept "$name already gone"
                continue
            }
            if ($PSCmdlet.ShouldProcess("APPLICATIONS.$name", 'Remove column')) {
                Remove-PnPField -List APPLICATIONS -Identity $name -Force | Out-Null
                Write-Made "removed $name"
                $script:Tally.ColumnsRemoved++
            }
        }
    }

    Write-Host ''
    Write-Host 'Summary' -ForegroundColor Cyan
    foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-22} {1}" -f $k, $script:Tally[$k]) }
    Write-Host ''
    Write-Host 'Then: refresh APPLICATIONS in Studio and re-paste the DTD Applications,' -ForegroundColor Yellow
    Write-Host 'Application and Landing screens.' -ForegroundColor Yellow
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
