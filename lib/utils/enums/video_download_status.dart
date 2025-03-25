import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

enum VideoDownloadStatus {
  @JsonValue('downloading')
  downloading,
  @JsonValue('finished')
  finished,
  @JsonValue('not_downloaded')
  notDownloaded,
}

extension VideoDownloadStatusExtension on VideoDownloadStatus {
  Widget get icon => this == VideoDownloadStatus.finished
      ? const Icon(Icons.download_done, color: Colors.green)
      : const Icon(Icons.download, color: Colors.blue);

  bool get isDownloading => this == VideoDownloadStatus.downloading;
  bool get isFinished => this == VideoDownloadStatus.finished;
  bool get isNotDownloaded => this == VideoDownloadStatus.notDownloaded;

  String get title => switch (this) {
        VideoDownloadStatus.downloading => 'Downloading',
        VideoDownloadStatus.finished => 'Finished',
        VideoDownloadStatus.notDownloaded => 'Not Downloaded',
      };

  Color get color => switch (this) {
        VideoDownloadStatus.downloading => Colors.blue,
        VideoDownloadStatus.finished => Colors.green,
        VideoDownloadStatus.notDownloaded => Colors.amber,
      };
}
