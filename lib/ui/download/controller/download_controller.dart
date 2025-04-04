import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_downloader_flutter/utils/enums/download_config.dart';
import 'package:youtube_downloader_flutter/utils/enums/log_type.dart';
import 'package:youtube_downloader_flutter/utils/enums/video_download_status.dart';
import 'package:youtube_downloader_flutter/utils/models/log_model.dart';
import 'package:youtube_downloader_flutter/utils/models/video_info_model.dart';
import 'package:youtube_downloader_flutter/utils/services/download_service.dart';
import 'package:youtube_downloader_flutter/utils/services/local_storage_service.dart';
import 'package:youtube_downloader_flutter/utils/services/notification_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class DownloadController extends ChangeNotifier {
  final DownloadService _service = DownloadService();
  final NotificationService _notificationService = NotificationService();
  bool _isDownloading = false;
  final List<String> _downloadedFilePaths = [];
  final List<VideoInfoModel> _videoInfoListForDownload = [];
  final StreamController<LogModel> _logController =
      StreamController.broadcast();
  Stream<LogModel> get processLogs => _logController.stream;
  String? _outputDir;
  int? _maxWorkers;
  final LocalStorageService _localStorageService = LocalStorageService();
  DownloadType _downloadType = DownloadType.audio;
  AudioFormat _audioFormat = AudioFormat.mp3;
  VideoQuality _videoQuality = VideoQuality.fullHd;
  List<VideoInfoModel> _playlistVideos = [];

  bool get isDownloading => _isDownloading;
  List<String> get downloadedFilePaths => _downloadedFilePaths;
  List<VideoInfoModel> get videoInfoListForDownload =>
      _videoInfoListForDownload;
  String? get outputDir => _outputDir;
  int? get maxWorkers => _maxWorkers;
  DownloadType get downloadType => _downloadType;
  AudioFormat get audioFormat => _audioFormat;
  VideoQuality get videoQuality => _videoQuality;
  List<VideoInfoModel> get playlistVideos => _playlistVideos;

  set downloadType(DownloadType value) {
    _downloadType = value;
    notifyListeners();
  }

  set audioFormat(AudioFormat value) {
    _audioFormat = value;
    notifyListeners();
  }

  set videoQuality(VideoQuality value) {
    _videoQuality = value;
    notifyListeners();
  }

  set playlistVideos(List<VideoInfoModel> value) {
    _playlistVideos = value;
    notifyListeners();
  }

  DownloadController() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _service.initializeScript();
    await _notificationService.initialize();

    final launchDetails = await _notificationService.getLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;
      logMessage('App launched from notification with payload: $payload');
    }

    // Tải cài đặt ban đầu
    await loadSettings();
    notifyListeners();
  }

  // Tải cài đặt từ LocalStorageService
  Future<void> loadSettings() async {
    _outputDir = await _localStorageService.getOutputDir();
    _maxWorkers = await _localStorageService.getMaxWorkers();
    notifyListeners();
  }

  // Phương thức để cập nhật cài đặt từ SettingsController
  void updateSettings(String? newOutputDir, int? newMaxWorkers) {
    if (newOutputDir != _outputDir || newMaxWorkers != _maxWorkers) {
      _outputDir = newOutputDir;
      _maxWorkers = newMaxWorkers;
      logMessage(
          'Settings updated: OutputDir=$_outputDir, MaxWorkers=$_maxWorkers');
      notifyListeners();
    }
  }

  bool _isValidUrl(String url) {
    try {
      yt.VideoId(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isPlaylistUrl(String url) {
    try {
      yt.PlaylistId(url);
      return true;
    } catch (e) {
      return false;
    }
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
    _cleanupTempFiles(_outputDir);
    logMessage("Download cancelled", LogType.warning);
    _isDownloading = false;
    notifyListeners();
  }

  void _cleanupTempFiles(String? outputDir) {
    if (outputDir == null) return;
    Directory(outputDir).listSync().forEach((entity) {
      if (entity.path.endsWith('.part')) entity.deleteSync();
    });
  }

  Future<List<VideoInfoModel>?> _fetchPlaylistVideos(String playlistUrl) async {
    try {
      final ytClient = yt.YoutubeExplode();
      final playlist = await ytClient.playlists.get(yt.PlaylistId(playlistUrl));
      final videos = await ytClient.playlists.getVideos(playlist.id).toList();

      final videoInfos = videos
          .map((video) => VideoInfoModel(
                id: video.id.value,
                title: video.title,
                url: video.url,
                duration: video.duration?.inSeconds ?? 0,
                thumbnailUrl: video.thumbnails.highResUrl,
              ))
          .toList();

      return videoInfos;
    } catch (e) {
      logMessage('Error fetching playlist: $e', LogType.error);
      return null;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<void> youtubeDownloader({
    List<VideoInfoModel>? playlistVideos,
    String? singleUrl,
  }) async {
    resetDownloadState();
    _isDownloading = true;
    final urlsToDownload =
        playlistVideos?.map((v) => v.url!).toList() ?? [singleUrl ?? ''];
    int completedCount = 0;

    try {
      final timeout = Duration(minutes: 5 * urlsToDownload.length);
      for (final url in urlsToDownload) {
        final args = [
          url,
          '--format=${downloadType.name}',
          if (downloadType == DownloadType.audio) ...[
            '--audio-format=${audioFormat.name}',
          ],
          if (downloadType == DownloadType.video) ...[
            '--quality=${videoQuality.quality}',
          ],
          if (_outputDir != null) ...[
            '--output-dir',
            _outputDir!,
          ],
        ];

        await _service.executeDownloadProcess(url, args, timeout: timeout,
            onOutput: (data) async {
          if (data.contains("START_INFO")) {
            final start = data.indexOf("START_INFO:") + "START_INFO:".length;
            final end = data.indexOf(":END_INFO");
            final jsonStr = data.substring(start, end).trim();
            final json = jsonDecode(jsonStr);
            final videoInfo = VideoInfoModel.fromJson(json);
            final index = _videoInfoListForDownload
                .indexWhere((element) => element.id == videoInfo.id);

            if (index != -1) {
              final updatedVideoInfo =
                  _videoInfoListForDownload[index].copyWith(
                percent: videoInfo.percent,
                status: videoInfo.status,
                outputPath: videoInfo.outputPath,
              );
              _videoInfoListForDownload[index] = updatedVideoInfo;

              if (videoInfo.status == VideoDownloadStatus.finished) {
                await _saveDownloadedVideoToLocal(updatedVideoInfo);
              }
            } else {
              _videoInfoListForDownload.add(videoInfo.copyWith(
                status: VideoDownloadStatus.downloading,
              ));
            }
          }
          logMessage(data);

          if (data.contains("Download completed:")) {
            final path = data.split("Download completed: ").last.trim();
            _downloadedFilePaths.add(path);
            completedCount++;

            if (urlsToDownload.length == 1) {
              _notificationService.showNotification(
                id: _downloadedFilePaths.length,
                title: 'Download Completed',
                body: 'File saved at: $path',
              );
            } else if (completedCount == urlsToDownload.length) {
              _notificationService.showNotification(
                id: 0,
                title: 'Playlist Download Completed',
                body: '${urlsToDownload.length} files saved at: $_outputDir',
              );
            }
          }
          notifyListeners();
        });
      }
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
    _videoInfoListForDownload.clear();
    notifyListeners();
  }

  Future<void> _saveDownloadedVideoToLocal(VideoInfoModel video) async {
    final existingIndex = _playlistVideos.indexWhere((v) => v.id == video.id);
    if (existingIndex != -1) {
      _playlistVideos[existingIndex] = video;
    } else {
      _playlistVideos.add(video);
    }
    await _localStorageService.saveHistory(_playlistVideos);
    notifyListeners();
  }

  Future<void> _savePlaylistToLocal(List<VideoInfoModel> videos) async {
    if (_playlistVideos.isEmpty) {
      _playlistVideos = await _localStorageService.getHistory();
    }

    final existingIds = _playlistVideos.map((v) => v.id).toSet();
    for (var video in videos) {
      if (existingIds.contains(video.id)) {
        final index = _playlistVideos.indexWhere((v) => v.id == video.id);
        _playlistVideos[index] = video;
      } else {
        _playlistVideos.add(video);
        existingIds.add(video.id);
      }
    }

    await _localStorageService.saveHistory(_playlistVideos);
    notifyListeners();
  }

  Future<void> getHistory() async {
    final history = await _localStorageService.getHistory();
    _playlistVideos = history;
    notifyListeners();
  }

  Future<void> removeHistory(List<VideoInfoModel> videos) async {
    if (_playlistVideos.isEmpty) {
      _playlistVideos = await _localStorageService.getHistory();
    }

    for (var video in videos) {
      _playlistVideos.removeWhere((v) => v.id == video.id);
    }

    await _localStorageService.saveHistory(_playlistVideos);
    notifyListeners();
  }

  Future<void> handleUrlInput({
    required String url,
    required VoidCallback playlistDownloadCallBack,
  }) async {
    _isDownloading = true;
    notifyListeners();
    if (url.isEmpty || !_isValidUrl(url)) {
      logMessage('Please enter a valid YouTube URL', LogType.error);
      _isDownloading = false;
      notifyListeners();
      return;
    }

    if (_isPlaylistUrl(url)) {
      final listVideos = await _fetchPlaylistVideos(url);
      if (listVideos == null || listVideos.isEmpty) {
        _isDownloading = false;
        notifyListeners();
        return;
      }

      _playlistVideos = listVideos;
      await _savePlaylistToLocal(listVideos);
      playlistDownloadCallBack();
    } else {
      youtubeDownloader(singleUrl: url);
    }

    notifyListeners();
  }

  bool submitValidate(String url) {
    if (url.isEmpty || !_isValidUrl(url)) {
      logMessage('Please enter a valid YouTube URL', LogType.error);
      return false;
    }

    if (_outputDir == null) {
      logMessage('Please select a download directory', LogType.error);
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _logController.close();
    _service.close();
    super.dispose();
  }
}
