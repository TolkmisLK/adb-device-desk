# Validation record / 验证记录

[中文验证记录](#中文验证记录按事件日期) · [English historical record](#multi-device-apk-installation--2026-09-24-asiashanghai)

> 各节保留原事件日期和当时状态。当前下载入口以 [README](../README.md) 为准；早期“尚未公开”的记录是历史快照，不表示当前没有下载页。

## Batch-install retry / 批量安装失败项重试（2026-09-28）

Candidate `2cb3de47cbf822a811d3c0737d59161551a704bc` passed both jobs in [CI 36401754623](https://github.com/TolkmisLK/adb-device-desk/actions/runs/36401754623): formatting, static analysis, core checks, Flutter tests, Windows portable build and extracted-startup checks. New controlled widget tests cover explicit failed-target selection, cancellation without installation, preserving earlier successes after retry and aborting if a selected device goes offline before final confirmation. These use a fake ADB service and a temporary APK fixture; they do not install on physical devices. No local application, ADB or hardware tests were run for this change.

候选提交 `2cb3de47cbf822a811d3c0737d59161551a704bc` 的[上述 CI](https://github.com/TolkmisLK/adb-device-desk/actions/runs/36401754623)两项任务均通过，包含格式、静态分析、核心检查、Flutter 测试、Windows 便携包构建及完整解压后启动检查。新增组件测试验证了失败项须明确选择、取消不会安装、重试后保留原成功结果，以及最终确认前设备转为离线时不开始重试。测试使用伪 ADB 服务和临时 APK 文件，没有对真机安装。本次未运行本地应用、ADB 或硬件测试；新功能没有真机验收记录。

## Published preview / 已发布预览（2026-09-27）

The [v0.1.0-preview.3 release page](https://github.com/TolkmisLK/adb-device-desk/releases/tag/v0.1.0-preview.3) is public and points to `5f5f710`. Its release notes report automated Windows build, tests and extracted-startup checks. The repository records no physical two-device batch-installation acceptance or device validation of the five new failure-specific messages. Do not infer those from a public download or CI. This section records the published status, not a new local ADB or hardware test.

[v0.1.0-preview.3 发布页](https://github.com/TolkmisLK/adb-device-desk/releases/tag/v0.1.0-preview.3)已公开，指向提交 `5f5f710`。发布说明记录了自动化 Windows 构建、测试和解压后启动检查。仓库尚无两台真机批量安装或五类新增错误提示的真机验收记录；公开下载和 CI 通过都不能推出这些项目已通过。本节只核对公开状态，没有新增本地 ADB 或硬件测试。

## Multi-device APK installation — 2026-09-24 (Asia/Shanghai)

The existing single-device application was reported usable after the 2026-09-23 candidate. This report does not establish which physical-device cases passed. The new batch path selects ready devices explicitly, runs the existing targeted APK install sequentially with its three-minute per-device timeout, and records each result even when a preceding target fails. It does not change debugging modes or stop the shared ADB server.

CI on candidate `1ea36a2` passed both jobs in [run 35977379932](https://github.com/TolkmisLK/adb-device-desk/actions/runs/35977379932): formatting, static analysis, ten core smoke checks, six public-preview plan checks, 37 Flutter tests (one visual capture test skipped), Windows tests, both release-plan checks, portable ZIP build and extracted-window startup. These tests include the batch coordinator's failure continuation and serial execution, plus the explicit-selection dialog. Batch installation has no physical-device acceptance in this record; the two-device and failure-continuation checks in [RELEASING.md](RELEASING.md) remain open.

## First-use candidate — 2026-09-23 (Asia/Shanghai)

Candidate `9481e49437485986d9407ccc7089b660088218f9` on `codex/portfolio-first-use-20260923` builds on main `4ac255ca63e95dc3a2a2fb385d80cb4e4265ace5`. The local `bf9462b` commit has the same tree (`f900f11eb58b696e135ff6a763366f02bf26cb3d`). Nonzero ADB exits now retain setup, discovery, pairing, connection and installation guidance while explicit selected-device errors take priority. Independent review found a missed `connect error for write: device ... not found` form; the follow-up fix was reviewed without a further blocking finding.

- **PASS — automated:** [CI 35846921125](https://github.com/TolkmisLK/adb-device-desk/actions/runs/35846921125) passed `check` and `windows` on this candidate: Flutter 3.35.7 formatting, analysis, core smoke, Flutter tests, demo capture, Windows tests, preview-plan check, ZIP build and extracted-window startup. Artifact `10743767531` was checked for required components and its portable ZIP SHA-256 matched `a77a2ca5bfbdab952706d698a27996f526f875ba94fc1f900864963f2410de3d`.
- **PASS — partial physical use:** On a Windows 11 build 22631 development machine, the extracted candidate opened a real GUI with isolated app settings and official Platform-Tools 37.0.1. Missing ADB and an invalid executable path produced setup guidance; choosing `adb.exe` in the native picker and verifying it worked. One USB device was detected and queried. A saved PNG decoded at 1080×2340; log export produced 60,013 bytes across 546 physical lines (the “500” option is not an exact physical-line guarantee). The 481-byte diagnostic JSON reported `adb_available`, `server_responding` and `device_ready` as pass, with `port_not_checked` skipped because no network target was supplied; it contained no actual device serial, IP address or user path. Switching from Chinese to English retained the ADB path. The window closed on request and its process exited; a local exit code was not captured.
- **BLOCKED — installation:** The first APK attempt timed out after about three minutes. The UI showed the timeout and re-enabled operations; only that ADB client ended, and the existing server process remained. A subsequent package-manager query again found no test package. Installation success and the phone-side cause are unverified.
- **NOT RUN — remaining acceptance:** Two-device targeting, wireless pairing/connection, physical offline and unauthorized states, narrow-window dragging on the local machine, and a clean Windows machine were not verified. The candidate CI covered a narrow-window widget, but automated coverage does not replace these physical checks. No public release was published.

## Wireless discovery — 2026-09-18 (Asia/Shanghai)

PR #4 candidate `21099f40c5faceb2301ed9943ed9b975da9c68d3` passed both jobs in [CI 35283424371](https://github.com/TolkmisLK/adb-device-desk/actions/runs/35283424371): format, analysis, ten standalone smoke checks, Flutter tests, actual demo capture and Windows build/extracted-window startup. Discovery is explicit; untrusted pairing/connect advertisements stay separate and selecting an address does not send a pairing or connection command. See [WIRELESS-DISCOVERY.md](WIRELESS-DISCOVERY.md).

All four real Flutter demo-rendered captures from artifact `10523671854` were downloaded and reviewed; the wireless panel shows separate pairing and connection ports without overflow. Windows artifact `10523877157` passed local SHA-256 and all 18 ZIP entry checks. Its startup JSON records a visible, responsive window for ten seconds, bundle DLL verification and normal exit 0, with physical-device and clean-machine flags false. These are CI/demo results, not live mDNS or Android hardware acceptance. The local cached Flutter tool still crashes with SIGBUS before startup; no local Flutter suite success is claimed for this candidate.

## Unpublished Windows preview draft — 2026-09-16 (Asia/Shanghai)

[Draft preparation CI](https://github.com/TolkmisLK/adb-device-desk/actions/runs/35030564868) completed successfully from exact commit `47350457eb54e7fd2cdd7b6c13812f4ffc872691` after PR #3 and main CI passed. The dedicated release branch repeated the locked-dependency, format, analysis, core smoke, 26-test, Windows build and actual extracted-window startup gates. Its separate release job checked the ZIP checksum and matching startup JSON before creating the draft.

GitHub now contains `v0.1.0-preview.1` with both `draft=true` and `prerelease=true`, targeting that exact commit. Three attached assets were confirmed through the authenticated repository API: `adb-device-desk-0.1.0-windows-x64.zip` (11,957,594 bytes), its SHA-256 file and `windows-startup.json`. The draft is not a public download or a stable release. No new local archive extraction or visual review is claimed for this build.

Consumer clean-machine and physical Android acceptance remain pending. Do not rerun creation blindly or publish this draft as if those checks passed; inspect the existing draft and follow [RELEASING.md](RELEASING.md).

## Actual Windows startup acceptance — 2026-09-15 (Asia/Shanghai)

[PR #2 CI](https://github.com/TolkmisLK/adb-device-desk/actions/runs/34866115172), candidate `9d8a9ec68fe555daf646eea3c66bd9b2a622d86f`: Linux checks and Windows tests/build/package/startup all passed. The Windows suite again reports 26 passed and the opt-in screenshot test skipped.

The produced portable ZIP was checksum-verified and extracted into a fresh temporary directory on the Windows 2022 runner. The actual executable started with an isolated settings profile and a deliberately absent ADB path. It presented the expected visible native window (the runner shows it from Flutter's first-frame callback), remained responsive for ten seconds, loaded the Flutter engine/file-selector plugin/MSVC modules from the extracted bundle, and exited normally with code zero after a window-close request. The log explicitly records the successful gate; the ZIP artifact also contains windows-startup.json.

This closes the previous no-Windows-execution gap. It is not clean-consumer-machine acceptance: the hosted runner includes developer tooling. No Android device was accessed and no new screenshot was visually reviewed in this run. The JSON explicitly marks physicalDeviceTested and cleanMachineTested false. Local execution was unavailable; these results came from the actual Windows CI runner.

## Update: 2026-09-13

The repository is available and PR #1 is merged. Windows CI passed after pinning the runner to `windows-2022`, matching Flutter 3.35.7's Visual Studio support. Linux checks and all 26 Windows tests passed, and the portable ZIP plus SHA256 were generated and uploaded.

- [Candidate CI #2](https://github.com/TolkmisLK/adb-device-desk/actions/runs/34754363185): passed; candidate `f8f4203c984f3c6192b10e3b40ac2e801dc79156`.
- [Merged-main CI](https://github.com/TolkmisLK/adb-device-desk/actions/runs/34754760328): passed; main `69cd7fe0a2649218cb640dcaee63699995862fd6`.
- The initial `windows-latest` build failed because this Flutter version selected an unsupported Visual Studio generator. The pinned runner resolved it; no test gate was removed.
- GitHub Profile now links to the development preview. Portfolio integration is merged; [Pages quality and deployment](https://github.com/TolkmisLK/TolkmisLK.github.io/actions/runs/34755091034) both passed. A live visual inspection of the deployed website has not been completed.

Physical-device acceptance, clean-machine interactive launch and a public release remain pending. The earlier repository-access blocker below is historical and resolved.

### Artifact verification: 2026-09-14 (Asia/Shanghai)

Downloaded candidate CI artifact `10315984431` successfully using a fresh artifact reference. Extracted the outer archive and ran `sha256sum -c adb-device-desk-0.1.0-windows-x64.zip.sha256`: **OK**. The portable ZIP contains 18 entries including `adb_device_desk.exe`, Flutter engine and file-selector DLLs, ICU/application assets, three Visual C++ runtime DLLs, LICENSE and Windows quickstart. This supersedes the earlier HTTP 403 download attempt. Archive inspection is not Windows execution or physical-device acceptance.

## Checkpoint: 2026-09-12 (Asia/Shanghai)

Environment: Linux, Flutter source tag 3.35.7, Dart 3.9.2. No physical Android device or Windows build host was available.

| Check | Result | Evidence |
| --- | --- | --- |
| Locked dependency resolution | Passed | `flutter pub get --enforce-lockfile`; source archive includes `pubspec.lock` |
| Source formatting | Passed for lib/test/tool | `dart format --output=none --set-exit-if-changed lib test tool` |
| Static analysis | Passed including the standalone smoke script | `flutter analyze --no-pub --fatal-infos`: No issues found |
| Standalone core smoke tests | 10 passed | `dart tool/core_smoke.dart`, exit 0 |
| Full Flutter tests | 26 passed, 1 intentionally skipped | `flutter test --no-pub --coverage --reporter expanded`, exit 0; screenshot capture is opt-in |
| Actual Flutter UI capture | 1 passed separately | `CAPTURE_UI=1 flutter test --no-pub test/visual_review_test.dart --update-goldens`, exit 0 |
| Visual review | Completed | Devices, dark devices, wireless and diagnostics in `docs/screenshots/`; demo data only |
| Native host generation | Completed | Windows and Linux runner sources generated; existing Dart app preserved |
| Windows native build and ZIP | Not completed | Windows host/CI required |
| Physical-device acceptance | Not performed | No device available |
| GitHub publication | Not completed | Target repository request returned 404; no repository-creation action is available in the connected tools |
| Profile/portfolio integration | Pending | Wait for a real source/release URL; do not advertise an unavailable download |

The 10 smoke checks exercised endpoint validation, device-state parsing, false-success handling, pairing stdin, explicit device targeting, report privacy, real child-process argv/stdin, binary capture, timeout and output-limit behavior. They do not replace the full Flutter tests or hardware acceptance.

The full suite additionally covers settings recovery, whitelisted settings storage, demo isolation, bilingual navigation and a 640 px layout. It exposed an English metric-label overflow and an invalid button finder; both were fixed. Screenshot review found missing icon-font glyphs in the capture harness, which now loads the real Material icon font. Screenshots are actual Flutter test-renderer output, not Windows screenshots or hardware acceptance evidence. They intentionally display DEMO DATA.

## Tool initialization issue (resolved)

Flutter's default bot detection attempted a cloud-instance metadata request and was blocked. Inspection located it in the SDK's `base/bot_detector.dart`. Subsequent commands use `CI=true BOT=true` so that the documented short-circuit skips the metadata probe. No instance metadata is needed or authorized for this project.

Missing dependencies in a transient package cache also interrupted initialization. The SDK and app were resolved into a workspace `PUB_CACHE`, after which native-host generation, analysis and tests completed. Do not delete a live lock or start competing writes; verify previous processes have ended, then use `CI=true BOT=true`, `TAR_OPTIONS=--no-same-owner`, `--no-version-check`, and bounded command timeouts in this managed Linux environment.

## Reproduce

With Flutter 3.35.7 on PATH, from the project root:

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --no-pub --fatal-infos
dart tool/core_smoke.dart
flutter test --no-pub --coverage --reporter expanded
CAPTURE_UI=1 flutter test --no-pub test/visual_review_test.dart --update-goldens
```

The final command uses POSIX syntax. In PowerShell set `$env:CAPTURE_UI='1'` first. Captures are manual review artifacts, not cross-platform pixel baselines. Inspect every changed PNG before accepting it.

## Remaining acceptance gates

1. Launch the complete extracted bundle on a clean Windows x64 machine. Source upload, Windows CI build/packaging and archive/checksum inspection have passed.
2. Perform the physical-device checklist in [RELEASING.md](RELEASING.md), including USB authorization, wireless pairing/connection, installation, PNG and log export.
3. Only after those gates, publish an evidence-backed release. Profile/portfolio already link to the explicitly labeled development preview. The release workflow creates a draft with ZIP and SHA256, not an automatic public release.

This is a tested development preview, not an accepted public Windows release. An unpublished draft exists as recorded above; hardware and consumer-machine gates still apply.

The native application icon is generated from the project's USB artwork at 16–256 px. `python tool/build_icon.py` rebuilds it with the optional Pillow dependency; app builds use the checked-in ICO and do not require Python.

## 中文验证记录（按事件日期）

以下中文对照保留每次验证的对象、结果与未验证边界。CI、Flutter 演示截图、Windows 托管环境启动和 Android 真机分别是不同证据，不能相互代替。

### 2026-09-24：多设备 APK 安装

2026-09-23 候选版的单设备操作曾被报告可用，但该报告不足以确认哪些真机场景通过。新增批量流程要求显式选择已连接目标，对每台依次运行既有、明确指定序列号的 APK 安装，每台最多等待三分钟；前一台失败仍记录结果并继续下一台。它不改变调试模式，也不停止共享 ADB 服务。

候选 `1ea36a2` 的 [CI 35977379932](https://github.com/TolkmisLK/adb-device-desk/actions/runs/35977379932) 两个作业通过：格式、分析、十项核心冒烟、六项公开预览方案检查、37 个 Flutter 测试（一个视觉截图测试跳过）、Windows 测试、两项发布方案检查、便携 ZIP 构建和解压后窗口启动。测试包括批量失败后继续、顺序执行和显式勾选对话框。**该记录没有批量安装真机验收**；[发布检查](RELEASING.md)中的双设备和失败续行项目仍未勾选。

### 2026-09-23：首次使用候选

候选 `9481e49437485986d9407ccc7089b660088218f9` 位于 `codex/portfolio-first-use-20260923`，基于主分支 `4ac255ca63e95dc3a2a2fb385d80cb4e4265ace5`；本地 `bf9462b` 的树为 `f900f11eb58b696e135ff6a763366f02bf26cb3d`，与候选相同。非零 ADB 退出时保留设置、发现、配对、连接和安装指引；明确的所选设备错误优先。独立审查发现漏掉 `connect error for write: device ... not found` 形式，后续修复经过复核，未再发现阻断问题。

- **自动化通过：** [CI 35846921125](https://github.com/TolkmisLK/adb-device-desk/actions/runs/35846921125) 的 `check`、`windows` 通过，包含 Flutter 3.35.7 格式、分析、核心冒烟、Flutter/Windows 测试、演示截图、发布方案检查、ZIP 构建与解压启动。产物 `10743767531` 的必要组件经检查，便携 ZIP 的 SHA-256 为 `a77a2ca5bfbdab952706d698a27996f526f875ba94fc1f900864963f2410de3d`。
- **部分真机使用通过：** 一台 Windows 11 build 22631 开发电脑解压后打开真实 GUI，使用隔离设置和官方 Platform-Tools 37.0.1。缺失 ADB、错误路径出现设置提示；系统选择框选 `adb.exe` 并验证成功。发现并查询一台 USB 设备，保存 PNG 解码为 1080×2340；日志导出 60,013 字节、546 个物理行，因此“500”选项不保证恰好 500 行。481 字节 JSON 中 `adb_available`、`server_responding`、`device_ready` 为通过，未填目标所以 `port_not_checked` 跳过；没有真实设备序列号、IP 或用户路径。中英文切换保留 ADB 路径，窗口按请求关闭并退出，但未捕获本地退出码。
- **安装受阻：** 首次 APK 安装约三分钟后超时；界面显示超时并恢复可操作。本次 ADB 客户端结束，共享服务进程仍在。随后包管理器查询仍未找到测试包。安装成功与手机侧根因**未验证**。
- **未执行：** 双设备目标隔离、无线配对与连接、真机离线及待授权状态、本机窄窗口拖动和干净 Windows 电脑。当时候选 CI 有窄窗口 widget 测试，但不代替真机。该日期没有公开发布。

### 2026-09-18：无线发现

PR #4 候选 `21099f40c5faceb2301ed9943ed9b975da9c68d3` 的 [CI 35283424371](https://github.com/TolkmisLK/adb-device-desk/actions/runs/35283424371) 两项作业通过：格式、分析、十项独立冒烟、Flutter 测试、实际演示截图与 Windows 构建/解压启动。发现由用户明确触发；配对/连接广播分别处理，点选地址不会发命令，详见[无线发现说明](WIRELESS-DISCOVERY.md)。

下载并审查了产物 `10523671854` 中四张实际 Flutter 演示截图；无线页的两个端口没有溢出。Windows 产物 `10523877157` 通过本地 SHA-256 与 ZIP 全部 18 项检查。启动 JSON 记录窗口可见、十秒响应、包内 DLL 验证和正常退出 0，同时真机及干净机器标记为 false。这些是 CI/演示证据，**不是**真实 mDNS 网络或 Android 硬件验收。当时本地 Flutter 缓存工具在启动前 SIGBUS 崩溃，本地 Flutter 测试没有成功记录。

### 2026-09-16：未公开的 Windows 预览草稿

PR #3 和主分支 CI 通过后，精确提交 `47350457eb54e7fd2cdd7b6c13812f4ffc872691` 的[草稿准备 CI](https://github.com/TolkmisLK/adb-device-desk/actions/runs/35030564868)通过：锁定依赖、格式、分析、核心冒烟、26 个测试、Windows 构建和真实解压启动；独立发布作业核对 ZIP 校验和与启动 JSON 后创建草稿。

当时 GitHub 的 `v0.1.0-preview.1` 同时为 `draft=true`、`prerelease=true`，指向该精确提交；通过已认证 API 确认三个附件：11,957,594 字节 ZIP、SHA-256 文件、`windows-startup.json`。草稿不是公开下载或稳定版；当时没有新增本地归档解压或视觉审查。干净消费者电脑和 Android 真机验收仍待完成，不应把草稿当成已验收版本。当前公开 preview.3 与此旧草稿是不同事件。

### 2026-09-15：Windows 解压启动

[PR #2 CI 34866115172](https://github.com/TolkmisLK/adb-device-desk/actions/runs/34866115172) 的候选 `9d8a9ec68fe555daf646eea3c66bd9b2a622d86f` 通过 Linux 检查和 Windows 测试/构建/打包/启动；Windows 报告 26 个测试通过，一个可选截图测试跳过。便携 ZIP 在 Windows 2022 runner 上核对校验和并解压到新目录，程序用独立配置和故意不存在的 ADB 路径启动，出现可见原生窗口并响应十秒；Flutter 引擎、文件选择插件和 MSVC 模块从解压包加载，请求关窗后正常退出码 0。日志与 `windows-startup.json` 记录此结果。

这关闭了先前“未运行 Windows 可执行程序”的缺口，但托管 runner 自带开发工具，不等于干净消费者电脑；未访问 Android 设备，也未在该次运行中重新视觉审查截图。JSON 的 `physicalDeviceTested`、`cleanMachineTested` 均为 false。当时本地执行不可用，结果来自 Windows CI runner。

### 2026-09-13 至 09-14：仓库、CI 与归档

仓库可访问，PR #1 合并。将 runner 固定为 `windows-2022` 以适配 Flutter 3.35.7 支持的 Visual Studio 后，Windows CI 通过；Linux 检查与 26 个 Windows 测试通过，生成并上传便携 ZIP 与 SHA-256。[候选 CI](https://github.com/TolkmisLK/adb-device-desk/actions/runs/34754363185) 对应 `f8f4203c984f3c6192b10e3b40ac2e801dc79156`，[主分支 CI](https://github.com/TolkmisLK/adb-device-desk/actions/runs/34754760328) 对应 `69cd7fe0a2649218cb640dcaee63699995862fd6`。最初 `windows-latest` 的失败源于此 Flutter 版本选到不受支持的 Visual Studio 生成器；固定 runner 后通过，未删减测试门槛。当时主页已链接开发预览，作品集合并，Pages [质量与部署](https://github.com/TolkmisLK/TolkmisLK.github.io/actions/runs/34755091034)通过，但未完成线上视觉检查；真机、干净机器与公开发行当时仍待办。

09-14 下载 CI 产物 `10315984431`，解外层归档并运行 `sha256sum -c adb-device-desk-0.1.0-windows-x64.zip.sha256` 得到 **OK**。便携 ZIP 有 18 项，包括 `.exe`、Flutter 引擎及文件选择 DLL、ICU/应用资源、三项 Visual C++ 运行库 DLL、许可证和 Windows 快速入门。这取代较早的 HTTP 403 下载失败，但归档检查不等于 Windows 实际执行或真机验收。

### 2026-09-12：初始检查点

当时环境为 Linux、Flutter 源码标签 3.35.7、Dart 3.9.2，没有 Android 真机或 Windows 构建主机。锁定依赖解析、`lib/test/tool` 格式、静态分析、十项独立核心冒烟、完整 Flutter 测试（26 通过、1 项有意跳过）、单独启用的 Flutter UI 截图、演示截图视觉审查及 Windows/Linux runner 源码生成均通过。**当时未完成** Windows 原生构建、真机验收、GitHub 发布及主页/作品集集成；仓库请求返回 404 是那次检查的历史结果，后续已解除。原文表格保留每项命令与证据。

十项冒烟覆盖端点校验、设备状态解析、伪成功、配对码标准输入、明确设备目标、报告隐私、真实子进程参数/输入、二进制数据、超时和输出限额，但不能代替完整 Flutter 或硬件测试。完整测试还覆盖设置损坏恢复、白名单存储、演示隔离、中英文导航及 640 px 布局；发现并修复英文指标标签溢出和错误按钮查找。截图夹具缺失图标字体的问题也已修复，后来加载真实 Material 图标字体。`docs/screenshots/` 是 Flutter 测试渲染的 **DEMO DATA**，不是 Windows 真机截图。

### 当时的工具问题、复现与待办

Flutter 默认机器人检测尝试访问云实例元数据，被环境阻止；调查定位在 SDK 的 `base/bot_detector.dart`。当时以 `CI=true BOT=true` 跳过该探测。临时包缓存缺依赖也曾中断初始化；将 SDK 与应用解析到工作区 `PUB_CACHE` 后完成生成、分析及测试。该托管 Linux 环境重现时，需先确保旧进程已结束，不删除活跃锁，也不并发写同一缓存；再按需要使用 `CI=true BOT=true`、`TAR_OPTIONS=--no-same-owner`、`--no-version-check` 与有界超时。

原英文 `Reproduce` 节列出 Flutter 3.35.7 的锁定依赖、格式、分析、核心冒烟、覆盖率测试及 `CAPTURE_UI=1` 的手工截图命令。最后一条是 POSIX 语法；PowerShell 先设置 `$env:CAPTURE_UI='1'`。截图是人工审查产物，不是跨平台像素基线；接受前应查看每张变化的 PNG。

当时待办为：在干净 Windows x64 电脑启动完整解压包；按[发布检查](RELEASING.md)完成 USB 授权、无线配对/连接、安装、PNG/日志的真机验收；根据实际证据决定稳定版发布。早期“尚无公开下载”的句子是历史状态，不能用于否认后来的公开 preview.3。项目原生图标由 USB 美术图生成 16–256 px，`python tool/build_icon.py` 通过可选 Pillow 重建；普通应用构建使用已提交的 ICO，无需 Python。
