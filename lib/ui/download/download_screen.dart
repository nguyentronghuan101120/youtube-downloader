import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_flutter/ui/download/download_controller.dart';
import 'package:youtube_downloader_flutter/utils/download_config.dart';
import 'package:youtube_downloader_flutter/utils/log_model.dart';
import 'package:youtube_downloader_flutter/utils/video_info_model.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DownloadType _downloadType = DownloadType.audio;
  AudioFormat _audioFormat = AudioFormat.mp3;
  VideoQuality _videoQuality = VideoQuality.fullHd;

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadController>(
      builder: (context, controller, child) {
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
                if (controller.videoInfo != null) ...[
                  _buildVideoInfo(controller.videoInfo!),
                  const SizedBox(height: 16),
                ],
                _buildOutputDirRow(controller),
                const SizedBox(height: 16),
                _buildDownloadButton(controller),
                const SizedBox(height: 16),
                _buildLogList(controller),
                if (controller.downloadedFilePath != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Download saved at: ${controller.downloadedFilePath}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoInfo(VideoInfoModel videoInfo) {
    final duration = Duration(seconds: videoInfo.duration);
    final durationStr =
        "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (videoInfo.thumbnailUrl.isNotEmpty)
              Image.network(
                videoInfo.thumbnailUrl,
                width: 100,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    videoInfo.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text("Duration: $durationStr"),
                ],
              ),
            ),
          ],
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
            onFieldSubmitted: (value) {
              controller.youtubeDownloader(value, _downloadType, _audioFormat,
                  _videoQuality, controller.outputDir);
            },
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<DownloadType>(
          value: _downloadType,
          items: DownloadType.values
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name.capitalize()),
                  ))
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
                : () => controller.youtubeDownloader(
                      _urlController.text,
                      _downloadType,
                      _audioFormat,
                      _videoQuality,
                      controller.outputDir,
                    ),
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

  Widget _buildLogList(DownloadController controller) {
    if (controller.processLogs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Expanded(
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        controller: _scrollController,
        itemCount: controller.processLogs.length,
        itemBuilder: (context, index) {
          return SelectableText(
            controller.processLogs[index].message,
            style: TextStyle(color: controller.processLogs[index].type.color),
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}
