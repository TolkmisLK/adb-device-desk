// Offline core verification without starting Flutter or touching any device.
// Run: dart tool/core_smoke.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:adb_device_desk/core/adb_service.dart';
import 'package:adb_device_desk/core/command_runner.dart';
import 'package:adb_device_desk/core/diagnostics.dart';
import 'package:adb_device_desk/core/models.dart';

void require(bool condition, String label) {
  if (!condition) throw StateError(label);
}

Future<void> rejects(Future<void> Function() action, String code) async {
  try {
    await action();
  } on DeskException catch (error) {
    require(error.code == code, 'Expected $code; got ${error.code}');
    return;
  }
  throw StateError('Expected $code');
}

class FixtureRunner implements CommandRunner {
  FixtureRunner(this.response);
  final String Function(List<String> args) response;
  List<String> args = [];
  String? secret;
  @override
  Future<CommandOutput> run(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 15),
    int maxBytes = 24 * 1024 * 1024,
    String? input,
  }) async {
    args = arguments;
    secret = input;
    return CommandOutput(
      0,
      Uint8List.fromList(utf8.encode(response(arguments))),
      Uint8List(0),
    );
  }
}

Future<void> main() async {
  var passed = 0;
  Future<void> check(String name, Future<void> Function() body) async {
    await body();
    passed++;
    stdout.writeln('PASS $name');
  }

  await check('endpoint validation', () async {
    for (final endpoint in [
      '192.168.1.20:5555',
      'android.local:37121',
      '[2001:db8::1]:65535',
    ]) {
      require(Endpoint.parse(endpoint).toString() == endpoint, endpoint);
    }
    for (final bad in [
      '--help',
      'host',
      'http://host:5555',
      'host:0',
      'host:65536',
      'host:22;whoami',
      '999.1.1.1:5555',
      '1.2.3:5555',
      '-bad:5555',
      '[:::]:5555',
    ]) {
      await rejects(() async {
        Endpoint.parse(bad);
      }, 'invalid_endpoint');
    }
  });
  await check('device parsing and authorization states', () async {
    final devices = AdbDevice.parse(
      'List of devices attached\nUSB1 device model:Pixel_8\nUSB2 unauthorized\nUSB3 offline\n',
    );
    require(
      devices.length == 3 && devices.first.title == 'Pixel 8',
      'device list',
    );
    require(
      devices.where((d) => d.ready).length == 1,
      'authorization boundary',
    );
  });
  await check('zero-exit connect failure is not success', () async {
    final service = AdbService(
      runner: FixtureRunner((_) => 'failed to connect'),
    );
    await rejects(
      () => service.connect(const Endpoint('host', 5555)),
      'connect_failed',
    );
  });
  await check('pair code uses stdin only', () async {
    final runner = FixtureRunner((_) => 'Successfully paired to host:40000');
    await AdbService(
      runner: runner,
    ).pair(const Endpoint('host', 40000), '123456');
    require(
      runner.args.join('|') == 'pair|host:40000' && runner.secret == '123456\n',
      'pair secret',
    );
  });
  await check('device commands are explicitly targeted', () async {
    final runner = FixtureRunner((_) => 'log fixture');
    await AdbService(runner: runner).logs('USB1');
    require(
      runner.args.join('|') == '-s|USB1|logcat|-d|-t|500|-v|threadtime',
      'target',
    );
  });
  await check('report excludes private identifiers', () async {
    final runner = FixtureRunner(
      (args) => args.first == 'version'
          ? 'Android Debug Bridge version 1.0.41\nInstalled as /private/path/adb'
          : 'List of devices attached\nPRIVATE_SERIAL unauthorized model:SecretPhone\n',
    );
    final report = await Diagnostics(
      AdbService(runner: runner),
      probe: (_) async => true,
    ).run(endpoint: const Endpoint('192.168.99.99', 45678));
    final json = jsonEncode(report.toJson());
    for (final secret in [
      'PRIVATE_SERIAL',
      'SecretPhone',
      '192.168.99.99',
      '45678',
      '/private/path',
    ]) {
      require(!json.contains(secret), 'private field leaked');
    }
    require(
      report.checks.any((c) => c.code == 'port_is_not_authorization'),
      'TCP caveat',
    );
  });
  final fixture = File('test/fixtures/process_fixture.dart').absolute.path;
  const runner = ProcessCommandRunner();
  await check('real subprocess argv and stdin', () async {
    final result = await runner.run(Platform.resolvedExecutable, [
      fixture,
      'echo',
      'file with spaces.apk',
      'x;echo INJECTED',
    ], input: '123456\n');
    final value = jsonDecode(result.text) as Map<String, dynamic>;
    require(
      jsonEncode(value['args']) ==
          jsonEncode(['file with spaces.apk', 'x;echo INJECTED']),
      'argv',
    );
    require(value['input'] == '123456\n', 'stdin');
  });
  await check('real binary capture', () async {
    final result = await runner.run(Platform.resolvedExecutable, [
      fixture,
      'binary',
    ]);
    require(result.stdout.join(',') == '0,128,255,13,10', 'binary bytes');
    require(result.errorText == 'diagnostic', 'separate stderr');
  });
  await check('real subprocess timeout', () async {
    await rejects(() async {
      await runner.run(Platform.resolvedExecutable, [
        fixture,
        'wait',
      ], timeout: const Duration(milliseconds: 800));
    }, 'command_timeout');
  });
  await check('real output limit', () async {
    await rejects(() async {
      await runner.run(Platform.resolvedExecutable, [
        fixture,
        'large',
      ], maxBytes: 1024);
    }, 'output_limit');
  });
  stdout.writeln(
    '$passed core smoke checks passed. No physical device was accessed.',
  );
}
