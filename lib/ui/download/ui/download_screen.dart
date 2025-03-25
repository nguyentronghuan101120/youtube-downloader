import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_flutter/ui/download/ui/playlist_view_screen.dart';
import 'package:youtube_downloader_flutter/ui/download/controller/download_controller.dart';
import 'package:youtube_downloader_flutter/ui/settings/ui/settings_screen.dart';
import 'package:youtube_downloader_flutter/utils/enums/download_config.dart';
import 'package:youtube_downloader_flutter/utils/enums/log_type.dart';
import 'package:youtube_downloader_flutter/utils/enums/video_download_status.dart';
import 'package:youtube_downloader_flutter/utils/models/video_info_model.dart';
import 'package:youtube_downloader_flutter/utils/services/show_log_service.dart';
import 'package:youtube_downloader_flutter/ui/download/ui/video_card.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadController>(
      builder: (context, controller, child) {
        controller.processLogs.listen((log) {
          if (log.type == LogType.error) {
            final errorMsg = _parseErrorMessage(log.message);
            if (context.mounted) {
              ShowLogService.showLog(context, errorMsg);
            }
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('YouTube Downloader'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.restart_alt),
                onPressed: () async {
                  final shouldReset = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Reset'),
                      content: const Text(
                          'Are you sure you want to reset the download state?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );

                  if (shouldReset == true) {
                    controller.resetDownloadState();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () async {
                  _handlePlaylistDownload(isHistoryView: true);
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()));
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputRow(controller),
                const SizedBox(height: 16),
                _buildInformation(
                  outputDir: controller.outputDir,
                  maxWorkers: controller.maxWorkers,
                ),
                const SizedBox(height: 16),
                _buildDownloadButton(controller),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (controller.isDownloading)
                      Text(
                        'Downloading: ${controller.videoInfoListForDownload.where((video) => video.status?.isDownloading ?? false).length} videos',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: VideoDownloadStatus.downloading.color),
                      ),
                    if (controller.videoInfoListForDownload
                        .where((video) => video.status?.isFinished ?? false)
                        .isNotEmpty)
                      Text(
                        'Download successful: ${controller.videoInfoListForDownload.where((video) => video.status?.isFinished ?? false).length} videos',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: VideoDownloadStatus.finished.color),
                      ),
                  ],
                ),
                (controller.videoInfoListForDownload.isNotEmpty)
                    ? Flexible(
                        child: ListView.builder(
                          itemCount: controller.videoInfoListForDownload.length,
                          itemBuilder: (context, index) => _buildVideoInfo(
                              controller.videoInfoListForDownload[index]),
                        ),
                      )
                    : const Center(
                        child: Text('No video to download'),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoInfo(VideoInfoModel videoInfo) {
    return VideoCard(
      video: videoInfo,
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
            onFieldSubmitted: (_) => controller.handleUrlInput(
                url: _urlController.text.trim(),
                playlistDownloadCallBack: () {}),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<DownloadType>(
          value: controller.downloadType,
          items: DownloadType.values
              .map((type) =>
                  DropdownMenuItem(value: type, child: Text(type.name)))
              .toList(),
          onChanged: controller.isDownloading
              ? null
              : (value) => setState(() => controller.downloadType = value!),
        ),
        const SizedBox(width: 8),
        if (controller.downloadType == DownloadType.video)
          _buildVideoQualityDropdown(controller),
        if (controller.downloadType == DownloadType.audio)
          _buildAudioFormatDropdown(controller),
      ],
    );
  }

  Widget _buildInformation({String? outputDir, int? maxWorkers}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Output directory: ${outputDir ?? 'No output directory selected'}",
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: outputDir == null ? Colors.grey : Colors.black,
          ),
        ),
        Text('Max workers: $maxWorkers'),
      ],
    );
  }

  Widget _buildVideoQualityDropdown(DownloadController controller) {
    return DropdownButton<VideoQuality>(
      value: controller.videoQuality,
      items: VideoQuality.values
          .map((quality) => DropdownMenuItem(
                value: quality,
                child: Text(quality.name),
              ))
          .toList(),
      onChanged: controller.isDownloading
          ? null
          : (value) => setState(() => controller.videoQuality = value!),
    );
  }

  Widget _buildAudioFormatDropdown(DownloadController controller) {
    return DropdownButton<AudioFormat>(
      value: controller.audioFormat,
      items: AudioFormat.values
          .map((format) => DropdownMenuItem(
                value: format,
                child: Text(format.name),
              ))
          .toList(),
      onChanged: controller.isDownloading
          ? null
          : (value) => setState(() => controller.audioFormat = value!),
    );
  }

  Widget _buildDownloadButton(DownloadController controller) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: controller.isDownloading
                ? null
                : () async {
                    await controller.handleUrlInput(
                        url: _urlController.text.trim(),
                        playlistDownloadCallBack: () {
                          _handlePlaylistDownload();
                        });
                  },
            child: controller.isDownloading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Start Download'),
          ),
        ),
        if (controller.isDownloading) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => controller.cancelDownload(),
            child: const Icon(Icons.cancel),
          ),
        ],
      ],
    );
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

  void _handlePlaylistDownload({bool isHistoryView = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PlaylistViewScreen(
                isHistoryView: isHistoryView,
              )),
    );
  }
}
