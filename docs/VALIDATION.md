# Validation record / 验证记录

## First-use error handling — 2026-09-23 (candidate)

On branch `codex/portfolio-first-use-20260923` from `a891bef`, nonzero ADB exits now retain actionable codes for setup, wireless discovery, pairing, connection and APK installation. Only explicit errors for a selected device map to `device_missing`; an unrelated `not found` remains an operation failure. Core tests cover these cases and preserve unauthorized, offline, timeout and output-limit priority. A widget test covers the setup route when ADB is unavailable.

Local checks used Dart 3.12.2 from the installed Flutter 3.44.2 SDK, **not** the required Flutter 3.35.7: formatting of the three changed Dart files and 10 dependency-free core smoke checks passed. A temporary Dart harness also passed 10 nonzero/priority scenarios and three device-missing boundary scenarios without starting ADB or using a device. Package resolution for Flutter tests was unavailable locally; exact-version analysis, core/widget tests and Windows packaging still require CI. Clean-machine and physical-device acceptance remain unchecked.

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
