# Windows release checklist

[中文发布检查](#中文发布检查) · [English](#windows-release-checklist)

> The preview.3 instructions below describe the candidate process at the time they were written. [v0.1.0-preview.3 is already public](https://github.com/TolkmisLK/adb-device-desk/releases/tag/v0.1.0-preview.3); do not recreate its tag or replace its assets. / 下文 preview.3 的候选步骤是当时的历史流程；该预览版现已公开，勿重复创建标签或替换附件。

## Automated gates

1. Update version in pubspec, report metadata, build script and documentation together.
2. Commit `pubspec.lock`; enforce it in CI.
3. Pass formatting, static analysis, core/process/widget tests on the exact candidate commit.
4. Build on a Windows x64 runner using `tool/build-windows.ps1`.
5. Check that the ZIP contains executable, Flutter/plugin DLLs, data, MSVC runtime files, license and quick start.
6. Download the artifact and verify the SHA-256 file before physical acceptance.

## Physical acceptance — record facts, do not pre-check

- [ ] Windows app starts on a clean machine without Flutter installed.
- [ ] Missing ADB leads to setup instructions; selecting official adb.exe works.
- [ ] USB authorized, unauthorized, offline and unplugged states behave correctly.
- [ ] Android 11+ pairing and connecting work using separate ports.
- [ ] Invalid/expired code and wrong port yield useful errors, no false success.
- [ ] Two connected devices: installation/screenshot/logs target only the selected one.
- [ ] Batch installation: explicitly check two ready devices, verify one APK installs on each and each result is shown; a failing or timed-out device does not stop the next target.
- [ ] Install a test APK; PNG opens normally; logcat exports after confirmation.
- [ ] Disconnect the selected TCP device without disconnecting another device.
- [ ] Diagnostic JSON contains no real identifiers, IPs, paths, codes or raw output.
- [ ] App remains responsive when a target is unreachable.

Record Windows version, Android versions, Platform-Tools version and outcomes in VALIDATION.md without device serials or private logs. Some desktop integration issues can only be resolved with a Windows runner or hardware; unit tests do not replace these checks.

## Publish

An authorized maintainer can prepare an **unpublished prerelease draft** without publishing a stable tag: create a branch such as `release/draft-v0.1.0-preview.1` from the exact reviewed commit. The `Prepare unpublished Windows preview` workflow repeats formatting, analysis, core smoke, Flutter tests, Windows packaging and actual ZIP startup. A separate contents-write job rechecks SHA-256 and creates only a draft prerelease targeting the immutable candidate SHA, with ZIP, checksum and startup JSON. It refuses an existing release instead of replacing it, and verifies draft/prerelease/target state after creation. Build jobs have contents-read permissions and no persistent checkout credentials. Branch creation is a deliberate release preparation action, not an ordinary feature-branch side effect. Source changes to this workflow do not by themselves prove draft creation succeeded.

`tool/test-preview-plan.ps1` checks valid naming, version equality and an exact commit without making GitHub writes. The preview tag suffix identifies the release candidate; the app and ZIP retain the matching base pubspec version. CI and draft assets remain evidence for later physical checks, not public stable publication.

For a public preview, merge the reviewed candidate, then tag that exact main commit with the next unused `v<pubspec version>-preview.<number>` tag. For this change, use `v0.1.0-preview.3`; the published `v0.1.0-preview.2` assets and the older unpublished draft must remain untouched. The preview suffix does not change the base app/ZIP version `0.1.0`, so `pubspec.yaml` and the build script do not need a version bump for this candidate. The tag-triggered `Publish Windows preview` workflow repeats locked dependency resolution, formatting, static analysis, smoke and Flutter tests, Windows packaging, extracted startup, checksum and startup-report checks. Only after these pass does a separate contents-write job publish a prerelease with the ZIP, SHA-256 file and startup JSON. It rejects an existing release with the same tag. Verify the public release assets and update the project status with its actual URL.

The maintainer previously reported usable ADB device operations. Two-device batch installation and the specific failure messages added for preview.3 have automated evidence only; the corresponding physical checks above remain open. A stable `v0.1.0` release is a later decision after the remaining acceptance gates. If any candidate fails, fix and validate it before tagging another candidate.

## GitHub project setup

Repository: `TolkmisLK/adb-device-desk`, public, description:

`A desktop tool to connect Android devices, diagnose ADB problems, and export screenshots and logs.`

Suggested topics: `flutter`, `dart`, `android`, `adb`, `windows`, `desktop-app`, `developer-tools`, `diagnostics`.

Once the repository and CI are available, add the project to the existing Profile README and portfolio with its actual status. Until a release exists, describe it as a development preview and link to the source, not a non-existent download.

## 中文发布检查

当前可下载版本是 [v0.1.0-preview.3 公开预览版](https://github.com/TolkmisLK/adb-device-desk/releases/tag/v0.1.0-preview.3)。本节是维护者发布核查清单；不能因已有预览版就把尚未完成的真机项目勾选为通过。对未来候选，从其**确切提交**重新验证。

### 自动化门槛

1. 如果基础版本确实变化，应同步更新 `pubspec`、报告元数据、构建脚本和文档，并提交 `pubspec.lock`，让 CI 强制按锁定依赖解析。预览标签后缀不改变基础版本 `0.1.0`。
2. 对确切候选提交运行格式检查、静态分析、核心/进程/界面测试；在 Windows x64 runner 用 `tool/build-windows.ps1` 构建。
3. 确认 ZIP 中有可执行文件、Flutter/插件 DLL、`data`、MSVC 运行库、许可证和快速入门说明；下载产物并用随附 SHA-256 文件核对后，才进行物理设备验收。

### 物理验收：按实际结果记录，不预先勾选

- [ ] 在未装 Flutter 的干净 Windows x64 电脑上完整解压并启动应用。
- [ ] 缺少 ADB 时有设置指引，能选择并验证官方 `adb.exe`。
- [ ] USB 已授权、待授权、离线和拔线后的状态及限制都正确。
- [ ] Android 11+ 分别用配对端口与连接端口成功配对和连接；错误/过期码、错误端口给出有用提示且不误报成功。
- [ ] 两台设备时，单台安装、截图和日志只面向当前选中的设备。
- [ ] 批量安装时明确勾选两台已连接设备，同一 APK 在两台分别安装并显示结果；一台失败或超时不阻断下一台。
- [ ] 安装测试 APK、确认 PNG 可打开，并在确认后导出日志；按实际 ADB 返回核验五种新增安装错误提示。
- [ ] 断开当前 TCP 设备时不影响其他设备；诊断 JSON 不含真实设备标识、IP、路径、配对码或原始输出；不可达目标不使界面卡死。

把 Windows 版本、Android 版本、Platform-Tools 版本和结果写到[验证记录](VALIDATION.md)，不要收录真实序列号或私密日志。单元测试与 CI 不能替代干净机器及真机检查。

### 发布流程与历史说明

维护者可以从已审查的精确提交开 `release/draft-v0.1.0-preview.N` 分支，运行 `Prepare unpublished Windows preview`：重复锁定依赖、格式、分析、冒烟/Flutter 测试、Windows 打包及真实解压启动。仅独立的写入作业核对校验和与启动报告后创建**未公开的预发布草稿**，目标绑定不可变候选 SHA，附件为 ZIP、SHA-256 和启动 JSON；已有同名发布时拒绝覆盖。构建作业只有读权限，不保留 checkout 凭据。`tool/test-preview-plan.ps1` 只验证命名、版本和提交，不写 GitHub。

公开预览版的流程是：合并已审查候选，再用下一个未使用的 `v<pubspec version>-preview.<number>` 标签指向那个主分支提交。标签触发的 `Publish Windows preview` 再跑依赖解析、检查、测试、打包、解压启动、校验和和报告检查，之后由独立写入作业发布带三种附件的预发布版；同名发布已存在时拒绝替换。**原英文所说“本次使用 preview.3”是发布前的历史安排；preview.3 目前已经公开，不应再打同名标签或重新上传二进制。** `v0.1.0` 稳定版仍须以后续真实验收决定。

本仓库为 `TolkmisLK/adb-device-desk`，公开简介是 “A desktop tool to connect Android devices, diagnose ADB problems, and export screenshots and logs.” 推荐主题包括 `flutter`、`dart`、`android`、`adb`、`windows`、`desktop-app`、`developer-tools`、`diagnostics`。主页与作品集应写实际状态并链接真实公开入口；原文中“尚无公开发行版”的句子属于写作时的历史条件。用户入口见[中文使用指南](USER-GUIDE.zh-CN.md)。
