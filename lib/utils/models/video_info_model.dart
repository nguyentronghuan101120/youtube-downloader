import 'package:json_annotation/json_annotation.dart';
import 'package:youtube_downloader_flutter/utils/enums/video_download_status.dart';

part 'video_info_model.g.dart';

@JsonSerializable()
class VideoInfoModel {
  final String id;
  final String title;
  final String? url;
  final int duration;
  final String? thumbnailUrl;
  final double? percent;
  final VideoDownloadStatus? status;
  final String? outputPath;

  VideoInfoModel({
    required this.id,
    required this.title,
    this.url,
    required this.duration,
    this.thumbnailUrl,
    this.percent,
    this.status,
    this.outputPath,
  });

  factory VideoInfoModel.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$VideoInfoModelToJson(this);

  VideoInfoModel copyWith({
    String? id,
    String? title,
    String? url,
    int? duration,
    String? thumbnailUrl,
    double? percent,
    VideoDownloadStatus? status,
    String? outputPath,
  }) {
    return VideoInfoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      percent: percent ?? this.percent,
      status: status ?? this.status,
      outputPath: outputPath ?? this.outputPath,
    );
  }
}
