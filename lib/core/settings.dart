import 'dart:convert';
import 'dart:io';

class Settings {
  const Settings({this.adbPath = 'adb', this.english = false});
  final String adbPath;
  final bool english;

  static File get file {
    final env = Platform.environment;
    final root = Platform.isWindows
        ? env['APPDATA'] ?? env['USERPROFILE'] ?? Directory.current.path
        : env['XDG_CONFIG_HOME'] ??
              '${env['HOME'] ?? Directory.current.path}/.config';
    return File('$root/adb-device-desk/settings.json');
  }

  static Future<Settings> load({File? source}) async {
    try {
      final value =
          jsonDecode(await (source ?? file).readAsString())
              as Map<String, dynamic>;
      final path = value['adbPath'];
      return Settings(
        adbPath: path is String && path.trim().isNotEmpty ? path : 'adb',
        english: value['english'] == true,
      );
    } on Object {
      return const Settings();
    }
  }

  Future<void> save({File? destination}) async {
    final target = destination ?? file;
    await target.parent.create(recursive: true);
    // Only preferences are persisted. No device history or pairing secrets.
    await target.writeAsString(
      jsonEncode({'adbPath': adbPath, 'english': english}),
      flush: true,
    );
  }
}
