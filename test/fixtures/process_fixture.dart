import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  switch (args.first) {
    case 'echo':
      stdout.write(
        jsonEncode({
          'args': args.skip(1).toList(),
          'input': await utf8.decoder.bind(stdin).join(),
        }),
      );
    case 'binary':
      stdout.add([0, 128, 255, 13, 10]);
      stderr.write('diagnostic');
    case 'large':
      stdout.add(List.filled(100000, 65));
    case 'wait':
      await Future<void>.delayed(const Duration(seconds: 30));
  }
}
