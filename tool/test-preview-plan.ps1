$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script = Join-Path $PSScriptRoot 'create-preview-draft.ps1'
$sha = 'a' * 40
$plan = & $script -Ref 'refs/heads/release/draft-v0.1.0-preview.1' -Commit $sha -PlanOnly | ConvertFrom-Json
if ($plan.tag -ne 'v0.1.0-preview.1' -or $plan.target -ne $sha -or -not $plan.draft -or -not $plan.prerelease -or $plan.files.Count -ne 3) { throw 'Incorrect preview plan' }
foreach ($ref in @('refs/heads/main', 'refs/heads/release/draft-v0.1.0-preview.0', 'refs/heads/release/draft-v0.1.0-preview.1/extra', 'refs/heads/release/draft-v9.9.9-preview.1', 'refs/tags/v0.1.0')) {
    $rejected = $false
    try { & $script -Ref $ref -Commit $sha -PlanOnly | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw "Unsafe ref accepted: $ref" }
}
$rejected = $false
try { & $script -Ref 'refs/heads/release/draft-v0.1.0-preview.1' -Commit 'main' -PlanOnly | Out-Null } catch { $rejected = $true }
if (-not $rejected) { throw 'Mutable release target accepted' }
Write-Output 'Preview release plan: 7 checks passed; no GitHub write performed.'
