# Development handoff — 2026-09-14

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
