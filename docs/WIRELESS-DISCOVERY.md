# Wireless discovery

On the Wireless page, select **Refresh discovery** to query `adb mdns services`. The app separates `_adb-tls-pairing._tcp` from `_adb-tls-connect._tcp` and displays validated host/port pairs. Choosing **Use address** fills only that type's input; it does not issue a pairing or connection command. Pairing still requires the six-digit code and the explicit Pair action. ADB itself may independently reconnect to previously authorized devices according to its own configuration.

Compare the address with the phone's Wireless debugging screen. Service names and addresses are untrusted discovery data, not proof of device identity. An empty list can result from disabled wireless debugging, network isolation or unsupported discovery; manual entry remains available. Legacy `_adb._tcp` services are not treated as modern TLS pairing/connect entries.

The parser ignores malformed rows/endpoints, deduplicates each type/address pair and bounds results to 100 from at most 500 lines. IPv4, bracketed IPv6 and valid hostnames use the existing endpoint validator. Unsupported output is not reported as a successful empty discovery. Results remain in memory, reset when changing ADB executable, and are excluded from saved settings and diagnostic reports. Demo mode uses documentation-only addresses and never invokes ADB.

Validation: local formatting and ten real-process/core smoke checks passed. Local Flutter test startup currently crashes while reading its cached tool snapshot (SIGBUS), before tests execute. New parser/command/widget regressions and actual demo capture are submitted to CI; no discovery with a physical Android device or real multicast network is claimed.
