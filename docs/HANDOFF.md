# Development handoff — 2026-09-12

## Completed locally

Flutter 3.35.7 / Dart 3.9.2 source with Windows and Linux native hosts, locked dependencies, bilingual responsive UI, system theme, isolated demo mode, validated ADB operations, bounded subprocess execution and privacy-whitelisted reports.

Latest checks: formatting unchanged; Flutter analysis clean; 26 tests passed with the opt-in capture test skipped; that capture test separately passed and its four actual demo renders were visually inspected. Standalone smoke suite previously passed 10 checks. See [VALIDATION.md](VALIDATION.md) for commands, boundaries and evidence. Windows icon generation also completed with six embedded sizes.

## External blockers, not completed work

- `TolkmisLK/adb-device-desk` returned 404 from the connected GitHub account on 2026-09-12. Repository-creation capability was unavailable. A 404 may mean absent or inaccessible: create the public repository if absent, or grant the connected account access if it already exists.
- No Windows build was run and no portable executable ZIP is included in this source archive. Windows CI must build and validate the real bundle.
- No physical Android device was available. USB, pairing, installation and export acceptance still require hardware.
- No GitHub commit, release, Profile update or portfolio link for this project has been published. Do not treat prepared workflow files as a successful CI run.

## Resume without rebuilding from scratch

1. Restore this source directory if needed and inspect newer remote work before uploading. Preserve unrelated changes. Do not use another project's repository as a substitute.
2. Make the target repository available. An initial README commit is helpful; upload the reviewed source and all native hosts, locked dependencies, workflows and docs, excluding local caches/build output.
3. Let `Check and build` run. Inspect logs and Windows artifact contents; fix failures on the actual candidate revision.
4. Follow [RELEASING.md](RELEASING.md). A tag creates a draft ZIP/SHA256 release; publish only after recorded acceptance.
5. Add accurate source/release links to the existing GitHub Profile and portfolio. Keep the project labelled development preview until its release gates have passed.

The source ZIP is a checkpoint, not a Windows installer. No private trading-system files or company/customer data are included.
