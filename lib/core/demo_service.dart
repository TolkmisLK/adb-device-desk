import 'dart:typed_data';
import 'adb_service.dart';
import 'models.dart';

class DemoService implements DeviceService {
  const DemoService();
  @override
  Future<String> version() async =>
      'Android Debug Bridge version 1.0.41 (demo)';
  @override
  Future<List<AdbDevice>> devices() async => const [
    AdbDevice('demo-usb-device', 'device', model: 'Pixel_8'),
    AdbDevice('192.0.2.24:37121', 'offline', model: 'Test_tablet'),
    AdbDevice('demo-authorization', 'unauthorized', model: 'Android_device'),
  ];
  @override
  Future<void> connect(Endpoint endpoint) async =>
      throw const DeskException('demo_only');
  @override
  Future<void> pair(Endpoint endpoint, String code) async =>
      throw const DeskException('demo_only');
  @override
  Future<void> disconnect(String serial) async =>
      throw const DeskException('demo_only');
  @override
  Future<void> install(String serial, String path) async =>
      throw const DeskException('demo_only');
  @override
  Future<Uint8List> screenshot(String serial) async =>
      throw const DeskException('demo_only');
  @override
  Future<String> logs(String serial) async =>
      throw const DeskException('demo_only');
  @override
  Future<Map<String, String>> info(String serial) async => {
    'ro.product.manufacturer': 'Google',
    'ro.product.model': 'Pixel 8',
    'ro.build.version.release': '14',
    'ro.build.version.sdk': '34',
  };
}
