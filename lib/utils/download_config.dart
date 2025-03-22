enum DownloadType {
  video,
  audio,
}

enum VideoQuality {
  sd,
  hd,
  fullHd,
  qhd,
  uhd,
}

extension VideoQualityExtension on VideoQuality {
  String get value => switch (this) {
        VideoQuality.sd => '360p',
        VideoQuality.hd => '480p',
        VideoQuality.fullHd => '720p',
        VideoQuality.qhd => '1080p',
        VideoQuality.uhd => '4k',
      };
}

enum AudioFormat {
  mp3,
  flac,
  aac,
  wav,
}
