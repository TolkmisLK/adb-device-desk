# Architecture

[中文架构说明](#中文架构说明) · [English](#architecture)

`DeskScreen` owns UI state and serializes user operations through one busy guard. All buttons that trigger ADB work are disabled while an operation is active. Navigation stays available. Refresh preserves selection only if the exact serial remains present; a failed refresh clears stale device state.

`DeviceService` defines the device boundary. `AdbService` builds fixed argument lists and validates responses. `DemoService` exposes labelled sample devices without executing ADB. File dialogs and filesystem writes live in the UI boundary, keeping core logic independently testable.

`ProcessCommandRunner` starts an executable without a shell, drains stdout/stderr concurrently, preserves binary data, limits combined output to 24 MiB, and terminates the client on timeout. The shared ADB server is not killed. Pairing codes travel via stdin and are not part of argv. Raw output is not retained in application logs.

`Diagnostics` checks ADB availability, server/device enumeration and an optional single TCP endpoint independently. A reachable port is reported separately from device authorization. Failed connectivity generates possible next checks, never an unsupported root-cause claim.

`DiagnosticReport` uses a schema-versioned field whitelist. It deliberately contains only timestamps, application version, demo flag, whether a target was supplied, device states, and diagnostic codes/statuses. Reports are not a raw command transcript. Device logcat exports are a separate, explicitly confirmed action.

`Settings` persists only the validated ADB executable path and language preference. On Windows this is `%APPDATA%/adb-device-desk/settings.json`. Missing or malformed settings fall back to defaults.

## Testing boundaries

- Unit tests: endpoint validation, device parsing, command selection, false-success responses and report privacy.
- Process integration tests: real Dart child process, binary capture, argument boundaries, stdin, timeout and output limit.
- TCP test: local ephemeral listening port, followed by closed-port verification.
- Widget tests: selection, disabled demo operations, diagnostics, resizing and language switching.
- Windows CI: analysis/tests plus real native compilation and packaging. Physical-device validation is a separate release gate.

## 中文架构说明

`DeskScreen` 管理界面状态，并用一个忙碌保护串行化用户发起的 ADB 操作。执行期间禁用会触发 ADB 的按钮，导航仍可用。刷新后仅当同一序列号仍在列表中才保留选择；刷新失败会清除过期设备状态。

`DeviceService` 是设备操作边界。`AdbService` 用固定参数列表构造命令并验证响应；`DemoService` 仅提供带「演示数据」标记的样例，不调用 ADB。文件选择和写入留在 UI 层，使核心逻辑能独立测试。

`ProcessCommandRunner` 不通过 shell 启动可执行文件，并发读取标准输出/错误，保留二进制数据，合并输出上限为 24 MiB。超时只终止本次 ADB 客户端，不停止共享 ADB 服务。配对码经标准输入传送，不放入命令参数；应用日志不保存原始输出。

`Diagnostics` 分别检查 ADB 是否可用、服务和设备枚举，以及可选的单一 TCP 端点。端口可达与设备已授权分开显示；连接失败只给可能的下一步检查，不武断确定根因。`DiagnosticReport` 使用带模式版本的字段白名单，仅含时间、应用版本、演示模式、是否填写目标、设备状态和诊断代码/状态；它不是原始命令记录。logcat 导出是单独且需确认的操作。

`Settings` 只保存已验证的 ADB 路径与语言偏好；Windows 默认位于 `%APPDATA%/adb-device-desk/settings.json`。设置缺失或损坏时回退到默认值。

### 测试边界

- 单元测试覆盖端点校验、设备解析、命令选择、伪成功响应与报告隐私。
- 进程集成测试通过真实 Dart 子进程检查参数边界、标准输入、二进制捕获、超时和输出上限。
- TCP 测试使用本机临时监听端口，并复查关闭后的端口。
- 界面测试覆盖选择、演示模式禁用设备操作、诊断、窗口尺寸和语言切换。
- Windows CI 覆盖分析/测试、原生编译与打包；真机验收是独立发布门槛。详见[验证记录](VALIDATION.md)。
