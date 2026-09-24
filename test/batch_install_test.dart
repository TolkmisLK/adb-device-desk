import 'package:adb_device_desk/core/batch_install.dart';
import 'package:adb_device_desk/core/demo_service.dart';
import 'package:adb_device_desk/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

class InstallFixture extends DemoService {
  final attempted = <String>[];
  int active = 0;
  int maximumActive = 0;

  @override
  Future<void> install(String serial, String path) async {
    attempted.add(serial);
    active++;
    if (active > maximumActive) maximumActive = active;
    await Future<void>.delayed(Duration.zero);
    active--;
    if (serial == 'offline') throw const DeskException('command_timeout');
  }
}

void main() {
  test(
    'batch installs only explicit targets, serially, continuing after failure',
    () async {
      final service = InstallFixture();
      final progress = <String>[];
      final results = await installBatch(
        service,
        ['first', 'offline', 'last'],
        'example.apk',
        onProgress: (current, completed) =>
            progress.add('${current ?? '-'}:${completed.length}'),
      );
      expect(service.attempted, ['first', 'offline', 'last']);
      expect(service.maximumActive, 1);
      expect(results.map((result) => result.errorCode), [
        null,
        'command_timeout',
        null,
      ]);
      expect(progress, ['first:0', '-:1', 'offline:1', '-:2', 'last:2', '-:3']);
    },
  );

  test('batch rejects an empty or duplicated selection', () async {
    final service = InstallFixture();
    await expectLater(
      installBatch(service, [], 'example.apk'),
      throwsA(
        isA<DeskException>().having(
          (error) => error.code,
          'code',
          'invalid_device',
        ),
      ),
    );
    await expectLater(
      installBatch(service, ['first', 'first'], 'example.apk'),
      throwsA(
        isA<DeskException>().having(
          (error) => error.code,
          'code',
          'invalid_device',
        ),
      ),
    );
    expect(service.attempted, isEmpty);
  });
}
