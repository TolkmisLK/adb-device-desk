param(
    [Parameter(Mandatory = $true)][string]$ArchivePath,
    [Parameter(Mandatory = $true)][string]$ReportPath
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $IsWindows) { throw 'This acceptance check requires Windows' }
$archive = (Resolve-Path -LiteralPath $ArchivePath).Path
$reportFile = [IO.Path]::GetFullPath($ReportPath)
$expected = ((Get-Content -LiteralPath "$archive.sha256" -Raw).Trim() -split '\s+')[0]
$actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($expected -notmatch '^[a-f0-9]{64}$' -or $expected -ne $actual) { throw 'Portable archive checksum mismatch' }
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('adb-desk-startup-' + [guid]::NewGuid().ToString('N'))
$bundle = Join-Path $fixture 'bundle'
$config = Join-Path $fixture 'config'
$oldAppData = $env:APPDATA
$child = $null
$result = [ordered]@{
    schema = 1
    platform = 'windows-x64'
    packageSha256 = $actual
    passed = $false
    visibleWindow = $false
    responsiveSeconds = 0
    gracefulExit = $false
    bundleModulesVerified = $false
    exitCode = $null
    physicalDeviceTested = $false
    cleanMachineTested = $false
}
try {
    New-Item -ItemType Directory -Path $fixture | Out-Null
    Expand-Archive -LiteralPath $archive -DestinationPath $bundle
    foreach ($name in @('adb_device_desk.exe', 'flutter_windows.dll', 'file_selector_windows_plugin.dll', 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll', 'data/flutter_assets', 'LICENSE.txt', 'WINDOWS-QUICKSTART.txt')) {
        if (-not (Test-Path -LiteralPath (Join-Path $bundle $name))) { throw "Missing extracted bundle component: $name" }
    }
    $settingsDir = Join-Path $config 'adb-device-desk'
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    # Use only a private generated profile and a guaranteed absent ADB path.
    # Starting this check cannot operate on a connected Android device.
    @{ adbPath = (Join-Path $fixture 'intentionally-absent-adb.exe'); english = $true } |
        ConvertTo-Json | Set-Content -LiteralPath (Join-Path $settingsDir 'settings.json') -Encoding utf8
    $env:APPDATA = $config
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class AdbDeskWindowProbe {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hwnd);
}
'@
    $child = Start-Process -FilePath (Join-Path $bundle 'adb_device_desk.exe') -WorkingDirectory $bundle -PassThru
    $deadline = [DateTime]::UtcNow.AddSeconds(45)
    do {
        Start-Sleep -Milliseconds 250
        $child.Refresh()
        if ($child.HasExited) { throw "Application exited before window creation: $($child.ExitCode)" }
        $visible = $child.MainWindowHandle -ne [IntPtr]::Zero -and [AdbDeskWindowProbe]::IsWindowVisible($child.MainWindowHandle)
    } while (-not $visible -and [DateTime]::UtcNow -lt $deadline)
    if (-not $visible) { throw 'Application did not present a visible native window within 45 seconds' }
    if ($child.MainWindowTitle -ne 'ADB Device Desk') { throw 'Unexpected application window title' }
    $result.visibleWindow = $true
    # The Windows runner shows this window from its first-Flutter-frame callback.
    # Visibility plus responsiveness is startup evidence, not visual UI review.
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 1
        $child.Refresh()
        if ($child.HasExited -or -not $child.Responding) { throw 'Application exited or stopped responding during startup observation' }
        $result.responsiveSeconds++
    }
    $modules = @($child.Modules)
    foreach ($name in @('flutter_windows.dll', 'file_selector_windows_plugin.dll', 'msvcp140.dll', 'vcruntime140.dll')) {
        $loaded = @($modules | Where-Object { $_.ModuleName -ieq $name })
        if ($loaded.Count -ne 1 -or -not [string]::Equals($loaded[0].FileName, (Join-Path $bundle $name), [StringComparison]::OrdinalIgnoreCase)) {
            throw "Required module was not loaded from the extracted bundle: $name"
        }
    }
    $result.bundleModulesVerified = $true
    if (-not $child.CloseMainWindow()) { throw 'Application refused its normal window-close request' }
    if (-not $child.WaitForExit(10000)) { throw 'Application did not exit after its normal window-close request' }
    if ($child.ExitCode -ne 0) { throw "Application returned a nonzero exit code: $($child.ExitCode)" }
    $result.gracefulExit = $true
    $result.exitCode = $child.ExitCode
    $result.passed = $true
} finally {
    if ($child) {
        $child.Refresh()
        if (-not $child.HasExited) { $child.Kill($true); $child.WaitForExit(10000) | Out-Null }
        $child.Dispose()
    }
    if ($null -eq $oldAppData) { Remove-Item Env:APPDATA -ErrorAction SilentlyContinue } else { $env:APPDATA = $oldAppData }
    New-Item -ItemType Directory -Path (Split-Path $reportFile -Parent) -Force | Out-Null
    $result | ConvertTo-Json | Set-Content -LiteralPath $reportFile -Encoding utf8
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
Write-Output 'Extracted Windows bundle: checksum, visible window, responsiveness, local DLL loading and clean exit passed.'
