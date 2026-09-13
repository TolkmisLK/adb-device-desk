import 'dart:io';

class DeskException implements Exception {
  const DeskException(this.code);
  final String code;
  @override
  String toString() => code;
}

class Endpoint {
  const Endpoint(this.host, this.port);
  final String host;
  final int port;

  factory Endpoint.parse(String input) {
    final value = input.trim();
    final match = RegExp(
      r'^(?:\[([0-9a-fA-F:]+)\]|([a-zA-Z0-9.-]+)):(\d{1,5})$',
    ).firstMatch(value);
    if (match == null) throw const DeskException('invalid_endpoint');
    final host = match.group(1) ?? match.group(2)!;
    final port = int.parse(match.group(3)!);
    if (port < 1 || port > 65535) {
      throw const DeskException('invalid_endpoint');
    }
    if (host.contains(':')) {
      if (InternetAddress.tryParse(host)?.type != InternetAddressType.IPv6) {
        throw const DeskException('invalid_endpoint');
      }
    } else if (RegExp(r'^[0-9.]+$').hasMatch(host)) {
      if (InternetAddress.tryParse(host)?.type != InternetAddressType.IPv4) {
        throw const DeskException('invalid_endpoint');
      }
    } else if (host.length > 253 ||
        host
            .split('.')
            .any(
              (part) => !RegExp(
                r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$',
              ).hasMatch(part),
            )) {
      throw const DeskException('invalid_endpoint');
    }
    return Endpoint(host, port);
  }

  @override
  String toString() => host.contains(':') ? '[$host]:$port' : '$host:$port';
}

class AdbDevice {
  const AdbDevice(this.serial, this.state, {this.model = ''});
  final String serial;
  final String state;
  final String model;
  bool get ready => state == 'device';
  String get title => model.isEmpty ? serial : model.replaceAll('_', ' ');

  static List<AdbDevice> parse(String output) {
    final devices = <AdbDevice>[];
    for (final raw in output.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty ||
          line.startsWith('List of devices') ||
          line.startsWith('*') ||
          line.startsWith('adb:')) {
        continue;
      }
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final state = line.contains('no permissions')
          ? 'no_permissions'
          : parts[1];
      if (!{
        'device',
        'offline',
        'unauthorized',
        'no_permissions',
        'recovery',
        'sideload',
        'bootloader',
        'rescue',
        'host',
      }.contains(state)) {
        continue;
      }
      final model =
          RegExp(r'(?:^|\s)model:(\S+)').firstMatch(line)?.group(1) ?? '';
      devices.add(AdbDevice(parts[0], state, model: model));
    }
    return devices;
  }
}

enum CheckStatus { pass, warning, fail, skipped }

class DiagnosticCheck {
  const DiagnosticCheck(this.code, this.status);
  final String code;
  final CheckStatus status;
  Map<String, String> toJson() => {'code': code, 'status': status.name};
}

class DiagnosticReport {
  DiagnosticReport({
    required this.checks,
    required this.states,
    required this.targetSupplied,
    this.demo = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();
  final List<DiagnosticCheck> checks;
  final List<String> states;
  final bool targetSupplied;
  final bool demo;
  final DateTime createdAt;

  // Deliberately whitelist fields: no serials, addresses, file paths, command
  // output, pairing codes, application names, or device logs enter reports.
  Map<String, Object> toJson() => {
    'schemaVersion': 1,
    'applicationVersion': '0.1.0',
    'createdAt': createdAt.toIso8601String(),
    'demo': demo,
    'targetSupplied': targetSupplied,
    'deviceStates': states,
    'checks': checks.map((check) => check.toJson()).toList(),
  };
}
