import 'dart:io';

import 'package:adb_device_desk/core/demo_service.dart';
import 'package:adb_device_desk/core/models.dart';
import 'package:adb_device_desk/core/settings.dart';
import 'package:adb_device_desk/ui/desk_screen.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RetryFixture extends DemoService {
  final attempted = <String>[];
  int deviceReads = 0;
  int? offlineOnRead;

  @override
  Future<List<AdbDevice>> devices() async {
    deviceReads++;
    return [
      const AdbDevice('one', 'device', model: 'First'),
      AdbDevice(
        'two',
        offlineOnRead != null && deviceReads >= offlineOnRead!
            ? 'offline'
            : 'device',
        model: 'Second',
      ),
      const AdbDevice('three', 'device', model: 'Third'),
    ];
  }

  @override
  Future<void> install(String serial, String path) async {
    attempted.add(serial);
    if (serial == 'two' &&
        attempted.where((value) => value == 'two').length == 1) {
      throw const DeskException('install_failed');
    }
  }
}

Future<RetryFixture> startFailedBatch(WidgetTester tester) async {
  final directory = await Directory.systemTemp.createTemp(
    'batch-retry-widget-',
  );
  addTearDown(() => directory.delete(recursive: true));
  final apk = File('${directory.path}${Platform.pathSeparator}example.apk');
  await apk.writeAsBytes([0]);
  final service = RetryFixture();

  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: DeskScreen(
        settings: const Settings(),
        demo: false,
        english: true,
        onLanguageChanged: (_) {},
        service: service,
        selectApk: () async => XFile(apk.path),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Batch install APK'));
  await tester.tap(find.text('Batch install APK'));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.byType(CheckboxListTile).at(0));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.byType(CheckboxListTile).at(1));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text('Choose APK'));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  expect(service.attempted, ['one', 'two']);
  expect(find.text('one: Succeeded'), findsOneWidget);
  expect(find.text('Retry failed installs'), findsOneWidget);
  return service;
}

void main() {
  testWidgets(
    'retry lists only failures, starts unchecked, and cancel does not install',
    (tester) async {
      final service = await startFailedBatch(tester);
      await tester.ensureVisible(find.text('Retry failed installs'));
      await tester.tap(find.text('Retry failed installs'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Select failed installs to retry'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        false,
      );
      final continueButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Continue'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(continueButton.onPressed, isNull);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.attempted, ['one', 'two']);

      await tester.tap(find.text('Retry failed installs'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        false,
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Confirm failed-install retry'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(service.attempted, ['one', 'two', 'two']);
      expect(find.text('one: Succeeded'), findsOneWidget);
      expect(find.text('two: Succeeded'), findsOneWidget);
      expect(
        find.textContaining('2 total · 2 succeeded · 0 failed'),
        findsOneWidget,
      );
      expect(find.text('Retry failed installs'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('device going offline before final confirmation prevents retry', (
    tester,
  ) async {
    final service = await startFailedBatch(tester);
    await tester.ensureVisible(find.text('Retry failed installs'));
    await tester.tap(find.text('Retry failed installs'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 200));
    service.offlineOnRead = service.deviceReads + 1;
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(service.attempted, ['one', 'two']);
    expect(
      find.textContaining('A target device changed state'),
      findsOneWidget,
    );
    expect(find.text('one: Succeeded'), findsOneWidget);
    expect(find.text('Retry failed installs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
