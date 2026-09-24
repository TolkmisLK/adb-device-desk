param(
    [Parameter(Mandatory)][string]$Tag,
    [Parameter(Mandatory)][string]$Commit,
    [switch]$PlanOnly
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    if ($Tag -cnotmatch '^v(?<version>\d+\.\d+\.\d+)-preview\.[1-9]\d*$') { throw 'Unsupported preview tag' }
    $version = $Matches.version
    if ($Commit -cnotmatch '^[a-f0-9]{40}$') { throw 'Expected exact candidate SHA' }
    if ((& git rev-parse HEAD).Trim() -ne $Commit) { throw 'Checkout does not match candidate SHA' }
    $pubspecVersion = (Select-String -Path pubspec.yaml -Pattern '^version: (\S+)').Matches[0].Groups[1].Value.Split('+')[0]
    if ($version -ne $pubspecVersion) { throw 'Tag version must match pubspec.yaml' }
    $zip = "dist/adb-device-desk-$version-windows-x64.zip"
    $files = @($zip, "$zip.sha256", 'dist/windows-startup.json')
    if ($PlanOnly) {
        [ordered]@{ tag = $Tag; target = $Commit; draft = $false; prerelease = $true; files = $files } | ConvertTo-Json -Depth 4
        return
    }
    if (-not $env:GH_TOKEN -or -not $env:GH_REPO) { throw 'GitHub release credentials are unavailable' }
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing release asset: $file" }
    }
    $digest = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    $checksum = (Get-Content -LiteralPath "$zip.sha256" -Raw).Trim()
    if ($checksum -ne "$digest  $([IO.Path]::GetFileName($zip))") { throw 'Archive checksum mismatch' }
    $report = Get-Content -LiteralPath 'dist/windows-startup.json' -Raw | ConvertFrom-Json
    if ($report.passed -ne $true -or $report.visibleWindow -ne $true -or $report.bundleModulesVerified -ne $true -or $report.gracefulExit -ne $true -or $report.exitCode -ne 0 -or $report.responsiveSeconds -lt 10 -or $report.packageSha256 -ne $digest) { throw 'Startup evidence does not validate this archive' }
    if ($report.physicalDeviceTested -ne $false -or $report.cleanMachineTested -ne $false) { throw 'Unexpected physical acceptance claims' }

    $existing = & gh release list --limit 100 --json tagName | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect existing releases' }
    if (@($existing | Where-Object { $_.tagName -eq $Tag }).Count -gt 0) { throw 'Release already exists; refusing to overwrite it' }
    & gh release create $Tag @files --verify-tag --target $Commit --draft --prerelease --title "ADB Device Desk $Tag" --notes-file docs/RELEASE-NOTES.md
    if ($LASTEXITCODE -ne 0) { throw 'Preview draft creation failed; inspect remote state before retrying' }
    $release = & gh release view $Tag --json isDraft,isPrerelease,tagName,targetCommitish,url,assets | ConvertFrom-Json
    $assetNames = @($release.assets | ForEach-Object { $_.name })
    $expectedNames = @($files | ForEach-Object { [IO.Path]::GetFileName($_) })
    if ($LASTEXITCODE -ne 0 -or -not $release.isDraft -or -not $release.isPrerelease -or $release.tagName -ne $Tag -or @($assetNames).Count -ne $files.Count -or @($expectedNames | Where-Object { $_ -notin $assetNames }).Count -gt 0) { throw 'Preview draft assets could not be verified' }
    & gh release edit $Tag --draft=false
    if ($LASTEXITCODE -ne 0) { throw 'Preview draft publication failed; inspect remote state before retrying' }
    $release = & gh release view $Tag --json isDraft,isPrerelease,tagName,targetCommitish,url,assets | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $release.isDraft -or -not $release.isPrerelease -or $release.tagName -ne $Tag -or @($release.assets).Count -ne $files.Count) { throw 'Published preview state could not be verified' }
    $release | Select-Object tagName,isDraft,isPrerelease,targetCommitish,url | ConvertTo-Json
} finally {
    Pop-Location
}
