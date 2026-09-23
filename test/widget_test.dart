import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adb_device_desk/main.dart';
import 'package:adb_device_desk/core/settings.dart';
import 'package:adb_device_desk/core/demo_service.dart';
import 'package:adb_device_desk/core/models.dart';
import 'package:adb_device_desk/ui/desk_screen.dart';

class DiscoveryFixture extends DemoService {
  int connections = 0;
  int pairings = 0;
  @override
  Future<void> connect(Endpoint endpoint) async {
    connections++;
  }

  @override
  Future<void> pair(Endpoint endpoint, String code) async {
    pairings++;
  }
}

class MissingAdbFixture extends DemoService {
  @override
  Future<String> version() async =>
      throw const DeskException('adb_unavailable');
}

void main() {
  testWidgets('missing ADB leaves a usable setup path', (tester) async {
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
          service: MissingAdbFixture(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Connect your first device'), findsOneWidget);
    expect(
      find.text(
        'Cannot start ADB. Select adb.exe from the official Platform-Tools in Settings and check that it is executable.',
      ),
      findsOneWidget,
    );
    expect(find.text('Set up ADB'), findsOneWidget);
    await tester.ensureVisible(find.text('Set up ADB'));
    await tester.tap(find.text('Set up ADB'));
    await tester.pumpAndSettle();
    expect(find.text('ADB executable'), findsOneWidget);
    expect(
      find.text('https://developer.android.com/tools/releases/platform-tools'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'discovery fills only the chosen port without connecting or pairing',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = DiscoveryFixture();
      await tester.pumpWidget(
        MaterialApp(
          home: DeskScreen(
            settings: const Settings(),
            demo: false,
            english: true,
            onLanguageChanged: (_) {},
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wireless'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refresh discovery'));
      await tester.pumpAndSettle();
      final use = find.text('Use address');
      expect(use, findsNWidgets(2));
      await tester.tap(use.first);
      await tester.pumpAndSettle();
      TextField field(String label) => tester.widget<TextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == label,
        ),
      );
      expect(
        field('Pairing address and port').controller!.text,
        '192.0.2.24:40123',
      );
      expect(field('Connection address and port').controller!.text, isEmpty);
      await tester.tap(use.last);
      await tester.pumpAndSettle();
      expect(
        field('Connection address and port').controller!.text,
        '192.0.2.24:37121',
      );
      expect(
        field('Pairing address and port').controller!.text,
        '192.0.2.24:40123',
      );
      expect(service.connections, 0);
      expect(service.pairings, 0);
      expect(tester.takeException(), isNull);
    },
  );
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
