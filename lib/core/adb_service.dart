import 'dart:io';
import 'dart:typed_data';
import 'command_runner.dart';
import 'models.dart';

abstract interface class DeviceService {
  Future<String> version();
  Future<List<AdbDevice>> devices();
  Future<void> connect(Endpoint endpoint);
  Future<void> pair(Endpoint endpoint, String code);
  Future<void> disconnect(String serial);
  Future<void> install(String serial, String path);
  Future<Uint8List> screenshot(String serial);
  Future<String> logs(String serial);
  Future<Map<String, String>> info(String serial);
}

class AdbService implements DeviceService {
  AdbService({this.executable = 'adb', CommandRunner? runner})
    : runner = runner ?? const ProcessCommandRunner();
  final String executable;
  final CommandRunner runner;

  Future<CommandOutput> _run(
    List<String> args, {
    Duration timeout = const Duration(seconds: 15),
    String? input,
  }) async {
    final result = await runner.run(
      executable,
      args,
      timeout: timeout,
      input: input,
    );
    if (result.exitCode != 0) {
      final output = '${result.text}\n${result.errorText}'.toLowerCase();
      if (output.contains('unauthorized')) {
        throw const DeskException('unauthorized');
      }
      if (output.contains('offline')) throw const DeskException('offline');
      if (output.contains('no devices') || output.contains('not found')) {
        throw const DeskException('device_missing');
      }
      throw const DeskException('command_failed');
    }
    return result;
  }

  List<String> _target(String serial, List<String> args) {
    if (serial.isEmpty ||
        serial.startsWith('-') ||
        RegExp(r'\s').hasMatch(serial)) {
      throw const DeskException('invalid_device');
    }
    return ['-s', serial, ...args];
  }

  @override
  Future<String> version() async {
    final output = (await _run(['version'])).text;
    if (!output.contains('Android Debug Bridge version')) {
      throw const DeskException('adb_unavailable');
    }
    return output.split('\n').first.trim();
  }

  @override
  Future<List<AdbDevice>> devices() async =>
      AdbDevice.parse((await _run(['devices', '-l'])).text);

  @override
  Future<void> connect(Endpoint endpoint) async {
    final result = await _run([
      'connect',
      endpoint.toString(),
    ], timeout: const Duration(seconds: 20));
    if (!RegExp(
      r'^(already )?connected to ',
      multiLine: true,
    ).hasMatch(result.text.trim())) {
      throw const DeskException('connect_failed');
    }
  }

  @override
  Future<void> pair(Endpoint endpoint, String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const DeskException('invalid_pairing_code');
    }
    // Send the code over stdin, never through the process argument list.
    final result = await _run(
      ['pair', endpoint.toString()],
      timeout: const Duration(seconds: 30),
      input: '$code\n',
    );
    if (!result.text.contains('Successfully paired to ')) {
      throw const DeskException('pair_failed');
    }
  }

  @override
  Future<void> disconnect(String serial) async {
    final endpoint = Endpoint.parse(serial);
    await _run(['disconnect', endpoint.toString()]);
  }

  @override
  Future<void> install(String serial, String path) async {
    final file = File(path).absolute;
    if (!file.path.toLowerCase().endsWith('.apk') || !await file.exists()) {
      throw const DeskException('invalid_apk');
    }
    final result = await _run(
      _target(serial, ['install', '-r', file.path]),
      timeout: const Duration(minutes: 3),
    );
    if (!RegExp(r'^Success\s*$', multiLine: true).hasMatch(result.text)) {
      throw const DeskException('install_failed');
    }
  }

  @override
  Future<Uint8List> screenshot(String serial) async {
    final bytes = (await _run(
      _target(serial, ['exec-out', 'screencap', '-p']),
    )).stdout;
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 8 ||
        List.generate(8, (i) => bytes[i] == signature[i]).contains(false)) {
      throw const DeskException('invalid_screenshot');
    }
    return bytes;
  }

  @override
  Future<String> logs(String serial) async => (await _run(
    _target(serial, ['logcat', '-d', '-t', '500', '-v', 'threadtime']),
  )).text;

  @override
  Future<Map<String, String>> info(String serial) async {
    final result = <String, String>{};
    for (final property in [
      'ro.product.manufacturer',
      'ro.product.model',
      'ro.build.version.release',
      'ro.build.version.sdk',
    ]) {
      result[property] = (await _run(
        _target(serial, ['shell', 'getprop', property]),
      )).text.trim();
    }
    return result;
  }
}
