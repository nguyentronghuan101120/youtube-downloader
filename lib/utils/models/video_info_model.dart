import 'package:json_annotation/json_annotation.dart';
import 'package:youtube_downloader_flutter/utils/enums/video_download_status.dart';

part 'video_info_model.g.dart';

@JsonSerializable()
class VideoInfoModel {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'duration')
  final int? duration;

  @JsonKey(name: 'thumbnail')
  final String? thumbnailUrl;

  @JsonKey(name: 'url')
  final String? url;

  @JsonKey(name: 'status', defaultValue: VideoDownloadStatus.notDownloaded)
  final VideoDownloadStatus? status;

  @JsonKey(name: 'output_path')
  final String? outputPath;

  @JsonKey(
    name: 'percent',
  )
  final double? percent;

  const VideoInfoModel({
    this.id,
    this.title,
    this.duration,
    this.thumbnailUrl,
    this.url,
    this.status,
    this.percent,
    this.outputPath,
  });

  factory VideoInfoModel.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$VideoInfoModelToJson(this);

  VideoInfoModel copyWith({
    String? id,
    String? title,
    int? duration,
    String? thumbnailUrl,
    String? url,
    VideoDownloadStatus? status,
    double? percent,
    String? outputPath,
  }) {
    return VideoInfoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      url: url ?? this.url,
      status: status ?? this.status,
      percent: percent ?? this.percent,
      outputPath: outputPath ?? this.outputPath,
    );
  }
}
