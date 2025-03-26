import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:path_provider/path_provider.dart';

class DownloadService {
  late String _scriptPath;
  late String _checkScriptPath;
  Process? _process;

  Future<void> initializeScript() async {
    final dir = await getApplicationDocumentsDirectory();

    // Sao chép và cấu hình check_and_install_libs.py
    final checkByteData =
        await rootBundle.load('assets/check_and_install_libs.py');
    final checkFile = File('${dir.path}/check_and_install_libs.py');
    if (!await checkFile.exists() ||
        await checkFile.length() != checkByteData.lengthInBytes) {
      await checkFile.writeAsBytes(checkByteData.buffer.asUint8List(),
          flush: true);
    }
    _checkScriptPath = checkFile.path;

    // Sao chép và cấu hình main.py
    final byteData = await rootBundle.load('assets/main.py');
    final file = File('${dir.path}/main.py');
    if (!await file.exists() || await file.length() != byteData.lengthInBytes) {
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    }
    _scriptPath = file.path;

    // Đảm bảo script có quyền thực thi trên Linux hoặc macOS
    if (Platform.isLinux || Platform.isMacOS) {
      await Process.run('chmod', ['+x', _checkScriptPath]);
      await Process.run('chmod', ['+x', _scriptPath]);
      // Chạy script kiểm tra và cài đặt thư viện trên macOS
      await _checkAndInstallLibraries();
    }
  }

  Future<void> _checkAndInstallLibraries() async {
    debugPrint("Checking and installing required libraries...");
    final process = await Process.start('python3', [_checkScriptPath]);
    process.stdout.transform(utf8.decoder).listen((data) {
      debugPrint(data); // In log ra console để debug
    });
    process.stderr.transform(utf8.decoder).listen((data) {
      debugPrint('[ERROR] $data');
    });
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception("Failed to check and install libraries.");
    }
    debugPrint("Library check completed.");
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
        if (Platform.isAndroid) {
          // Dùng chaquopy trên Android
          final result = await Chaquopy.executeCode('''
import sys
from io import StringIO
from script import main

sys.stdout = StringIO()
sys.argv = ['script.py', '$url', *${jsonEncode(args)}]
main()
sys.stdout.seek(0)
print(sys.stdout.read())
''');
          final output = result['stdout'] as String;
          if (output.isNotEmpty) {
            onOutput(output);
          }
          if (result['stderr'] != null && result['stderr'].isNotEmpty) {
            onOutput('[ERROR] ${result['stderr']}');
          }
        } else if (Platform.isMacOS || Platform.isLinux) {
          // Dùng Process.start trên macOS hoặc Linux
          _process = await Process.start('python3', [_scriptPath, ...args]);
          _process!.stdout.transform(utf8.decoder).listen(onOutput);
          _process!.stderr.transform(utf8.decoder).listen((data) {
            onOutput('[ERROR] $data');
          });
          await _process!.exitCode.timeout(timeout, onTimeout: () {
            _process!.kill();
            throw TimeoutException(
                "Download took too long on attempt $attempt.");
          });
        } else {
          throw UnsupportedError(
              'Platform not supported: ${Platform.operatingSystem}');
        }
        break; // Thành công thì thoát vòng lặp
      } catch (e) {
        onOutput(
            '[ERROR] Failed to execute Python script on attempt $attempt: $e');
        if (attempt == retries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }

  void killProcess() {
    _process?.kill();
  }
}
