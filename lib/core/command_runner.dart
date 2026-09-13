import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'models.dart';

class CommandOutput {
  const CommandOutput(this.exitCode, this.stdout, this.stderr);
  final int exitCode;
  final Uint8List stdout;
  final Uint8List stderr;
  String get text => utf8.decode(stdout, allowMalformed: true);
  String get errorText => utf8.decode(stderr, allowMalformed: true);
}

abstract interface class CommandRunner {
  Future<CommandOutput> run(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 15),
    int maxBytes = 24 * 1024 * 1024,
    String? input,
  });
}

class ProcessCommandRunner implements CommandRunner {
  const ProcessCommandRunner();

  @override
  Future<CommandOutput> run(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 15),
    int maxBytes = 24 * 1024 * 1024,
    String? input,
  }) async {
    final Process process;
    try {
      process = await Process.start(executable, arguments, runInShell: false);
    } on ProcessException {
      throw const DeskException('adb_unavailable');
    }
    final out = BytesBuilder(copy: false);
    final err = BytesBuilder(copy: false);
    var total = 0;
    var exceeded = false;
    var timedOut = false;
    void collect(BytesBuilder buffer, List<int> bytes) {
      total += bytes.length;
      if (total > maxBytes) {
        exceeded = true;
        process.kill();
      } else if (!exceeded) {
        buffer.add(bytes);
      }
    }

    final outSub = process.stdout.listen((bytes) => collect(out, bytes));
    final errSub = process.stderr.listen((bytes) => collect(err, bytes));
    final streams = Future.wait<void>([
      outSub.asFuture<void>(),
      errSub.asFuture<void>(),
    ]);
    final timer = Timer(timeout, () {
      timedOut = true;
      process.kill();
    });
    try {
      if (input != null) process.stdin.write(input);
      // adb can exit before consuming stdin (e.g. unsupported pair command).
      try {
        await process.stdin.close();
      } on IOException {
        /* Read exit below. */
      }
      final exitCode = await process.exitCode.timeout(
        timeout + const Duration(seconds: 2),
      );
      await streams.timeout(const Duration(seconds: 2));
      if (timedOut) throw const DeskException('command_timeout');
      if (exceeded) throw const DeskException('output_limit');
      return CommandOutput(exitCode, out.takeBytes(), err.takeBytes());
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      throw const DeskException('command_timeout');
    } finally {
      timer.cancel();
      await outSub.cancel();
      await errSub.cancel();
    }
  }
}
