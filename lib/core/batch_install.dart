import 'dart:io';
import 'adb_service.dart';
import 'models.dart';

class InstallResult {
  const InstallResult(this.serial, this.errorCode);
  final String serial;
  final String? errorCode;
  bool get succeeded => errorCode == null;
}

/// Returns only previously failed devices that are ready in a fresh snapshot.
/// The caller must still request an explicit selection and confirmation.
List<String> retryableBatchSerials(
  List<InstallResult> previous,
  List<AdbDevice> current,
) {
  final ready = {
    for (final device in current)
      if (device.ready) device.serial,
  };
  return [
    for (final result in previous)
      if (!result.succeeded && ready.contains(result.serial)) result.serial,
  ];
}

/// Installs on one explicit target at a time. A failed target does not stop
/// later targets, and each underlying ADB command keeps its own timeout.
Future<List<InstallResult>> installBatch(
  DeviceService service,
  List<String> serials,
  String path, {
  void Function(String? current, List<InstallResult> completed)? onProgress,
}) async {
  if (serials.isEmpty || serials.toSet().length != serials.length) {
    throw const DeskException('invalid_device');
  }
  final results = <InstallResult>[];
  for (final serial in serials) {
    onProgress?.call(serial, List.unmodifiable(results));
    String? errorCode;
    try {
      await service.install(serial, path);
    } on DeskException catch (error) {
      errorCode = error.code;
    } on FileSystemException {
      errorCode = 'file_error';
    } on Object {
      errorCode = 'unexpected_error';
    }
    results.add(InstallResult(serial, errorCode));
    onProgress?.call(null, List.unmodifiable(results));
  }
  return List.unmodifiable(results);
}
