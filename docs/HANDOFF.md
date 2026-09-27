# Development handoff — 2026-09-14

> 这是 **2026-09-14 的历史交接快照**，不是当前发布状态。当前公开版本与验收范围请看[中文使用指南](USER-GUIDE.zh-CN.md)和[验证记录](VALIDATION.md)。[中文交接说明](#中文交接说明2026-09-14)

The source is published in this repository. PR #1 was merged; Windows builds and packaging on windows-2022 passed. Archive download, SHA-256 and all 18 extracted entries were checked. The old 2026-09-12 repository-access, upload and build blockers are resolved; do not rebuild the project from that old handoff.

Flutter 3.35.7 / Dart 3.9.2; locked dependencies, bilingual responsive desktop UI, system theme, isolated demo mode, bounded ADB child processes and privacy-whitelisted reports. Twenty-six tests, analysis, formatting and ten standalone smoke checks passed. Four actual Flutter test-renderer demo captures were reviewed. They are not Windows hardware screenshots.

## Current candidate

Packaging now invokes tool/test-windows-startup.ps1 against the actual portable ZIP. The script verifies the checksum, extracts into a new temporary directory, starts the real executable with a private generated settings profile and a deliberately absent ADB path, requires a visible window and ten responsive seconds, checks that engine/plugin/runtime modules load from the extracted bundle, and requests a normal zero-code exit. It writes a bounded JSON evidence report. Candidate 9d8a9ec68fe555daf646eea3c66bd9b2a622d86f passed CI 34866115172, including the actual Windows startup gate. The Windows log confirms checksum, visible window, ten responsive seconds, local DLL loading and normal exit. This was an execution check, not a newly reviewed screenshot or clean-machine/hardware acceptance.

No terminal/runtime is available in the current assistant environment. Changes are made through the connected GitHub tools and must be verified in CI. Preserve remote work; compare the latest main/PR head before any update. Never delete unrelated files or write into the user's private trading repository.

## Remaining acceptance

- A CI startup pass is not a clean Windows consumer machine test: the hosted runner includes developer tools and runtimes. Check the extracted bundle on a clean x64 Windows machine.
- Android USB authorization, wireless pairing/connection, APK install and screenshot/log exports still require real devices. The startup fixture deliberately prevents ADB access and cannot prove any of those operations.
- Profile and portfolio link to the development preview; Pages deployment passed. Live-site visual review remains outstanding.
- No stable release/tag has been published. The tag workflow creates a draft, not a public accepted release. Use RELEASING.md and VALIDATION.md for evidence and remaining gates.

## 中文交接说明（2026-09-14）

以下是原交接在**当时**记录的事实，不能当作 2026-09-27 的当前状态。源码已在本仓库公开，PR #1 已合并；`windows-2022` 上的 Windows 构建和打包通过。当时已核对归档下载、SHA-256 和全部 18 个解压条目；2026-09-12 的仓库访问、上传和构建阻碍已解除，无需按旧交接从头重建项目。

当时使用 Flutter 3.35.7 / Dart 3.9.2 和锁定依赖。应用有响应式中英文桌面界面、系统主题、隔离演示模式、受限 ADB 子进程及隐私字段白名单报告。26 个测试、分析、格式检查与十项独立冒烟检查通过；已审查四张真实 Flutter 测试渲染的演示截图，它们不是 Windows 硬件截图。

### 当时的候选与验证

打包流程会对便携 ZIP 运行 `tool/test-windows-startup.ps1`：核对校验和、解压到新临时目录、使用独立设置目录与故意不存在的 ADB 路径启动真实程序，要求出现窗口并保持十秒响应，确认引擎/插件/运行时模块从解压包加载，并正常以 0 退出，同时生成有界 JSON 证据。候选 `9d8a9ec68fe555daf646eea3c66bd9b2a622d86f` 的 CI `34866115172` 通过该 Windows 启动检查。它证明了该 CI 环境的启动，不是新增视觉审查、干净消费者电脑或 Android 真机验收。

当时交接称助手环境没有可用终端或运行时，需通过连接的 GitHub 工具修改并依赖 CI 验证。这仅记录当时环境。处理后续工作时应保留远端已有成果、先比较最新主分支和 PR 头，不删除无关文件，也不写入用户的私人交易仓库。

### 当时待完成的验收

- CI 启动通过不等于干净 Windows x64 消费者电脑验收；托管 runner 含开发工具和运行时，仍需在干净机器运行整个解压包。
- USB 授权、无线配对与连接、APK 安装、截图和日志导出仍需真实设备验证。启动夹具故意阻断 ADB，无法证明这些设备操作。
- 当时主页和作品集链接到开发预览，Pages 部署通过，但线上页面视觉检查未完成。
- 当时没有稳定版或公开可验收版本；标签流程的草稿不等于公开发布。**此项已是历史状态**：preview.3 现有公开发布页；稳定版的验收仍应依据[发布检查](RELEASING.md)及[验证记录](VALIDATION.md)。
