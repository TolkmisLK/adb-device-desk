# Changelog

[中文更新记录](#中文更新记录) · [English](#changelog)

## 0.1.0 — Preview series

- Device discovery, selection and state-aware actions.
- Android wireless pairing and connection as separate steps.
- Local ADB and optional target-port diagnostics with private-by-default reports.
- Single APK installation, PNG screenshots, device info and bounded logcat export.
- Chinese/English interface, system theme and an isolated demo mode.
- Automated core, subprocess and widget tests; Windows packaging workflow.
- Preview.3 candidate: show specific per-device guidance for five ADB package-install failures.

## 中文更新记录

### 0.1.0 预览版系列

- 发现并选择设备，按已连接、离线、待授权等状态限制可执行操作。
- 将 Android 无线配对与无线连接分成两个步骤，分别填写配对端口和连接端口。
- 检查本机 ADB 和可选的一个目标 TCP 端口，导出按隐私字段白名单生成的诊断报告。
- 支持对所选设备安装单个 APK、保存 PNG 截图、查看设备信息、导出受输出上限约束的 logcat。后续预览版增加明确勾选多台设备后依次安装同一 APK，并逐台显示结果；单台失败后继续处理后续设备。
- 提供中英文界面、系统深浅主题和与真实 ADB 操作隔离的演示模式。
- 核心逻辑、子进程和界面有自动化测试，并有 Windows 打包流程及解压后启动检查。
- preview.3：ADB 返回相应安装失败码时，逐台提示存储不足、签名不匹配、版本降级、Android 版本过低或 CPU 架构不匹配；其余安装失败保留通用提示。两台设备批量安装及这五类新提示仍待真机验收，见[验证记录](docs/VALIDATION.md)。
