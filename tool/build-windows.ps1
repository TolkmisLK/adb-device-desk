param([string]$Version = '0.1.0')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Version -notmatch '^\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?$') { throw 'Invalid version' }
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    $pubspecVersion = (Select-String -Path pubspec.yaml -Pattern '^version: (\S+)').Matches[0].Groups[1].Value.Split('+')[0]
    if ($Version -ne $pubspecVersion) { throw 'Version must match pubspec.yaml' }
    if (-not (Test-Path 'windows/CMakeLists.txt')) {
        & flutter create --platforms=windows --project-name=adb_device_desk --org=dev.ncc --empty --no-pub .
        if ($LASTEXITCODE -ne 0) { throw 'Windows runner generation failed' }
    }
    & flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'Flutter Windows build failed' }
    $bundle = Join-Path (Get-Location) 'build/windows/x64/runner/Release'
    foreach ($required in @('adb_device_desk.exe', 'flutter_windows.dll', 'data')) {
        if (-not (Test-Path (Join-Path $bundle $required))) { throw "Missing bundle component: $required" }
    }

    # Flutter Windows executables need the MSVC runtime alongside the bundle.
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (-not (Test-Path $vswhere)) { throw 'Visual Studio locator not found' }
    $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) { throw 'Visual C++ toolchain not found' }
    $redist = Get-ChildItem (Join-Path $vs 'VC/Redist/MSVC') -Directory |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+' } |
        Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
    if (-not $redist) { throw 'Visual C++ redistributable directory not found' }
    $crt = Get-ChildItem (Join-Path $redist.FullName 'x64') -Directory -Filter '*.CRT' | Select-Object -First 1
    if (-not $crt) { throw 'x64 CRT directory not found' }
    foreach ($dll in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
        $source = Join-Path $crt.FullName $dll
        if (-not (Test-Path $source)) { throw "Missing runtime: $dll" }
        Copy-Item $source $bundle -Force
    }
    Copy-Item LICENSE (Join-Path $bundle 'LICENSE.txt') -Force
    Copy-Item docs/WINDOWS-QUICKSTART.txt $bundle -Force
    New-Item -ItemType Directory -Force dist | Out-Null
    $zip = Join-Path (Get-Location) "dist/adb-device-desk-$Version-windows-x64.zip"
    Compress-Archive -Path "$bundle/*" -DestinationPath $zip -Force
    $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $([IO.Path]::GetFileName($zip))" | Set-Content "$zip.sha256" -Encoding ascii
    & (Join-Path $PSScriptRoot 'test-windows-startup.ps1') -ArchivePath $zip -ReportPath (Join-Path (Get-Location) 'dist/windows-startup.json')
    Write-Output $zip
} finally {
    Pop-Location
}
