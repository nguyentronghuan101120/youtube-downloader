import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_downloader_flutter/utils/enums/download_config.dart';
import 'package:youtube_downloader_flutter/utils/models/log_model.dart';
import 'package:youtube_downloader_flutter/utils/models/video_info_model.dart';
import 'package:youtube_downloader_flutter/utils/services/download_services.dart';

class DownloadController extends ChangeNotifier {
  final DownloadService _service = DownloadService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isDownloading = false;
  String? _outputDir;
  final List<String> _downloadedFilePaths = [];
  final List<VideoInfoModel> _videoInfos = [];
// THAY ĐỔI: Thêm StreamController để phát log dưới dạng stream
  final StreamController<LogModel> _logController =
      StreamController.broadcast();
  Stream<LogModel> get processLogs => _logController.stream;

  bool get isDownloading => _isDownloading;
  String? get outputDir => _outputDir;
  List<String> get downloadedFilePaths => _downloadedFilePaths;
  List<VideoInfoModel> get videoInfos => _videoInfos;

  DownloadController() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _service.initializeScript();
    await _setDefaultDownloadDirectory();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _setDefaultDownloadDirectory() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          logMessage(
              'Storage permission denied, please select a directory manually',
              LogType.error);
          await pickOutputDirectory();
          if (_outputDir == null) throw Exception('No directory selected');
          return;
        }
      }

      Directory? downloadsDir = await getDownloadsDirectory();
      _outputDir = downloadsDir != null
          ? "${downloadsDir.path}/youtube-downloader"
          : (await getExternalStorageDirectory())?.path;
      Directory(_outputDir!).createSync(recursive: true);
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

  bool isValidUrl(String url) {
    final regex =
        RegExp(r'^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.*$');
    return regex.hasMatch(url.trim());
  }

  bool isPlaylistUrl(String url) {
    final uri = Uri.parse(url);
    return uri.queryParameters.containsKey('list');
  }

  void logMessage(String message, [LogType type = LogType.info]) {
    final logMessage = message.trim();
    if (logMessage.isEmpty) return;
    _logController.add(LogModel(logMessage, type));
    debugPrint(logMessage);
    notifyListeners();
  }

  void cancelDownload() {
    _service.killProcess();
    _cleanupTempFiles();
    logMessage("Download cancelled", LogType.warning);
    resetDownloadState();
    notifyListeners();
  }

  void _cleanupTempFiles() {
    if (_outputDir != null) {
      Directory(_outputDir!).listSync().forEach((entity) {
        if (entity.path.endsWith('.part')) entity.deleteSync();
      });
    }
  }

  Future<List<VideoInfoModel>?> fetchPlaylistVideos(String playlistUrl) async {
    resetDownloadState();
    _isDownloading = true;
    try {
      final args = [
        '--format=info-only',
        '--output-dir',
        _outputDir ?? '',
        playlistUrl
      ];
      String output = '';
      await _service.executeDownloadProcess(playlistUrl, args,
          onOutput: (data) {
        output += data;
      });
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
    } finally {
      _isDownloading = false;
      notifyListeners();
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
      // THAY ĐỔI: Điều chỉnh timeout dựa trên số lượng URL
      final timeout = Duration(minutes: 5 * urlsToDownload.length);

      final args = [
        ...urlsToDownload,
        '--format=${downloadType.name}',
        if (downloadType == DownloadType.audio)
          '--audio-format=${audioFormat.name}',
        if (downloadType == DownloadType.video)
          '--quality=${videoQuality.name}',
        '--output-dir',
        _outputDir!,
      ];

      await _service.executeDownloadProcess(youtubeUrl, args, timeout: timeout,
          onOutput: (data) {
        if (data.contains("START_INFO")) {
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

        // THAY ĐỔI: Thêm đường dẫn file vào danh sách khi tải xong
        if (data.contains("Download completed:")) {
          final path = data.split("Download completed: ").last.trim();
          _downloadedFilePaths.add(path);
          // THAY ĐỔI: Gửi thông báo cho từng file
          _notificationsPlugin.show(
            _downloadedFilePaths.length, // ID tăng dần để tránh trùng
            'Download Completed',
            'File saved at: $path',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'download_channel',
                'Download Notifications',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
        notifyListeners();
      });
    } catch (e) {
      logMessage('Error: $e', LogType.error);
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  void resetDownloadState() {
    _isDownloading = false;
    _downloadedFilePaths.clear();
    _videoInfos.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _logController.close();
    super.dispose();
  }
}
