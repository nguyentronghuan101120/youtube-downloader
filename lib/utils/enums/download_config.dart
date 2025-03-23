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
  String get quality => switch (this) {
        VideoQuality.sd => '480p',
        VideoQuality.hd => '720p',
        VideoQuality.fullHd => '1080p',
        VideoQuality.qhd => '1440p',
        VideoQuality.uhd => '4k',
      };
}

enum AudioFormat {
  mp3,
  flac,
  m4a,
  wav,
}
