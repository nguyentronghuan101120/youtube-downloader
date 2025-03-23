import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_downloader_flutter/utils/enums/download_config.dart';
import 'package:youtube_downloader_flutter/utils/models/log_model.dart';
import 'package:youtube_downloader_flutter/utils/models/video_info_model.dart';

class DownloadController extends ChangeNotifier {
  bool _isDownloading = false;
  String? _outputDir;
  late String _scriptPath;
  String? _downloadedFilePath;
  final List<VideoInfoModel> _videoInfos = [];
  final List<LogModel> processLogs = [];
  late Process process;

  bool get isDownloading => _isDownloading;
  String? get outputDir => _outputDir;
  String? get downloadedFilePath => _downloadedFilePath;
  List<VideoInfoModel> get videoInfos => _videoInfos;

  DownloadController() {
    _initializeScript();
    _setDefaultDownloadDirectory();
  }

  Future<void> _initializeScript() async {
    final byteData = await rootBundle.load('assets/main.py');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/main.py');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    _scriptPath = file.path;
    if (Platform.isLinux || Platform.isMacOS) {
      await Process.run('chmod', ['+x', _scriptPath]);
    }
  }

  Future<void> _setDefaultDownloadDirectory() async {
    try {
      Directory? downloadsDir = await getDownloadsDirectory();
      _outputDir = downloadsDir != null
          ? "${downloadsDir.path}/youtube-downloader"
          : (await getExternalStorageDirectory())?.path;
    } catch (e) {
      _outputDir = null;
      logMessage('Error setting default directory: $e', LogType.error);
    }
    notifyListeners();
  }

  Future<void> pickOutputDirectory() async {
    String? selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir != null) {
      _outputDir = selectedDir;
      notifyListeners();
    }
  }

  bool _isValidUrl(String url) {
    final regex =
        RegExp(r'^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.*$');
    return regex.hasMatch(url.trim());
  }

  // THAY ĐỔI: Thêm phương thức mới để kiểm tra URL có phải playlist không
  // Comment: Thêm logic kiểm tra trực tiếp trong ứng dụng thay vì gọi script
  bool isPlaylistUrl(String url) {
    final uri = Uri.parse(url);
    return uri.queryParameters.containsKey('list');
  }

  Future<void> executeDownloadProcess(
    String url,
    List<String> args, {
    required void Function(String) onOutput,
  }) async {
    if (!_isValidUrl(url)) {
      logMessage('Invalid YouTube URL', LogType.error);
      notifyListeners();
      return;
    }

    if (_outputDir == null) {
      logMessage('No output directory selected', LogType.error);
      notifyListeners();
      return;
    }

    process = await Process.start('python', [_scriptPath, ...args]);
    process.stdout.transform(utf8.decoder).listen((data) {
      onOutput(data);
    });
    process.stderr.transform(utf8.decoder).listen((data) {
      logMessage(data, LogType.error);
    });

    await process.exitCode.timeout(const Duration(minutes: 30), onTimeout: () {
      process.kill();
      throw TimeoutException("Download took too long.");
    });
  }

  void logMessage(String message, [LogType type = LogType.info]) {
    final logMessage = message.trim();
    if (logMessage.isEmpty) return;
    processLogs.add(LogModel(logMessage, type));
    debugPrint(logMessage);
    notifyListeners();
  }

  void cancelDownload() {
    logMessage("Download cancelled", LogType.warning);
    resetDownloadState();
    process.kill();

    notifyListeners();
  }

  Future<List<VideoInfoModel>?> fetchPlaylistVideos(String playlistUrl) async {
    resetDownloadState();
    _isDownloading = true;
    if (!_isValidUrl(playlistUrl)) {
      logMessage('Invalid YouTube URL', LogType.error);
      notifyListeners();
      return null;
    }

    try {
      final args = [
        playlistUrl,
        '--format=info-only',
        '--output-dir',
        _outputDir ?? ''
      ];
      process = await Process.start('python', [_scriptPath, ...args]);
      final output = await process.stdout.transform(utf8.decoder).join();
      final jsonMatch = RegExp(r'START_INFO:(.+):END_INFO').firstMatch(output);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(1)!;
        final jsonData = jsonDecode(jsonStr);
        if (jsonData is List) {
          return jsonData.map((item) => VideoInfoModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      logMessage('Error fetching playlist: $e', LogType.error);
      resetDownloadState();
      return null;
    }
  }

  Future<void> youtubeDownloader(
    String youtubeUrl, {
    DownloadType downloadType = DownloadType.audio,
    AudioFormat audioFormat = AudioFormat.mp3,
    VideoQuality videoQuality = VideoQuality.fullHd,
    List<String>? playlistUrls,
  }) async {
    resetDownloadState();
    _isDownloading = true;
    final urlsToDownload = playlistUrls ?? [youtubeUrl];
    try {
      await Future.wait(urlsToDownload.map((url) async {
        final args = [
          url,
          '--format=${downloadType.name}',
          if (downloadType == DownloadType.audio)
            '--audio-format=${audioFormat.name}',
          if (downloadType == DownloadType.video)
            '--quality=${videoQuality.name}',
          '--output-dir',
          _outputDir!,
        ];

        await executeDownloadProcess(url, args, onOutput: (data) {
          if (data.startsWith("START_INFO") && data.contains("START_INFO")) {
            final start = data.indexOf("START_INFO:") + "START_INFO:".length;
            final end = data.indexOf(":END_INFO");
            final jsonStr = data.substring(start, end).trim();
            final json = jsonDecode(jsonStr);
            final videoInfo = VideoInfoModel.fromJson(json);
            final index =
                _videoInfos.indexWhere((element) => element.id == videoInfo.id);

            if (index != -1) {
              _videoInfos[index] = videoInfo.copyWith(
                percent: videoInfo.percent,
                status: videoInfo.status,
              );
            } else {
              _videoInfos.add(videoInfo);
            }
          }
          logMessage(data);
          notifyListeners();
        });

        _downloadedFilePath = await _getOutputPathFromLogs();
      }));
    } catch (e) {
      logMessage('Error: $e', LogType.error);
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  void setPlaylistUrls(List<String> urls) {
    notifyListeners();
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

  void resetDownloadState() {
    _isDownloading = false;
    _downloadedFilePath = null;
    _videoInfos.clear();
    processLogs.clear();
    notifyListeners();
  }
}
