ADB Device Desk for Windows x64 (public preview).

- View connected Android devices and their authorization states.
- Pair and connect over Wi-Fi with separate pairing and connection ports.
- Install one APK on the selected device, or explicitly select multiple ready devices to install the same APK sequentially. Each device gets its own result; a failed target does not stop later targets.
- Capture PNG screenshots, inspect device information, export logcat, and run connection diagnostics.
- Use the Chinese or English interface with automatic light and dark themes.

Download the Windows ZIP and extract the whole archive. Install [Android Platform-Tools](https://developer.android.com/tools/releases/platform-tools) separately, then select `adb.exe` in Settings. ADB is not bundled. The SHA-256 file lets you verify the ZIP. This portable build is unsigned.

The package passes automated Windows build, test and extracted-startup checks. Multi-device batch installation has not yet been exercised on physical devices for this preview. Installation accepts one APK file at a time; split APK / APKS / XAPK packages are unsupported. Exported raw logcat may contain private data, so review it before sharing.

Windows x64 公开预览版。完整解压 ZIP 后运行，另行安装 Android 官方 Platform-Tools，并在设置中选择 `adb.exe`。可明确勾选多台已连接设备，将同一个 APK 逐台安装并查看各台结果；单台失败不影响后续设备。本预览版的批量安装尚未完成多台真机验收。原始日志分享前请检查。
