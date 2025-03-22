class VideoInfoModel {
  final String title;
  final int duration;
  final String thumbnailUrl;
  final String url;

  VideoInfoModel({
    required this.title,
    required this.duration,
    required this.thumbnailUrl,
    required this.url,
  });

  factory VideoInfoModel.fromJson(Map<String, dynamic> json) {
    return VideoInfoModel(
      title: json['title'] ?? 'Untitled',
      duration: json['duration'] ?? 0,
      thumbnailUrl: json['thumbnail'] ?? '',
      url: json['url'] ?? '',
    );
  }
}
