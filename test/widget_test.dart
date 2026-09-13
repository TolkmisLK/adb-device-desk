import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adb_device_desk/main.dart';
import 'package:adb_device_desk/core/settings.dart';

void main() {
  testWidgets(
    'device selection and diagnostics remain usable at desktop size',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const DeskApp(demo: true, settings: Settings(english: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.text('DEMO DATA'), findsOneWidget);
      final install = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Install APK'),
          matching: find.byWidgetPredicate(
            (widget) => widget is OutlinedButton,
          ),
        ),
      );
      expect(install.onPressed, isNull);
      await tester.tap(find.text('Diagnostics'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Run diagnostics'));
      await tester.pumpAndSettle();
      expect(find.text('Diagnostic results'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('narrow window and language switch do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const DeskApp(demo: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('English'));
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
