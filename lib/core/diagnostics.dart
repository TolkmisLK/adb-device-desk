import 'dart:io';
import 'adb_service.dart';
import 'models.dart';

typedef PortProbe = Future<bool> Function(Endpoint endpoint);

Future<bool> probePort(Endpoint endpoint) async {
  try {
    final socket = await Socket.connect(
      endpoint.host,
      endpoint.port,
      timeout: const Duration(seconds: 3),
    );
    socket.destroy();
    return true;
  } on SocketException {
    return false;
  }
}

class Diagnostics {
  Diagnostics(this.service, {PortProbe? probe}) : probe = probe ?? probePort;
  final DeviceService service;
  final PortProbe probe;

  Future<DiagnosticReport> run({Endpoint? endpoint, bool demo = false}) async {
    final checks = <DiagnosticCheck>[];
    var found = <AdbDevice>[];
    var available = false;
    try {
      await service.version();
      available = true;
      checks.add(const DiagnosticCheck('adb_available', CheckStatus.pass));
    } on DeskException catch (e) {
      checks.add(DiagnosticCheck(e.code, CheckStatus.fail));
    }
    if (available) {
      try {
        found = await service.devices();
        checks.add(
          const DiagnosticCheck('server_responding', CheckStatus.pass),
        );
        if (found.isEmpty) {
          checks.add(const DiagnosticCheck('no_devices', CheckStatus.warning));
        }
        for (final state in found.map((d) => d.state).toSet()) {
          checks.add(
            DiagnosticCheck(
              state == 'device' ? 'device_ready' : state,
              state == 'device' ? CheckStatus.pass : CheckStatus.warning,
            ),
          );
        }
      } on DeskException catch (e) {
        checks.add(DiagnosticCheck(e.code, CheckStatus.fail));
      }
    } else {
      checks.add(
        const DiagnosticCheck('server_not_checked', CheckStatus.skipped),
      );
    }
    if (endpoint != null) {
      final reachable = await probe(endpoint);
      checks.add(
        DiagnosticCheck(
          reachable ? 'port_reachable' : 'port_unreachable',
          reachable ? CheckStatus.pass : CheckStatus.fail,
        ),
      );
      // An open TCP port does not establish the service identity or ADB auth.
      checks.add(
        const DiagnosticCheck('port_is_not_authorization', CheckStatus.warning),
      );
    } else {
      checks.add(
        const DiagnosticCheck('port_not_checked', CheckStatus.skipped),
      );
    }
    return DiagnosticReport(
      checks: checks,
      states: found.map((d) => d.state).toList(),
      targetSupplied: endpoint != null,
      demo: demo,
    );
  }
}
