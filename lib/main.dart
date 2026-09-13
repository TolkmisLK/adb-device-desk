import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/settings.dart';
import 'ui/desk_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await Settings.load();
  runApp(DeskApp(settings: settings));
}

class DeskApp extends StatefulWidget {
  const DeskApp({
    super.key,
    this.settings = const Settings(),
    this.demo = const bool.fromEnvironment('DEMO'),
  });
  final Settings settings;
  final bool demo;
  @override
  State<DeskApp> createState() => _DeskAppState();
}

class _DeskAppState extends State<DeskApp> {
  late bool english = widget.settings.english;
  ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF087F73),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF121C1C)
          : const Color(0xFFF4F7F7),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ADB Device Desk',
    debugShowCheckedModeBanner: false,
    theme: theme(Brightness.light),
    darkTheme: theme(Brightness.dark),
    locale: Locale(english ? 'en' : 'zh'),
    supportedLocales: const [Locale('zh'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: DeskScreen(
      settings: widget.settings,
      demo: widget.demo,
      english: english,
      onLanguageChanged: (value) => setState(() => english = value),
    ),
  );
}
