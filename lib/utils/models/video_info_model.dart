import 'dart:convert';

class VideoInfoModel {
  final String? id;
  final String? title;
  final int? duration;
  final String? thumbnailUrl;
  final String? url;
  final String? status;
  final double? percent;

  const VideoInfoModel({
    this.id,
    this.title,
    this.duration,
    this.thumbnailUrl,
    this.url,
    this.status,
    this.percent,
  });

  factory VideoInfoModel.fromJson(Map<String, dynamic> json) {
    return VideoInfoModel(
      id: json['id'],
      title: json['title'],
      duration: json['duration'],
      thumbnailUrl: json['thumbnail'],
      url: json['url'],
      status: json['status'],
      percent: json["percent"] != null
          ? double.tryParse(json["percent"].replaceAll("%", ""))
          : null,
    );
  }

  VideoInfoModel copyWith({
    String? id,
    String? title,
    int? duration,
    String? thumbnailUrl,
    String? url,
    String? status,
    double? percent,
  }) {
    return VideoInfoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      url: url ?? this.url,
      status: status ?? this.status,
      percent: percent ?? this.percent,
    );
  }
}
