import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:adb_device_desk/core/command_runner.dart';
import 'package:adb_device_desk/core/models.dart';

void main() {
  const runner = ProcessCommandRunner();
  final sdk = Platform.environment['FLUTTER_ROOT'];
  final dart = sdk == null
      ? 'dart'
      : '$sdk/bin/cache/dart-sdk/bin/dart${Platform.isWindows ? '.exe' : ''}';
  final fixture = File('test/fixtures/process_fixture.dart').absolute.path;
  test(
    'real process preserves argv boundaries and reads secret from stdin',
    () async {
      final result = await runner.run(dart, [
        fixture,
        'echo',
        'file with spaces.apk',
        'x;echo INJECTED',
      ], input: '123456\n');
      final value = jsonDecode(result.text) as Map<String, dynamic>;
      expect(value['args'], ['file with spaces.apk', 'x;echo INJECTED']);
      expect(value['input'], '123456\n');
    },
  );
  test('real process keeps binary stdout separate from stderr', () async {
    final result = await runner.run(dart, [fixture, 'binary']);
    expect(result.stdout, [0, 128, 255, 13, 10]);
    expect(result.errorText, 'diagnostic');
  });
  test('hung process is stopped within a bounded time', () async {
    final watch = Stopwatch()..start();
    await expectLater(
      runner.run(dart, [
        fixture,
        'wait',
      ], timeout: const Duration(milliseconds: 800)),
      throwsA(
        isA<DeskException>().having((e) => e.code, 'code', 'command_timeout'),
      ),
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
  });
  test('oversized output is rejected', () async {
    await expectLater(
      runner.run(dart, [fixture, 'large'], maxBytes: 1024),
      throwsA(
        isA<DeskException>().having((e) => e.code, 'code', 'output_limit'),
      ),
    );
  });
  test('missing executable has a safe actionable error', () async {
    await expectLater(
      runner.run('nonexistent-adb-desk-test-executable', []),
      throwsA(
        isA<DeskException>().having((e) => e.code, 'code', 'adb_unavailable'),
      ),
    );
  });
}
