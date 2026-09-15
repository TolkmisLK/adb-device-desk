Windows x64 desktop preview for connecting and diagnosing Android devices.

**Unpublished development preview, not stable or physical-device acceptance.** Windows CI verifies the packaged app starts, loads its bundled runtime and closes normally. Clean consumer Windows and Android USB/wireless/APK/screenshot/log workflows remain untested on actual user hardware. Keep this release as a draft until the recorded release gates are met.

- Device list with ready, offline and authorization states.
- Separate wireless pairing and connection steps.
- ADB and TCP diagnostics with structured report export.
- APK installation, screenshots, device information and logcat export.
- Chinese/English UI and automatic light/dark theme.

Download the Windows ZIP and extract the entire archive. Install Android Platform-Tools separately and select adb.exe in Settings. The SHA-256 file verifies the downloaded archive. This build is unsigned.

Windows x64 安卓设备连接与诊断工具。完整解压 ZIP 后运行，在设置中选择官方 Platform-Tools 的 adb.exe。配对端口与连接端口需要分别填写。原始设备日志分享前请检查。

Known limits: single APK only; no mirroring, batch operations or automatic reconnect. An open TCP port is not proof of ADB authorization.
