import 'package:flutter/material.dart';

class LogModel {
  final String message;
  final LogType type;

  LogModel(this.message, this.type);
}

enum LogType {
  info,
  error,
  warning,
  success,
}

extension LogTypeExtension on LogType {
  Color get color => switch (this) {
        LogType.info => Colors.blue,
        LogType.error => Colors.red,
        LogType.warning => Colors.green,
        LogType.success => Colors.green,
      };
}
