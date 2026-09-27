ADB Device Desk for Windows x64 (public preview).

- View connected Android devices and their authorization states.
- Pair and connect over Wi-Fi with separate pairing and connection ports.
- Install one APK on the selected device, or explicitly select multiple ready devices to install the same APK sequentially. Each device gets its own result; a failed target does not stop later targets.
- Installation results now identify five package-manager failures when ADB reports them: insufficient storage, signature mismatch, version downgrade, Android version too old, and incompatible CPU architecture. Other failures retain the general message.
- Capture PNG screenshots, inspect device information, export logcat, and run connection diagnostics.
- Use the Chinese or English interface with automatic light and dark themes.

Download the Windows ZIP and extract the whole archive. Install [Android Platform-Tools](https://developer.android.com/tools/releases/platform-tools) separately, then select `adb.exe` in Settings. ADB is not bundled. The SHA-256 file lets you verify the ZIP. This portable build is unsigned.

The package passes automated Windows build, test and extracted-startup checks. The maintainer previously reported usable ADB device operations, but no two-device batch-installation acceptance or physical check of the new failure-specific messages is recorded. Both have automated coverage. Installation accepts one APK file at a time; split APK / APKS / XAPK packages are unsupported. Exported raw logcat may contain private data, so review it before sharing.

Windows x64 公开预览版。完整解压 ZIP 后运行，另行安装 Android 官方 Platform-Tools，并在设置中选择 `adb.exe`。可明确勾选多台已连接设备，将同一个 APK 逐台安装并查看各台结果；单台失败不影响后续设备。ADB 明确返回存储不足、签名冲突、版本降级、系统版本过低或处理器架构不匹配时，会显示对应原因。维护者此前报告 ADB 设备操作可用；两台设备的批量安装和本次错误细分提示有自动化覆盖，但尚无真机验收记录。分享原始日志前请检查。

## 中文详细说明

下载请到 [v0.1.0-preview.3 发布页](https://github.com/TolkmisLK/adb-device-desk/releases/tag/v0.1.0-preview.3)，Windows x64 用户下载 ZIP，完整解压并运行 `adb_device_desk.exe`。同页的 SHA-256 文件可用于校验 ZIP；便携程序未签名。ADB 不在包内，需从 [Android 官方 Platform-Tools](https://developer.android.com/tools/releases/platform-tools)另行下载，在程序「设置」中选择 `adb.exe` 并验证。逐步图文和排错见[中文使用指南](USER-GUIDE.zh-CN.md)。

- 设备页列出设备及授权状态。USB 要在设备上开启调试并接受授权；Android 11+ 无线连接先用配对弹窗的端口及六位码配对，再用无线调试主页面的连接端口连接。
- 选中一台已连接设备后，可安装一个 `.apk`、保存 PNG 截图、查看设备基本信息、导出 logcat 和进行连接诊断。
- 「批量安装 APK」须逐台明确勾选目标，对每台依次安装同一个 APK 并显示各台结果；失败的目标不会阻止后续目标。单台安装最长等待三分钟。
- 只有当 ADB 返回对应代码，才显示存储不足、同包名应用签名不匹配、版本降级、设备 Android 版本过低、CPU 架构不兼容这五种明确原因；其他错误使用通用提示。签名不匹配时卸载旧应用可能导致数据丢失。
- 可切换中英文界面并跟随系统深浅主题。JSON 诊断报告按白名单生成，不含设备标识、地址、路径、配对码或原始输出；logcat 原文不自动脱敏，分享前需检查。

已通过自动化 Windows 构建、测试和完整解压后的启动检查。维护者此前报告过设备操作可用，但该记录不能证明所有真机场景；两台设备批量安装以及五种错误提示尚无真机验收记录。当前不支持 split APK、APKS、XAPK、投屏或自动重连，详情见[验证记录](VALIDATION.md)和[故障排查](TROUBLESHOOTING.md)。
