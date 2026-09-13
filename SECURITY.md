# Security and data handling

This is a local, single-operator desktop utility. It runs an ADB executable chosen by the user with that user's operating-system permissions. Select only a trusted, official executable. The application does not sandbox ADB, install drivers or acquire administrator rights.

ADB has substantial authority over an authorized Android device. Use the tool only with devices you own or are authorized to administer. APK installation requires explicit confirmation. Wireless debugging must be enabled on the device; the app does not bypass authorization.

The app starts processes with argument arrays and `runInShell: false`, targets a selected serial explicitly, uses pairing stdin, applies timeouts and bounds captured output. There is no arbitrary shell-command UI. It does not stop the shared ADB server or automatically change debugging mode.

Only the ADB path and language preference are persisted. Pairing codes are cleared from the input when submitted and are not saved to configuration, command arguments or diagnostic reports. Dart strings cannot guarantee memory zeroization. The OS, selected ADB binary and device remain trusted parts of the system.

Diagnostic JSON excludes addresses, serials, file paths, models and raw process output by design. It still reveals the time, counts/states of devices and diagnostic findings. Exported logcat is raw and may contain sensitive data; review before sharing. No telemetry, automatic uploads, accounts or cloud API keys are involved.

For a suspected vulnerability, do not post pairing codes, device logs or personal details in a public issue. Use GitHub's private vulnerability reporting if enabled; otherwise open an issue requesting a private contact channel without disclosing exploit details or private data.
