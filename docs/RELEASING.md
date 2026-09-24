# Windows release checklist

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

Tag the checked commit `v0.1.0`. The release workflow rebuilds, retests and creates a **draft** with ZIP/checksum attachments. After acceptance, publish that draft and update CHANGELOG/README with the real release state. If a candidate fails, fix it and validate again before publishing; do not relabel an untested build as stable.

## GitHub project setup

Repository: `TolkmisLK/adb-device-desk`, public, description:

`A desktop tool to connect Android devices, diagnose ADB problems, and export screenshots and logs.`

Suggested topics: `flutter`, `dart`, `android`, `adb`, `windows`, `desktop-app`, `developer-tools`, `diagnostics`.

Once the repository and CI are available, add the project to the existing Profile README and portfolio with its actual status. Until a release exists, describe it as a development preview and link to the source, not a non-existent download.
