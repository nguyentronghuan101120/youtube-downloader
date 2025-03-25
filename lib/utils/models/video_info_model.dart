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

  @JsonKey(name: 'status', defaultValue: VideoDownloadStatus.downloading)
  final VideoDownloadStatus? status;

  @JsonKey(name: 'output_path')
  final String? outputPath;

  @JsonKey(
    name: 'percent',
    fromJson: _percentFromJson, // Hàm tùy chỉnh để parse percent
    toJson: _percentToJson, // Hàm tùy chỉnh để serialize percent
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

  // Hàm tùy chỉnh để parse percent từ JSON
  static double? _percentFromJson(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll("%", ""));
    }
    return null;
  }

  // Hàm tùy chỉnh để serialize percent sang JSON
  static dynamic _percentToJson(double? value) {
    return value; // Giữ nguyên giá trị double, không thêm "%" khi serialize
  }
}
