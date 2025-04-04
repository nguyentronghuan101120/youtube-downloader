import 'dart:async';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadService {
  final YoutubeExplode _yt = YoutubeExplode();
  StreamController<String> _logController = StreamController.broadcast();
  Stream<String> get logs => _logController.stream;

  Future<void> initializeScript() async {
    // No initialization needed for youtube_explode_dart
  }

  Future<void> executeDownloadProcess(
    String url,
    List<String> args, {
    required void Function(String) onOutput,
    int retries = 3,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    try {
      final videoId = VideoId(url);
      final video = await _yt.videos.get(videoId);

      // Parse arguments
      final formatType = args.contains('--format=video') ? 'video' : 'audio';
      final audioFormat = args
          .firstWhere(
            (arg) => arg.startsWith('--audio-format='),
            orElse: () => '--audio-format=mp3',
          )
          .split('=')[1];
      final videoQuality = args
          .firstWhere(
            (arg) => arg.startsWith('--quality='),
            orElse: () => '--quality=720p',
          )
          .split('=')[1];
      final outputDir = args
          .firstWhere(
            (arg) => arg.startsWith('--output-dir'),
            orElse: () => '--output-dir=${Directory.current.path}',
          )
          .split('=')[1];

      // Get stream manifest
      final manifest = await _yt.videos.streams.getManifest(videoId);

      // Select appropriate stream based on format type
      StreamInfo streamInfo;
      if (formatType == 'video') {
        final videoStream = manifest.videoOnly
            .where((e) => e.videoQuality.name == videoQuality)
            .first;
        final audioStream = manifest.audioOnly.withHighestBitrate();
        streamInfo = videoStream;

        // Download video and audio separately
        final videoFile =
            File('$outputDir/${video.title}.${videoStream.container.name}');
        final audioFile =
            File('$outputDir/${video.title}.${audioStream.container.name}');

        await _downloadStream(videoStream, videoFile, onOutput);
        await _downloadStream(audioStream, audioFile, onOutput);

        // TODO: Use FFmpeg to merge video and audio
        onOutput(
            'START_INFO:{"id":"${video.id}","status":"finished","output_path":"${videoFile.path}"}:END_INFO');
      } else {
        streamInfo = manifest.audioOnly
            .where((e) => e.container.name == audioFormat)
            .first;

        final file =
            File('$outputDir/${video.title}.${streamInfo.container.name}');
        await _downloadStream(streamInfo, file, onOutput);
        onOutput(
            'START_INFO:{"id":"${video.id}","status":"finished","output_path":"${file.path}"}:END_INFO');
      }
    } catch (e) {
      onOutput('START_ERROR:$e:END_ERROR');
      rethrow;
    }
  }

  Future<void> _downloadStream(
      StreamInfo streamInfo, File file, void Function(String) onOutput) async {
    final stream = await _yt.videos.streams.get(streamInfo);
    final fileStream = file.openWrite();

    var downloadedBytes = 0;
    final totalBytes = streamInfo.size.totalBytes;

    final completer = Completer<void>();
    final subscription = stream.listen(
      (data) {
        downloadedBytes += data.length;
        final percent = (downloadedBytes / totalBytes * 100).toStringAsFixed(1);
        onOutput(
            'START_INFO:{"id":"${streamInfo.videoId}","status":"downloading","percent":$percent}:END_INFO');
        fileStream.add(data);
      },
      onDone: () async {
        await fileStream.flush();
        await fileStream.close();
        completer.complete();
      },
      onError: (error) {
        onOutput('START_ERROR:$error:END_ERROR');
        completer.completeError(error);
      },
    );

    await completer.future;
    await subscription.cancel();
  }

  void killProcess() {
    // No process to kill with youtube_explode_dart
  }

  Future<void> close() async {
    await _logController.close();
  }
}
