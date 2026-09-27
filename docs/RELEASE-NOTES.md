ADB Device Desk for Windows x64 (public preview).

- View connected Android devices and their authorization states.
- Pair and connect over Wi-Fi with separate pairing and connection ports.
- Install one APK on the selected device, or explicitly select multiple ready devices to install the same APK sequentially. Each device gets its own result; a failed target does not stop later targets.
- Installation results now identify five package-manager failures when ADB reports them: insufficient storage, signature mismatch, version downgrade, Android version too old, and incompatible CPU architecture. Other failures retain the general message.
- Capture PNG screenshots, inspect device information, export logcat, and run connection diagnostics.
- Use the Chinese or English interface with automatic light and dark themes.

Download the Windows ZIP and extract the whole archive. Install [Android Platform-Tools](https://developer.android.com/tools/releases/platform-tools) separately, then select `adb.exe` in Settings. ADB is not bundled. The SHA-256 file lets you verify the ZIP. This portable build is unsigned.

The package passes automated Windows build, test and extracted-startup checks. The maintainer reports physical-device acceptance of the earlier batch flow; the new failure-specific messages in this preview have automated coverage but no recorded physical-device check. Installation accepts one APK file at a time; split APK / APKS / XAPK packages are unsupported. Exported raw logcat may contain private data, so review it before sharing.

Windows x64 公开预览版。完整解压 ZIP 后运行，另行安装 Android 官方 Platform-Tools，并在设置中选择 `adb.exe`。可明确勾选多台已连接设备，将同一个 APK 逐台安装并查看各台结果；单台失败不影响后续设备。ADB 明确返回存储不足、签名冲突、版本降级、系统版本过低或处理器架构不匹配时，会显示对应原因。维护者已报告对先前批量安装流程进行了真机验收；本次新增的错误细分提示仅有自动化验证，尚无真机核验记录。分享原始日志前请检查。
