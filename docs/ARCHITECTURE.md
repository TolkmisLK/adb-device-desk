# Architecture

`DeskScreen` owns UI state and serializes user operations through one busy guard. All buttons that trigger ADB work are disabled while an operation is active. Navigation stays available. Refresh preserves selection only if the exact serial remains present; a failed refresh clears stale device state.

`DeviceService` defines the device boundary. `AdbService` builds fixed argument lists and validates responses. `DemoService` exposes labelled sample devices without executing ADB. File dialogs and filesystem writes live in the UI boundary, keeping core logic independently testable.

`ProcessCommandRunner` starts an executable without a shell, drains stdout/stderr concurrently, preserves binary data, limits combined output to 24 MiB, and terminates the client on timeout. The shared ADB server is not killed. Pairing codes travel via stdin and are not part of argv. Raw output is not retained in application logs.

`Diagnostics` checks ADB availability, server/device enumeration and an optional single TCP endpoint independently. A reachable port is reported separately from device authorization. Failed connectivity generates possible next checks, never an unsupported root-cause claim.

`DiagnosticReport` uses a schema-versioned field whitelist. It deliberately contains only timestamps, application version, demo flag, whether a target was supplied, device states, and diagnostic codes/statuses. Reports are not a raw command transcript. Device logcat exports are a separate, explicitly confirmed action.

`Settings` persists only the validated ADB executable path and language preference. On Windows this is `%APPDATA%/adb-device-desk/settings.json`. Missing or malformed settings fall back to defaults.

## Testing boundaries

- Unit tests: endpoint validation, device parsing, command selection, false-success responses and report privacy.
- Process integration tests: real Dart child process, binary capture, argument boundaries, stdin, timeout and output limit.
- TCP test: local ephemeral listening port, followed by closed-port verification.
- Widget tests: selection, disabled demo operations, diagnostics, resizing and language switching.
- Windows CI: analysis/tests plus real native compilation and packaging. Physical-device validation is a separate release gate.
