import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_flutter/ui/download/ui/playlist_view_screen.dart';
import 'package:youtube_downloader_flutter/ui/download/controller/download_controller.dart';
import 'package:youtube_downloader_flutter/utils/enums/download_config.dart';
import 'package:youtube_downloader_flutter/utils/models/log_model.dart';
import 'package:youtube_downloader_flutter/utils/models/video_info_model.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _urlController = TextEditingController();
  DownloadType _downloadType = DownloadType.audio;
  AudioFormat _audioFormat = AudioFormat.mp3;
  VideoQuality _videoQuality = VideoQuality.fullHd;

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadController>(
      builder: (context, controller, child) {
        controller.processLogs.listen((log) {
          if (log.type == LogType.error &&
              log.message.contains('[ERROR]') &&
              mounted) {
            final errorMsg = _parseErrorMessage(log.message);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg)),
              );
            }
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('YouTube Downloader'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputRow(controller),
                const SizedBox(height: 16),
                _buildOutputDirRow(controller),
                const SizedBox(height: 16),
                _buildDownloadButton(controller),
                const SizedBox(height: 16),
                if (controller.isDownloading)
                  Text(
                    'Đang tải: ${controller.videoInfos.length} video',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      if (controller.videoInfos.isNotEmpty)
                        Flexible(
                          child: ListView.builder(
                            itemCount: controller.videoInfos.length,
                            itemBuilder: (context, index) =>
                                _buildVideoInfo(controller.videoInfos[index]),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoInfo(VideoInfoModel videoInfo) {
    final duration = Duration(seconds: videoInfo.duration ?? 0);
    final durationStr =
        "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  if (videoInfo.thumbnailUrl != null &&
                      videoInfo.thumbnailUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        videoInfo.thumbnailUrl!,
                        width: 100,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          videoInfo.title ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text("Duration: $durationStr"),
                        if (videoInfo.status != null)
                          Text("Status: ${videoInfo.status}"),
                      ],
                    ),
                  ),
                  Text(
                    "${videoInfo.percent ?? 0}%",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: videoInfo.percent != null ? videoInfo.percent! / 100 : 0,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow(DownloadController controller) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'YouTube URL',
              hintText: 'Enter YouTube video/playlist URL',
              border: OutlineInputBorder(),
            ),
            enabled: !controller.isDownloading,
            onFieldSubmitted: (_) => _handleUrlInput(controller),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<DownloadType>(
          value: _downloadType,
          items: DownloadType.values
              .map((type) =>
                  DropdownMenuItem(value: type, child: Text(type.name)))
              .toList(),
          onChanged: controller.isDownloading
              ? null
              : (value) => setState(() => _downloadType = value!),
        ),
        const SizedBox(width: 8),
        if (_downloadType == DownloadType.video)
          _buildVideoQualityDropdown(controller),
        if (_downloadType == DownloadType.audio)
          _buildAudioFormatDropdown(controller),
      ],
    );
  }

  Widget _buildOutputDirRow(DownloadController controller) {
    return Row(
      children: [
        Expanded(
          child: Text(
            controller.outputDir ?? 'No output directory selected',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: controller.outputDir == null ? Colors.grey : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed:
              controller.isDownloading ? null : controller.pickOutputDirectory,
          child: const Text('Choose Output Directory'),
        ),
      ],
    );
  }

  Widget _buildVideoQualityDropdown(DownloadController controller) {
    return DropdownButton<VideoQuality>(
      value: _videoQuality,
      items: VideoQuality.values
          .map((quality) => DropdownMenuItem(
                value: quality,
                child: Text(quality.name),
              ))
          .toList(),
      onChanged: controller.isDownloading
          ? null
          : (value) => setState(() => _videoQuality = value!),
    );
  }

  Widget _buildAudioFormatDropdown(DownloadController controller) {
    return DropdownButton<AudioFormat>(
      value: _audioFormat,
      items: AudioFormat.values
          .map((format) => DropdownMenuItem(
                value: format,
                child: Text(format.name),
              ))
          .toList(),
      onChanged: controller.isDownloading
          ? null
          : (value) => setState(() => _audioFormat = value!),
    );
  }

  Widget _buildDownloadButton(DownloadController controller) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: controller.isDownloading || controller.outputDir == null
                ? null
                : () => _handleUrlInput(controller),
            child: controller.isDownloading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Start Download'),
          ),
        ),
        if (controller.isDownloading) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: controller.cancelDownload,
            child: const Icon(Icons.cancel),
          ),
        ],
      ],
    );
  }

  void _handleUrlInput(DownloadController controller) async {
    final url = _urlController.text.trim();
    if (url.isEmpty || !controller.isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid YouTube URL')),
      );
      return;
    }

    if (controller.isPlaylistUrl(url)) {
      final listVideos = await controller.fetchPlaylistVideos(url);
      if (listVideos == null || listVideos.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to fetch playlist videos')),
          );
        }
        return;
      }
      if (mounted) {
        final selectedUrls = await Navigator.push<List<String>>(
          context,
          MaterialPageRoute(
              builder: (_) => PlaylistViewScreen(videos: listVideos)),
        );
        if (selectedUrls != null && selectedUrls.isNotEmpty) {
          controller.youtubeDownloader(
            url,
            downloadType: _downloadType,
            audioFormat: _audioFormat,
            videoQuality: _videoQuality,
            playlistUrls: selectedUrls,
          );
        } else {
          controller.resetDownloadState();
        }
      }
    } else {
      controller.youtubeDownloader(
        url,
        downloadType: _downloadType,
        audioFormat: _audioFormat,
        videoQuality: _videoQuality,
      );
    }
  }

  String _parseErrorMessage(String message) {
    if (message.contains('Video unavailable')) {
      return 'Video is unavailable or blocked in your region.';
    } else if (message.contains('TimeoutException')) {
      return 'Download took too long, please try again.';
    } else if (message.contains('network')) {
      return 'Network error, please check your internet connection.';
    }
    return 'An error occurred: ${message.split('[ERROR] ').last}';
  }
}

extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}
