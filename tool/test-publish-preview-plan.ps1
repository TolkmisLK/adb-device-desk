$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script = Join-Path $PSScriptRoot 'publish-preview.ps1'
$sha = (& git rev-parse HEAD).Trim()
$plan = & $script -Tag 'v0.1.0-preview.2' -Commit $sha -PlanOnly | ConvertFrom-Json
if ($plan.tag -ne 'v0.1.0-preview.2' -or $plan.target -ne $sha -or $plan.draft -or -not $plan.prerelease -or $plan.files.Count -ne 3) { throw 'Incorrect public preview plan' }
foreach ($tag in @('v0.1.0', 'v0.1.0-preview.0', 'v0.1.0-preview.2/extra', 'v9.9.9-preview.2')) {
    $rejected = $false
    try { & $script -Tag $tag -Commit $sha -PlanOnly | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw "Unsafe tag accepted: $tag" }
}
$rejected = $false
try { & $script -Tag 'v0.1.0-preview.2' -Commit ('a' * 40) -PlanOnly | Out-Null } catch { $rejected = $true }
if (-not $rejected) { throw 'Non-checkout target accepted' }
Write-Output 'Public preview plan: 6 checks passed; no GitHub write performed.'
