import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:adb_device_desk/core/adb_service.dart';
import 'package:adb_device_desk/core/command_runner.dart';
import 'package:adb_device_desk/core/diagnostics.dart';
import 'package:adb_device_desk/core/models.dart';

Matcher code(String value) =>
    isA<DeskException>().having((e) => e.code, 'code', value);

class StubRunner implements CommandRunner {
  StubRunner(this.handle);
  final CommandOutput Function(List<String> args, String? input) handle;
  List<String>? lastArgs;
  String? lastInput;
  @override
  Future<CommandOutput> run(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 15),
    int maxBytes = 24 * 1024 * 1024,
    String? input,
  }) async {
    lastArgs = arguments;
    lastInput = input;
    return handle(arguments, input);
  }
}

CommandOutput output(String text, {int exit = 0, String error = ''}) =>
    CommandOutput(
      exit,
      Uint8List.fromList(utf8.encode(text)),
      Uint8List.fromList(utf8.encode(error)),
    );

void main() {
  test(
    'wireless discovery separates ports, deduplicates and rejects malformed services',
    () {
      final services = WirelessService.parse('''List of discovered mdns services
phone _adb-tls-pairing._tcp 192.168.1.20:40123
phone _adb-tls-connect._tcp. 192.168.1.20:37121
alias _adb-tls-connect._tcp 192.168.1.20:37121
ipv6 _adb-tls-connect._tcp [2001:db8::1]:45678
legacy _adb._tcp 192.168.1.20:5555
bad _adb-tls-connect._tcp host:0
bad _adb-tls-pairing._tcp --help
bad _adb-tls-connect._tcp 192.168.999.1:5555
extra _adb-tls-connect._tcp host:5555 injected
''');
      expect(services.length, 3);
      expect(services.map((s) => s.pairing), [true, false, false]);
      expect(services.map((s) => s.endpoint.toString()), [
        '192.168.1.20:40123',
        '192.168.1.20:37121',
        '[2001:db8::1]:45678',
      ]);
      expect(
        WirelessService.parse(
          List.generate(
            600,
            (i) => 'name _adb-tls-connect._tcp host:${i + 1}',
          ).join('\n'),
        ).length,
        100,
      );
    },
  );
  test(
    'wireless discovery uses only the read-only services command and requires its header',
    () async {
      final runner = StubRunner(
        (_, _) => output(
          'List of discovered mdns services\nphone _adb-tls-pairing._tcp host:40123\n',
        ),
      );
      final found = await AdbService(runner: runner).discoverWireless();
      expect(runner.lastArgs, ['mdns', 'services']);
      expect(runner.lastInput, isNull);
      expect(found.single.pairing, true);
      final failed = AdbService(
        runner: StubRunner((_, _) => output('Unknown command mdns')),
      );
      await expectLater(
        failed.discoverWireless(),
        throwsA(code('discovery_unavailable')),
      );
    },
  );
  test(
    'nonzero setup and discovery failures keep actionable guidance',
    () async {
      final version = AdbService(
        runner: StubRunner(
          (_, _) => output('', exit: 1, error: 'library not found'),
        ),
      );
      await expectLater(version.version(), throwsA(code('adb_unavailable')));

      final discovery = AdbService(
        runner: StubRunner(
          (_, _) => output('', exit: 1, error: 'unknown command mdns'),
        ),
      );
      await expectLater(
        discovery.discoverWireless(),
        throwsA(code('discovery_unavailable')),
      );
    },
  );
  group('Address validation', () {
    test('accepts IPv4, DNS and bracketed IPv6 with explicit ports', () {
      for (final value in [
        '192.168.1.20:5555',
        'android.local:37121',
        '[2001:db8::1]:65535',
      ]) {
        expect(Endpoint.parse(value).toString(), value);
      }
    });
    test(
      'rejects options, shell syntax, invalid IPs and out-of-range ports',
      () {
        for (final value in [
          '--help',
          'host',
          'http://host:5555',
          'host:0',
          'host:65536',
          'host:22;whoami',
          '999.1.1.1:5555',
          '1.2.3:5555',
          '-bad:5555',
          'host..local:5555',
          '[:::]:5555',
          'host:22\nsecond:22',
          'a@host:22',
        ]) {
          expect(
            () => Endpoint.parse(value),
            throwsA(code('invalid_endpoint')),
            reason: value,
          );
        }
      },
    );
  });
  test(
    'parses device states without mistaking daemon chatter for a device',
    () {
      final devices = AdbDevice.parse('''* daemon started successfully
List of devices attached
USB1 device product:husky model:Pixel_8_Pro device:husky transport_id:1
192.168.1.10:5555 offline transport_id:2
USB2 unauthorized usb:1-2
USB3 no permissions (user in plugdev group; are your udev rules wrong?)
USB4 recovery
adb: something failed
''');
      expect(devices.length, 5);
      expect(devices.first.title, 'Pixel 8 Pro');
      expect(devices.map((d) => d.state), [
        'device',
        'offline',
        'unauthorized',
        'no_permissions',
        'recovery',
      ]);
      expect(devices.where((d) => d.ready).length, 1);
    },
  );
  test('connect requires success text even when adb exits zero', () async {
    final service = AdbService(
      runner: StubRunner((_, _) => output('failed to connect to host:5555')),
    );
    await expectLater(
      service.connect(const Endpoint('host', 5555)),
      throwsA(code('connect_failed')),
    );
  });
  test('accepts an already connected response', () async {
    final service = AdbService(
      runner: StubRunner((_, _) => output('already connected to host:5555\n')),
    );
    await service.connect(const Endpoint('host', 5555));
  });
  test('pairing code goes to stdin, never argv', () async {
    final runner = StubRunner(
      (_, _) => output('Enter pairing code: Successfully paired to host:40123'),
    );
    await AdbService(
      runner: runner,
    ).pair(const Endpoint('host', 40123), '123456');
    expect(runner.lastArgs, ['pair', 'host:40123']);
    expect(runner.lastInput, '123456\n');
  });
  test('invalid pairing code never launches the process', () async {
    final runner = StubRunner((_, _) => throw StateError('must not execute'));
    await expectLater(
      AdbService(runner: runner).pair(const Endpoint('host', 40123), '12345\n'),
      throwsA(code('invalid_pairing_code')),
    );
    expect(runner.lastArgs, isNull);
  });
  test('pairing rejects a zero-exit failure response', () async {
    final service = AdbService(
      runner: StubRunner((_, _) => output('Failed: wrong password')),
    );
    await expectLater(
      service.pair(const Endpoint('host', 40123), '123456'),
      throwsA(code('pair_failed')),
    );
  });
  test(
    'nonzero pair and connect failures keep their operation guidance',
    () async {
      final connect = AdbService(
        runner: StubRunner(
          (_, _) =>
              output('', exit: 1, error: 'failed to connect to host:5555'),
        ),
      );
      await expectLater(
        connect.connect(const Endpoint('host', 5555)),
        throwsA(code('connect_failed')),
      );
      final noSelectedDevice = AdbService(
        runner: StubRunner(
          (_, _) => output('', exit: 1, error: 'device not found'),
        ),
      );
      await expectLater(
        noSelectedDevice.connect(const Endpoint('host', 5555)),
        throwsA(code('connect_failed')),
      );
      final pair = AdbService(
        runner: StubRunner(
          (_, _) => output('', exit: 1, error: 'Failed: wrong password'),
        ),
      );
      await expectLater(
        pair.pair(const Endpoint('host', 40123), '123456'),
        throwsA(code('pair_failed')),
      );
    },
  );
  test('device operations always specify exactly one target', () async {
    final runner = StubRunner((_, _) => output('logs'));
    await AdbService(runner: runner).logs('USB1');
    expect(runner.lastArgs, [
      '-s',
      'USB1',
      'logcat',
      '-d',
      '-t',
      '500',
      '-v',
      'threadtime',
    ]);
  });
  test(
    'unauthorized output becomes actionable error without raw data',
    () async {
      final service = AdbService(
        runner: StubRunner(
          (_, _) =>
              output('', exit: 1, error: 'device PRIVATE_SERIAL unauthorized'),
        ),
      );
      await expectLater(service.logs('USB1'), throwsA(code('unauthorized')));
    },
  );
  test(
    'APK path with spaces is one argument and installation needs Success',
    () async {
      final directory = await Directory.systemTemp.createTemp('adb-desk-test-');
      addTearDown(() => directory.delete(recursive: true));
      final apk = File('${directory.path}/example app.apk');
      await apk.writeAsBytes([0]);
      final runner = StubRunner(
        (_, _) => output('Performing Streamed Install\nSuccess\n'),
      );
      await AdbService(runner: runner).install('USB1', apk.path);
      expect(runner.lastArgs, [
        '-s',
        'USB1',
        'install',
        '-r',
        apk.absolute.path,
      ]);
      final failing = AdbService(
        runner: StubRunner(
          (_, _) => output('Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE]'),
        ),
      );
      await expectLater(
        failing.install('USB1', apk.path),
        throwsA(code('install_failed')),
      );
    },
  );
  test(
    'nonzero install distinguishes package failure from a lost device',
    () async {
      final directory = await Directory.systemTemp.createTemp('adb-desk-test-');
      addTearDown(() => directory.delete(recursive: true));
      final apk = File('${directory.path}/example.apk');
      await apk.writeAsBytes([0]);

      final packageFailure = AdbService(
        runner: StubRunner(
          (_, _) => output(
            '',
            exit: 1,
            error: 'INSTALL_FAILED: package dependency not found',
          ),
        ),
      );
      await expectLater(
        packageFailure.install('USB1', apk.path),
        throwsA(code('install_failed')),
      );

      final missingDevice = AdbService(
        runner: StubRunner(
          (_, _) => output(
            '',
            exit: 1,
            error: "adb: error: device 'PRIVATE_SERIAL' not found",
          ),
        ),
      );
      await expectLater(
        missingDevice.install('USB1', apk.path),
        throwsA(code('device_missing')),
      );

      final windowsMissingDevice = AdbService(
        runner: StubRunner(
          (_, _) => output(
            '',
            exit: 1,
            error: "adb.exe: error: device 'PRIVATE_SERIAL' not found",
          ),
        ),
      );
      await expectLater(
        windowsMissingDevice.install('USB1', apk.path),
        throwsA(code('device_missing')),
      );

      final disconnectedDuringInstall = AdbService(
        runner: StubRunner(
          (_, _) => output(
            '',
            exit: 1,
            error: "adb: connect error for write: device 'USB1' not found",
          ),
        ),
      );
      await expectLater(
        disconnectedDuringInstall.install('USB1', apk.path),
        throwsA(code('device_missing')),
      );

      final missingLocalFile = AdbService(
        runner: StubRunner(
          (_, _) => output(
            '',
            exit: 1,
            error: 'adb: connect error for write: APK path not found',
          ),
        ),
      );
      await expectLater(
        missingLocalFile.install('USB1', apk.path),
        throwsA(code('install_failed')),
      );
    },
  );
  test(
    'device errors and runner limits take priority over operation defaults',
    () async {
      for (final (error, expected) in [
        ('device PRIVATE_SERIAL unauthorized', 'unauthorized'),
        ('device PRIVATE_SERIAL offline', 'offline'),
      ]) {
        final service = AdbService(
          runner: StubRunner((_, _) => output('', exit: 1, error: error)),
        );
        await expectLater(
          service.connect(const Endpoint('host', 5555)),
          throwsA(code(expected)),
        );
      }
      for (final expected in ['command_timeout', 'output_limit']) {
        final service = AdbService(
          runner: StubRunner((_, _) => throw DeskException(expected)),
        );
        await expectLater(
          service.pair(const Endpoint('host', 40123), '123456'),
          throwsA(code(expected)),
        );
      }
    },
  );
  test('screenshots preserve binary bytes and reject text errors', () async {
    final png = Uint8List.fromList([
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      0,
      255,
      128,
    ]);
    final runner = StubRunner((_, _) => CommandOutput(0, png, Uint8List(0)));
    expect(await AdbService(runner: runner).screenshot('USB1'), png);
    expect(runner.lastArgs, ['-s', 'USB1', 'exec-out', 'screencap', '-p']);
    final failing = AdbService(
      runner: StubRunner((_, _) => output('screencap failed')),
    );
    await expectLater(
      failing.screenshot('USB1'),
      throwsA(code('invalid_screenshot')),
    );
  });
  test(
    'reports whitelist fields and distinguish TCP reachability from authorization',
    () async {
      final calls = <List<String>>[];
      final runner = StubRunner((args, _) {
        calls.add(args);
        return output(
          args.first == 'version'
              ? 'Android Debug Bridge version 1.0.41\nInstalled as /private/path/adb'
              : 'List of devices attached\nSECRET_SERIAL unauthorized model:SecretPhone\n',
        );
      });
      final report = await Diagnostics(
        AdbService(runner: runner),
        probe: (_) async => true,
      ).run(endpoint: const Endpoint('192.168.99.99', 45678));
      final json = jsonEncode(report.toJson());
      for (final secret in [
        'SECRET_SERIAL',
        'SecretPhone',
        '192.168.99.99',
        '45678',
        '/private/path',
      ]) {
        expect(json, isNot(contains(secret)));
      }
      expect(
        report.checks.map((c) => c.code),
        containsAll([
          'port_reachable',
          'port_is_not_authorization',
          'unauthorized',
        ]),
      );
      expect(calls, [
        ['version'],
        ['devices', '-l'],
      ]);
    },
  );
  test(
    'ADB failure does not prevent the independent target port check',
    () async {
      final runner = StubRunner(
        (_, _) => throw const DeskException('adb_unavailable'),
      );
      final report = await Diagnostics(
        AdbService(runner: runner),
        probe: (_) async => false,
      ).run(endpoint: const Endpoint('host', 5555));
      expect(
        report.checks.map((c) => c.code),
        containsAll([
          'adb_unavailable',
          'server_not_checked',
          'port_unreachable',
        ]),
      );
    },
  );
  test('blank target does not probe a network', () async {
    final runner = StubRunner(
      (args, _) => output(
        args.first == 'version'
            ? 'Android Debug Bridge version 1.0.41'
            : 'List of devices attached\n',
      ),
    );
    final report = await Diagnostics(
      AdbService(runner: runner),
      probe: (_) async => throw StateError('must not probe'),
    ).run();
    expect(
      report.checks.map((c) => c.code),
      containsAll(['no_devices', 'port_not_checked']),
    );
  });
  test('real TCP probe distinguishes open and closed local ports', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final endpoint = Endpoint('127.0.0.1', server.port);
    final subscription = server.listen((socket) => socket.destroy());
    expect(await probePort(endpoint), isTrue);
    await subscription.cancel();
    await server.close();
    expect(await probePort(endpoint), isFalse);
  });
}
