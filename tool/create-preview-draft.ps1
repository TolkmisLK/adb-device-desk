param(
    [Parameter(Mandatory)][string]$Ref,
    [Parameter(Mandatory)][string]$Commit,
    [switch]$PlanOnly
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    if ($Ref -cnotmatch '^refs/heads/release/draft-v(?<version>\d+\.\d+\.\d+)-preview\.(?<iteration>[1-9]\d*)$') { throw 'Unsupported draft branch name' }
    $version = $Matches.version
    $tag = "v$version-preview.$($Matches.iteration)"
    if ($Commit -cnotmatch '^[a-f0-9]{40}$') { throw 'Expected exact candidate commit SHA' }
    $pubspecVersion = (Select-String -Path pubspec.yaml -Pattern '^version: (\S+)').Matches[0].Groups[1].Value.Split('+')[0]
    if ($version -ne $pubspecVersion) { throw 'Draft version must match pubspec.yaml' }
    $zip = "dist/adb-device-desk-$version-windows-x64.zip"
    $files = @($zip, "$zip.sha256", 'dist/windows-startup.json')
    $plan = [ordered]@{ tag = $tag; target = $Commit; draft = $true; prerelease = $true; files = $files }
    if ($PlanOnly) { $plan | ConvertTo-Json -Depth 4; return }
    foreach ($file in $files) { if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing release evidence: $file" } }
    $digest = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    $checksum = (Get-Content -LiteralPath "$zip.sha256" -Raw).Trim()
    if ($checksum -ne "$digest  $([IO.Path]::GetFileName($zip))") { throw 'Release archive checksum mismatch' }
    $report = Get-Content -LiteralPath 'dist/windows-startup.json' -Raw | ConvertFrom-Json
    if ($report.passed -ne $true -or $report.visibleWindow -ne $true -or $report.bundleModulesVerified -ne $true -or $report.gracefulExit -ne $true -or $report.exitCode -ne 0 -or $report.responsiveSeconds -lt 10 -or $report.packageSha256 -ne $digest) { throw 'Startup evidence does not validate this archive' }
    # Do not infer hardware acceptance from the Windows runner's startup report.
    if ($report.physicalDeviceTested -ne $false -or $report.cleanMachineTested -ne $false) { throw 'Unexpected physical acceptance claims' }
    $existing = & gh release list --limit 100 --json tagName | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect existing releases' }
    if (@($existing | Where-Object { $_.tagName -eq $tag }).Count -gt 0) { throw 'Release already exists; refusing to overwrite it' }
    & gh release create $tag @files --target $Commit --draft --prerelease --title "ADB Device Desk $tag - development preview" --notes-file docs/RELEASE-NOTES.md
    if ($LASTEXITCODE -ne 0) { throw 'Draft creation failed; inspect remote state before retrying' }
    $release = & gh release view $tag --json isDraft,isPrerelease,tagName,targetCommitish,url | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or -not $release.isDraft -or -not $release.isPrerelease -or $release.targetCommitish -ne $Commit) { throw 'Draft state could not be verified; do not retry creation blindly' }
    $release | ConvertTo-Json
} finally { Pop-Location }
