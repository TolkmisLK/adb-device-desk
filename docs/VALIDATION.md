# Validation record / 验证记录

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

1. Make `TolkmisLK/adb-device-desk` available to the connected GitHub account. If absent, create that public repository; if it already exists, grant access. Do not paste credentials into chat.
2. Upload the source, run Windows CI, inspect its actual result and ZIP contents, and launch the complete extracted bundle on a clean Windows x64 machine. The packaging script has not yet been executed on Windows.
3. Perform the physical-device checklist in [RELEASING.md](RELEASING.md), including USB authorization, wireless pairing/connection, installation, PNG and log export.
4. Only after those gates, publish an evidence-backed release and connect the Profile/portfolio. The workflow creates a draft with ZIP and SHA256, not an automatic public release.

This is a tested source preview, not an accepted Windows release. No release exists at this checkpoint.

The native application icon is generated from the project's USB artwork at 16–256 px. `python tool/build_icon.py` rebuilds it with the optional Pillow dependency; app builds use the checked-in ICO and do not require Python.
