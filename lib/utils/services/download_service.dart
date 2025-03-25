import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  late String _scriptPath;
  Process? _process;

  Future<void> initializeScript() async {
    final byteData = await rootBundle.load('assets/main.py');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/main.py');
    if (!await file.exists() || await file.length() != byteData.lengthInBytes) {
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    }
    _scriptPath = file.path;
    if (Platform.isLinux || Platform.isMacOS) {
      await Process.run('chmod', ['+x', _scriptPath]);
    }
  }

  Future<void> executeDownloadProcess(
    String url,
    List<String> args, {
    required void Function(String) onOutput,
    int retries = 3,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        _process = await Process.start('python', [_scriptPath, ...args]);
        _process!.stdout.transform(utf8.decoder).listen(onOutput);
        _process!.stderr.transform(utf8.decoder).listen((data) {
          onOutput('[ERROR] $data');
        });

        await _process!.exitCode.timeout(timeout, onTimeout: () {
          _process!.kill();
          throw TimeoutException("Download took too long on attempt $attempt.");
        });
        break; // Thành công thì thoát vòng lặp
      } catch (e) {
        if (attempt == retries) rethrow; // Ném lỗi nếu hết số lần thử
        await Future.delayed(
            Duration(seconds: 2 * attempt)); // Delay trước khi thử lại
      }
    }
  }

  void killProcess() {
    _process?.kill();
  }
}
