import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chaquopy/chaquopy.dart';
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

  Future<String> _getPythonInterpreter() async {
    for (var pythonCmd in ['python', 'python3']) {
      try {
        final result = await Process.run(pythonCmd, ['--version']);
        if (result.exitCode == 0) {
          return pythonCmd;
        }
      } catch (e) {
        continue;
      }
    }

    // Python is missing, attempt installation (Mac/Linux only)
    if (Platform.isMacOS || Platform.isLinux) {
      try {
        await Process.run('brew', ['install', 'python3']);
        return 'python3';
      } catch (e) {
        throw Exception(
            'Failed to install Python. Please install it manually.');
      }
    }

    throw Exception(
        'Python is not installed and cannot be automatically set up.');
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
            onOutput('START_ERROR: ${result['stderr']} :END_ERROR');
          }
        } else if (Platform.isMacOS || Platform.isLinux) {
          final pythonCmd = await _getPythonInterpreter();
          _process = await Process.start(pythonCmd, [_scriptPath, ...args]);
          _process!.stdout.transform(utf8.decoder).listen(onOutput);
          _process!.stderr.transform(utf8.decoder).listen((data) {
            onOutput('START_ERROR: $data :END_ERROR');
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
        break;
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
