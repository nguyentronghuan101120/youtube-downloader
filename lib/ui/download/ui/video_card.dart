import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_downloader_flutter/utils/enums/video_download_status.dart';
import 'package:youtube_downloader_flutter/utils/models/video_info_model.dart';

class VideoCard extends StatelessWidget {
  final VideoInfoModel video;
  final bool isSelected;
  final VoidCallback? onToggle;

  const VideoCard({
    super.key,
    required this.video,
    this.isSelected = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle?.call(),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    if (onToggle != null) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => onToggle?.call(),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (video.thumbnailUrl != null &&
                        video.thumbnailUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildThumbnail(),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title ?? 'Untitled',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                              "Duration: ${_formatDuration(video.duration ?? 0)}"),
                          if (video.status != null)
                            Text(
                              "Status: ${video.status!.title}",
                              style: TextStyle(
                                color: video.status!.color,
                              ),
                            ),
                          if (video.outputPath != null)
                            Text("Downloaded to: ${video.outputPath}"),
                        ],
                      ),
                    ),
                    if (video.status!.isDownloading)
                      Text(
                        "${video.percent ?? 0}%",
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (video.status != null) video.status!.icon,
                  ],
                ),
                if (video.status!.isDownloading && onToggle == null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: video.percent != null ? video.percent! / 100 : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildThumbnail() {
    if (video.thumbnailUrl == null || video.thumbnailUrl!.isEmpty) {
      return const Icon(Icons.video_library, size: 45);
    }

    if (Platform.isMacOS) {
      return Image.network(
        video.thumbnailUrl!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 45),
      );
    }

    return CachedNetworkImage(
      imageUrl: video.thumbnailUrl!,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image, size: 45),
    );
  }
}

extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}
