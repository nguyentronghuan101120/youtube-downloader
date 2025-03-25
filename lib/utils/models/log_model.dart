import 'package:flutter/material.dart';
import 'package:youtube_downloader_flutter/utils/enums/log_type.dart';

class LogModel {
  final String message;
  final LogType type;

  LogModel(this.message, this.type);
}

extension LogTypeExtension on LogType {
  Color get color => switch (this) {
        LogType.info => Colors.blue,
        LogType.error => Colors.red,
        LogType.warning => Colors.green,
        LogType.success => Colors.green,
      };
}
