import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_downloader_flutter/utils/download_config.dart';
import 'package:youtube_downloader_flutter/utils/log_model.dart';

class DownloadController extends ChangeNotifier {
  final List<LogModel> processLogs = [];
  bool _isDownloading = false;
  String? _downloadedFilePath;
  Process? _process;
  late String _scriptPath;

  bool get isDownloading => _isDownloading;
  String? get downloadedFilePath => _downloadedFilePath;

  DownloadController() {
    _initializeScript();
  }

  Future<void> _initializeScript() async {
    _scriptPath = await _prepareScript();
    if (Platform.isLinux || Platform.isMacOS) {
      await _makeFileExecutable(_scriptPath);
    }
  }

  Future<String> _prepareScript() async {
    final byteData = await rootBundle.load('assets/excutable_for_app.py');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/excutable_for_app.py');
    // Ghi đè file mỗi lần để đảm bảo dùng script mới nhất
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
  }

  Future<void> _makeFileExecutable(String path) async {
    await Process.run('chmod', ['+x', path]);
  }

  Future<void> youtubeDownloader(
    String youtubeUrl,
    DownloadType downloadType,
    AudioFormat audioFormat,
    VideoQuality videoQuality,
    String outputDir,
  ) async {
    if (!_isValidUrl(youtubeUrl)) {
      _logMessage('Invalid YouTube URL', LogType.error);
      notifyListeners();
      return;
    }

    _isDownloading = true;
    processLogs.clear();
    _downloadedFilePath = null;
    _process = null;
    notifyListeners();

    _logMessage("Preparing to download...");
    try {
      final args = await _buildProcessArgs(
          youtubeUrl, downloadType, audioFormat, videoQuality, outputDir);
      _process = await Process.start('python', [_scriptPath, ...args]);
      _listenToProcessOutput(_process!);

      final exitCode = await _process!.exitCode.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          _process!.kill();
          throw TimeoutException("Download took too long.");
        },
      );

      if (exitCode == 0) {
        _downloadedFilePath = await _getOutputPathFromLogs();
        _logMessage("Download completed successfully!");
      } else {
        final error = await _process!.stderr.transform(utf8.decoder).join();
        throw Exception("Download failed: $error");
      }
    } catch (e) {
      _logMessage('Error: $e', LogType.error);
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  void cancelDownload() {
    _process?.kill();
    _isDownloading = false;
    _logMessage("Download cancelled", LogType.warning);
    notifyListeners();
  }

  bool _isValidUrl(String url) {
    final regex =
        RegExp(r'^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.*$');
    return regex.hasMatch(url.trim());
  }

  Future<List<String>> _buildProcessArgs(
    String youtubeUrl,
    DownloadType downloadType,
    AudioFormat audioFormat,
    VideoQuality videoQuality,
    String outputDir,
  ) async {
    final args = [
      youtubeUrl,
      '--format=${downloadType.name}',
      if (downloadType == DownloadType.audio)
        '--audio-format=${audioFormat.name}',
      if (downloadType == DownloadType.video) '--quality=${videoQuality.value}',
      '--output-dir',
      outputDir,
    ];
    return args;
  }

  void _listenToProcessOutput(Process process) {
    process.stdout.transform(utf8.decoder).listen((data) => _logMessage(data));
    process.stderr
        .transform(utf8.decoder)
        .listen((data) => _logMessage(data, LogType.error));
  }

  Future<String?> _getOutputPathFromLogs() async {
    final log = processLogs.lastWhere(
      (log) => log.message.contains("Download completed:"),
      orElse: () => LogModel("", LogType.info),
    );
    return log.message.contains("Download completed:")
        ? log.message.split("Download completed: ").last.trim()
        : null;
  }

  void _logMessage(String message, [LogType type = LogType.info]) {
    final logMessage = message.trim();
    if (logMessage.isEmpty) return;
    final logType = type != LogType.info
        ? type
        : logMessage.toLowerCase().contains('error') ||
                logMessage.toLowerCase().contains('failed')
            ? LogType.error
            : logMessage.toLowerCase().contains('warning')
                ? LogType.warning
                : LogType.info;
    processLogs.add(LogModel(logMessage, logType));
    notifyListeners();
  }
}
