<#
.SYNOPSIS
    Repoints the supervisor emails on the @ldptest.invalid applications so the
    signed-in user shows up on the Supervisor Endorsement Screen.

.DESCRIPTION
    Add-LdpTestApplications.ps1 sets FirstLineSupervisorEmail = firstline@ldptest.invalid
    and SecondLineSupervisorEmail = secondline@ldptest.invalid on every Submitted
    or later test row. The Supervisor Endorsement Screen filters APPLICATIONS on

        Or(FirstLineSupervisorEmail = User().Email,
           SecondLineSupervisorEmail = User().Email)

    so the queue is empty for any real user until those two columns hold their
    email. This script rewrites both to whatever the two parameters below say,
    on the test rows only — no other application is touched.

    ONLY the @ldptest.invalid rows. The reserved TLD is the same safe key
    Add-LdpTestApplications.ps1 and its -Remove use, so this cannot leak into
    real applications.

    Draft rows are skipped. Add-LdpTestApplications.ps1 leaves them without
    supervisors on purpose — a supervisor is snapshotted at submission (R1/R5)
    — and this script preserves that. Withdrawn rows are updated: the screen
    filters them out anyway, but leaving them out of sync would surprise the
    next person to reopen the data.

    Idempotent — a row already holding both target values is skipped.

.PARAMETER FirstLineSupervisorEmail
    Written to APPLICATIONS.FirstLineSupervisorEmail on every test row.
    Defaults to Mark's tenant login.

.PARAMETER SecondLineSupervisorEmail
    Written to APPLICATIONS.SecondLineSupervisorEmail on every test row.
    Defaults to the same value as FirstLineSupervisorEmail, so the signed-in
    user sees every row and can act on whichever stage is their turn.

.EXAMPLE
    ./Update-LdpTestSupervisors.ps1 -SiteUrl https://... -ClientId <guid>

.EXAMPLE
    ./Update-LdpTestSupervisors.ps1 -SiteUrl https://... -ClientId <guid> `
        -FirstLineSupervisorEmail alice@contoso.com `
        -SecondLineSupervisorEmail bob@contoso.com
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://.+')]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ClientId,

    [string]$FirstLineSupervisorEmail = 'MarkMolesworth@MarkMolesworth.onmicrosoft.com',

    [string]$SecondLineSupervisorEmail
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $SecondLineSupervisorEmail) { $SecondLineSupervisorEmail = $FirstLineSupervisorEmail }

$script:TestDomain = '@ldptest.invalid'

$script:Tally = [ordered]@{
    RowsUpdated = 0; RowsAlreadyCurrent = 0; DraftsSkipped = 0
}

function Write-Made { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }
function Write-Kept { param([string]$m) Write-Host "  = $m" -ForegroundColor DarkGray }
function Write-Held { param([string]$m) Write-Host "  ~ $m" -ForegroundColor Yellow }

Write-Host ''
Write-Host 'LDP test supervisors — repoint the queue at a real user' -ForegroundColor Cyan
Write-Host "  Site         : $SiteUrl"
Write-Host "  First line   : $FirstLineSupervisorEmail"
Write-Host "  Second line  : $SecondLineSupervisorEmail"
Write-Host ''

Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId
try {
    $tests = @(Get-PnPListItem -List APPLICATIONS -PageSize 500 |
               Where-Object { [string]$_['ApplicantEmail'] -like "*$script:TestDomain" })

    if ($tests.Count -eq 0) {
        Write-Held "No @ldptest.invalid applications found. Run Add-LdpTestApplications.ps1 first."
        return
    }

    Write-Host "Found $($tests.Count) test application(s)." -ForegroundColor Cyan
    Write-Host ''

    foreach ($a in $tests) {
        $name   = [string]$a['ApplicantName']
        $status = [string]$a['ApplicationStatus']

        if ($status -eq 'Draft') {
            Write-Kept "$name — Draft, no supervisor snapshotted (skipped)"
            $script:Tally.DraftsSkipped++
            continue
        }

        $currentFirst  = [string]$a['FirstLineSupervisorEmail']
        $currentSecond = [string]$a['SecondLineSupervisorEmail']

        if ($currentFirst -eq $FirstLineSupervisorEmail -and
            $currentSecond -eq $SecondLineSupervisorEmail) {
            Write-Kept "$name — already current"
            $script:Tally.RowsAlreadyCurrent++
            continue
        }

        if ($PSCmdlet.ShouldProcess("APPLICATIONS/$name", 'Repoint supervisor emails')) {
            Set-PnPListItem -List APPLICATIONS -Identity $a.Id -Values @{
                FirstLineSupervisorEmail  = $FirstLineSupervisorEmail
                SecondLineSupervisorEmail = $SecondLineSupervisorEmail
            } | Out-Null
            Write-Made "$name — $status"
            $script:Tally.RowsUpdated++
        }
    }

    Write-Host ''
    Write-Host 'Summary' -ForegroundColor Cyan
    foreach ($k in $script:Tally.Keys) { Write-Host ("  {0,-20} {1}" -f $k, $script:Tally[$k]) }
    Write-Host ''
    Write-Host 'Then: refresh APPLICATIONS in Power Apps Studio, F5 the Supervisor' -ForegroundColor Yellow
    Write-Host 'Endorsement Screen. Marcus (Pending First-Line) and Priya (Pending' -ForegroundColor Yellow
    Write-Host 'Second-Line) are the two ready to act on; the rest are view-only.' -ForegroundColor Yellow
    Write-Host ''
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
