import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adb_device_desk/main.dart';
import 'package:adb_device_desk/core/settings.dart';

// Explicit, local visual-review command; not a cross-platform pixel baseline.
// CAPTURE_UI=1 flutter test test/visual_review_test.dart --update-goldens
void main() {
  testWidgets(
    'render actual Flutter demo screens for visual review',
    (tester) async {
      final root = Platform.environment['FLUTTER_ROOT']!;
      final bytes = File(
        '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      ).readAsBytesSync();
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
              ).readAsBytesSync(),
            ),
          ),
        );
      await icons.load();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const DeskApp(demo: true, settings: Settings(english: true)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DeskApp),
        matchesGoldenFile('../docs/screenshots/devices.png'),
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DeskApp),
        matchesGoldenFile('../docs/screenshots/devices-dark.png'),
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wireless'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DeskApp),
        matchesGoldenFile('../docs/screenshots/wireless.png'),
      );
      await tester.tap(find.text('Diagnostics'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Run diagnostics'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DeskApp),
        matchesGoldenFile('../docs/screenshots/diagnostics.png'),
      );
      expect(tester.takeException(), isNull);
    },
    skip: Platform.environment['CAPTURE_UI'] != '1',
  );
}
