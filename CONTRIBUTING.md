# Contributing

[中文贡献指南](#中文贡献指南) · [English](#contributing)

Use Flutter 3.35.7. Run `flutter pub get`, `dart format lib test`, `flutter analyze --fatal-infos`, and `flutter test` before submitting a change.

Keep changes focused on a user-visible problem. Add tests for changed process behavior, targeting, privacy or failure handling. Do not include real device logs, identifiers, APKs or credentials in tests or screenshots; use fixtures or demo mode.

UI text must be available in Chinese and English. Explain the problem, changed behavior and validation in pull requests. New dependencies or background device operations require a concrete reason.

## 中文贡献指南

- 使用 Flutter **3.35.7**。提交代码改动前运行 `flutter pub get`、`dart format lib test`、`flutter analyze --fatal-infos` 和 `flutter test`，并在 PR 中写明实际执行结果；纯文档改动可检查文档链接和格式，不必声称跑过应用测试。
- 将修改限定在明确的用户可见问题。若改变进程调用、目标设备选择、隐私处理或失败行为，补充能验证这些行为的测试。测试与截图使用固定样例或演示模式，不放入真实设备日志、设备标识、APK 或凭据。
- 界面文案同时提供中文和英文。新增或修改说明文档时，也给出实用的中文内容与明显的导航入口。PR 描述应说明问题、行为变化与验证范围。新增依赖或后台设备操作应给出具体理由。
- 本项目的实机验收与自动化 CI 是不同证据；请在[验证记录](docs/VALIDATION.md)中如实标注通过、失败和未执行项。代码提交说明使用中文。
