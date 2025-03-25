import 'package:flutter/material.dart';

class ShowLogService {
  static void showLog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
