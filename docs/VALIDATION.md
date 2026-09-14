# Validation record / 验证记录

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

This is a tested source preview, not an accepted Windows release. No release exists at this checkpoint.

The native application icon is generated from the project's USB artwork at 16–256 px. `python tool/build_icon.py` rebuilds it with the optional Pillow dependency; app builds use the checked-in ICO and do not require Python.
