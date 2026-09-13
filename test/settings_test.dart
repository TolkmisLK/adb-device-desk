import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:adb_device_desk/core/settings.dart';

void main() {
  late Directory directory;
  late File file;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('adb-desk-settings-');
    file = File('${directory.path}/preferences/settings.json');
  });
  tearDown(() => directory.delete(recursive: true));

  test('missing or malformed settings fall back safely', () async {
    expect((await Settings.load(source: file)).adbPath, 'adb');
    await file.parent.create(recursive: true);
    await file.writeAsString('{broken');
    expect((await Settings.load(source: file)).english, isFalse);
    await file.writeAsString('[1, 2]');
    expect((await Settings.load(source: file)).adbPath, 'adb');
  });

  test('only the executable path and language are persisted', () async {
    const settings = Settings(
      adbPath: r'C:\Program Files\platform-tools\adb.exe',
      english: true,
    );
    await settings.save(destination: file);
    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(decoded.keys.toSet(), {'adbPath', 'english'});
    final restored = await Settings.load(source: file);
    expect(restored.adbPath, settings.adbPath);
    expect(restored.english, isTrue);
  });

  test('empty executable path and unrelated fields are ignored', () async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({'adbPath': '  ', 'english': false, 'pairingCode': '123456'}),
    );
    final restored = await Settings.load(source: file);
    expect(restored.adbPath, 'adb');
    await restored.save(destination: file);
    expect(await file.readAsString(), isNot(contains('123456')));
    expect(await file.readAsString(), isNot(contains('pairingCode')));
  });
}
