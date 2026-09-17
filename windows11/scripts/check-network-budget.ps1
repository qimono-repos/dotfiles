# Filename: check-network-budget.ps1
# Description: Hard-cap network RECEIVED tracking, session-budget style, with
#   monotonic accumulation. Each run adds max(0, current - lastSeen) per
#   adapter to a persistent running total, so a counter reset (reboot, adapter
#   cycle, sleep/resume) can NEVER zero out usage that was already measured.
#
# Budget default 1 GiB (1073741824 bytes), overridable with -BudgetBytes.
# Exits 1 when consumed >= budget (safety signal for build/install steps).
#
# Usage:  .\scripts\check-network-budget.ps1            (init or report)
#         .\scripts\check-network-budget.ps1 -BudgetBytes 536870912
#         .\scripts\check-network-budget.ps1 -Reset     (wipe tracking state)
# State:  %USERPROFILE%\.qimono\network-budget.json
#
# State schema:
#   {
#     "startedAt":        ISO8601 of first anchor,
#     "budgetBytes":      budget in effect,
#     "accumulatedBytes": monotonic received since startedAt,
#     "lastSeen":         { adapterName -> last counter value read },
#     "runs":             number of report invocations (incl. resets)
#   }

param(
    [long]$BudgetBytes = 1073741824,
    [switch]$Reset
)

$ErrorActionPreference = 'Stop'

function Get-Adapters {
    $adapters = @{}
    Get-NetAdapterStatistics -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -and $_.ReceivedBytes -ne $null } |
        ForEach-Object {
            $adapters[$_.Name] = @{ name = $_.Name; received = [long]$_.ReceivedBytes }
        }
    return $adapters
}

$stateDir  = Join-Path $env:USERPROFILE '.qimono'
$stateFile = Join-Path $stateDir 'network-budget.json'
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

if ($Reset) {
    Remove-Item $stateFile -Force -ErrorAction SilentlyContinue
    Write-Host '[network] tracking state cleared.' -ForegroundColor Yellow
}

$state = $null
if (Test-Path $stateFile) {
    try { $state = Get-Content $stateFile -Raw | ConvertFrom-Json } catch { $state = $null }
}

$adapters = Get-Adapters

if (-not $state) {
    # First run: no accumulated bytes yet, record current counters as lastSeen.
    $lastSeen = @{}
    foreach ($g in $adapters.Keys) { $lastSeen[$g] = [long]$adapters[$g].received }
    $state = @{
        startedAt        = (Get-Date).ToString('o')
        budgetBytes      = $BudgetBytes
        accumulatedBytes = 0L
        lastSeen         = $lastSeen
        runs             = 1
        runsReset        = 0
    }
    $state | ConvertTo-Json -Depth 4 | Set-Content -Path $stateFile -Encoding utf8
    Write-Host ('[network] tracking anchored at {0}; budget {1:N0} bytes ({2:N2} GiB)' -f (Get-Date).ToString('s'), $BudgetBytes, ($BudgetBytes / 1GB)) -ForegroundColor Cyan
}
else {
    # Accumulate per-adapter deltas since the previous read. Any adapter whose
    # counter went BACKWARD (reset) contributes 0 and gets re-anchored.
    # Guard schema evolution: files written by earlier script versions may lack
    # fields added later. Backfill them so the persistent state stays forward
    # compatible ("runsReset"/"accumulatedBytes"/"lastSeen"/"budgetBytes").
    if ($null -eq $state.runsReset)  { $state | Add-Member -NotePropertyName runsReset  -NotePropertyValue 0 -Force }
    if ($null -eq $state.lastSeen)   { $state | Add-Member -NotePropertyName lastSeen   -NotePropertyValue @{} -Force }
    if ($null -eq $state.accumulatedBytes) { $state | Add-Member -NotePropertyName accumulatedBytes -NotePropertyValue 0L -Force }
    if ($null -eq $state.budgetBytes) { $state | Add-Member -NotePropertyName budgetBytes -NotePropertyValue [long]$BudgetBytes -Force }
    if (-not $state.accumulatedBytes) { $state.accumulatedBytes = 0L }
    if (-not $state.lastSeen)         { $state.lastSeen = @{} }

    $lastSeen = @{}
    foreach ($p in $state.lastSeen.PSObject.Properties) { $lastSeen[$p.Name] = [long]$p.Value }

    $accumulated = [long]$state.accumulatedBytes
    foreach ($g in $adapters.Keys) {
        $cur = [long]$adapters[$g].received
        if ($lastSeen.ContainsKey($g)) {
            $prev = $lastSeen[$g]
            if ($cur -ge $prev) { $accumulated += $cur - $prev }
            else {
                # counter reset (boot / adapter down / sleep) -> carried 0 this cycle
                $state.runsReset = [int]$state.runsReset + 1
            }
        }
        $lastSeen[$g] = $cur
    }

    # Track adapters that disappeared (disconnected) so their counters re-base
    # when they come back rather than double-counting stale values.
    $state.accumulatedBytes = $accumulated
    $state.budgetBytes      = $BudgetBytes
    $state.lastSeen         = $lastSeen
    $state.runs             = ([int]$state.runs) + 1

    $state | ConvertTo-Json -Depth 4 | Set-Content -Path $stateFile -Encoding utf8
}

$used   = [long]$state.accumulatedBytes
$usedMB = [math]::Round($used / 1MB, 1)
$budMB  = [math]::Round($BudgetBytes / 1MB, 1)
$remain = [math]::Max(0L, $BudgetBytes - $used)

$color = 'Green'
if ($usedMB -ge 0.8 * $budMB) { $color = 'Yellow' }
if ($used -ge $BudgetBytes)   { $color = 'Red' }

$startedAt = ([string]$state.startedAt)
if ($startedAt.Length -gt 19) { $startedAt = $startedAt.Substring(0, 19) }
Write-Host ('[network] received since {0}: {1,9:N1} MB / {2:N1} MB  (remaining {3:N0} MB)' -f $startedAt, $usedMB, $budMB, ($remain / 1MB)) -ForegroundColor $color

if ($used -ge $BudgetBytes) {
    Write-Host '[network] HARD CAP REACHED — stop network activity immediately.' -ForegroundColor Red
    exit 1
}
exit 0