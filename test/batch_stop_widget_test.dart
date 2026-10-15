import 'dart:async';
import 'dart:io';

import 'package:adb_device_desk/core/demo_service.dart';
import 'package:adb_device_desk/core/models.dart';
import 'package:adb_device_desk/core/settings.dart';
import 'package:adb_device_desk/ui/desk_screen.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class StopFixture extends DemoService {
  final firstStarted = Completer<void>();
  final releaseFirst = Completer<void>();
  final attempted = <String>[];
  final readWaiters = <int, Completer<void>>{};
  final attemptWaiters = <int, Completer<void>>{};
  int deviceReads = 0;

  Future<void> waitForRead(int count) => deviceReads >= count
      ? Future<void>.value()
      : (readWaiters[count] ??= Completer<void>()).future;

  Future<void> waitForAttempts(int count) => attempted.length >= count
      ? Future<void>.value()
      : (attemptWaiters[count] ??= Completer<void>()).future;

  @override
  Future<List<AdbDevice>> devices() async {
    deviceReads++;
    readWaiters.remove(deviceReads)?.complete();
    return const [
      AdbDevice('one', 'device'),
      AdbDevice('two', 'device'),
      AdbDevice('three', 'device'),
    ];
  }

  @override
  Future<void> install(String serial, String path) async {
    attempted.add(serial);
    attemptWaiters.remove(attempted.length)?.complete();
    if (serial == 'one') {
      firstStarted.complete();
      await releaseFirst.future;
    }
  }
}

void main() {
  testWidgets(
    'stop keeps the current result and continuation requires selection',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync(
        'batch-stop-widget-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final apk = File('${directory.path}${Platform.pathSeparator}example.apk');
      apk.writeAsBytesSync([0]);
      final service = StopFixture();

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
      await tester.tap(find.byType(CheckboxListTile).at(2));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Choose APK'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.runAsync(
        () => service.firstStarted.future.timeout(const Duration(seconds: 10)),
      );

      await tester.ensureVisible(find.text('Stop after current device'));
      await tester.tap(find.text('Stop after current device'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(service.attempted, ['one']);
      service.releaseFirst.complete();
      await tester.pumpAndSettle();
      expect(service.attempted, ['one']);
      expect(find.text('one: Succeeded'), findsOneWidget);
      expect(find.text('two: Not attempted'), findsOneWidget);
      expect(find.text('three: Not attempted'), findsOneWidget);

      await tester.ensureVisible(find.text('Continue unattempted installs'));
      final nextRead = service.deviceReads + 1;
      await tester.runAsync(() async {
        await tester.tap(find.text('Continue unattempted installs'));
        await service
            .waitForRead(nextRead)
            .timeout(const Duration(seconds: 10));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Select unattempted targets'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .value,
        false,
      );
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump(const Duration(milliseconds: 200));
      final selectionContinue = find.descendant(
        of: find.ancestor(
          of: find.text('Select unattempted targets'),
          matching: find.byType(AlertDialog),
        ),
        matching: find.text('Continue'),
      );
      await tester.runAsync(() async {
        await tester.tap(selectionContinue);
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Confirm unattempted installs'), findsOneWidget);
      final confirmationContinue = find.descendant(
        of: find.ancestor(
          of: find.text('Confirm unattempted installs'),
          matching: find.byType(AlertDialog),
        ),
        matching: find.text('Continue'),
      );
      final nextAttempt = service.attempted.length + 1;
      await tester.runAsync(() async {
        await tester.tap(confirmationContinue);
        await service
            .waitForRead(nextRead + 1)
            .timeout(const Duration(seconds: 10));
        await service
            .waitForAttempts(nextAttempt)
            .timeout(const Duration(seconds: 10));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(service.attempted, ['one', 'two']);
      expect(find.text('three: Not attempted'), findsOneWidget);
      expect(find.text('Continue unattempted installs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
