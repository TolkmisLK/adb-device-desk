# Security and data handling

[中文安全与数据处理](#中文安全与数据处理) · [English](#security-and-data-handling)

This is a local, single-operator desktop utility. It runs an ADB executable chosen by the user with that user's operating-system permissions. Select only a trusted, official executable. The application does not sandbox ADB, install drivers or acquire administrator rights.

ADB has substantial authority over an authorized Android device. Use the tool only with devices you own or are authorized to administer. APK installation requires explicit confirmation. Wireless debugging must be enabled on the device; the app does not bypass authorization.

The app starts processes with argument arrays and `runInShell: false`, targets a selected serial explicitly, uses pairing stdin, applies timeouts and bounds captured output. There is no arbitrary shell-command UI. It does not stop the shared ADB server or automatically change debugging mode.

Only the ADB path and language preference are persisted. Pairing codes are cleared from the input when submitted and are not saved to configuration, command arguments or diagnostic reports. Dart strings cannot guarantee memory zeroization. The OS, selected ADB binary and device remain trusted parts of the system.

Diagnostic JSON excludes addresses, serials, file paths, models and raw process output by design. It still reveals the time, counts/states of devices and diagnostic findings. Exported logcat is raw and may contain sensitive data; review before sharing. No telemetry, automatic uploads, accounts or cloud API keys are involved.

For a suspected vulnerability, do not post pairing codes, device logs or personal details in a public issue. Use GitHub's private vulnerability reporting if enabled; otherwise open an issue requesting a private contact channel without disclosing exploit details or private data.

## 中文安全与数据处理

机伴是单人本机桌面工具，以当前操作系统用户权限运行用户选择的 ADB 可执行文件。只选择可信、官方的 `adb.exe`；应用不会隔离 ADB、安装驱动或申请管理员权限。ADB 对已经授权的 Android 设备有较高操作权限，请只操作自己拥有或获授权管理的设备。安装 APK 需要明确确认；无线调试须先由设备端启用，应用不会绕过授权。

应用以参数数组启动进程，`runInShell: false`，单台设备命令明确指定序列号；配对码经标准输入发送，命令有超时，捕获输出有限额。界面没有任意 shell 命令入口，不会停止共享 ADB 服务或自动改变调试模式。系统、所选 ADB 程序和设备仍是受信任边界；Dart 字符串无法保证内存清零。

持久化设置只有已验证的 ADB 路径和语言偏好。提交配对码后，输入框会清空；配对码不存入设置、命令参数或诊断报告。诊断 JSON 通过字段白名单排除地址、序列号、文件路径、设备型号及原始进程输出，但仍会显示时间、设备数量与状态以及诊断结果。导出的 logcat 是**原始日志**，可能有敏感数据；分享前必须自行审查。应用没有遥测、自动上传、账户或云端 API 密钥。

怀疑存在漏洞时，不要在公开 Issue 中贴配对码、设备日志或个人资料。如果 GitHub 私密漏洞报告可用，请使用它；否则只公开请求私下联系渠道，不披露漏洞细节或私密数据。一般操作步骤见[中文使用指南](docs/USER-GUIDE.zh-CN.md)。
