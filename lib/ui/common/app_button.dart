import 'package:flutter/material.dart';
import 'package:youtube_downloader_flutter/utils/enums/app_button_type.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final AppButtonType type;
  final Size size;

  const AppButton({
    super.key,
    this.label = '',
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = const Size(double.infinity, 48),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: type.backgroundColor(context),
          foregroundColor: type.foregroundColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 5,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class IconAppButton extends AppButton {
  final IconData icon;
  const IconAppButton({
    super.key,
    required super.onPressed,
    required this.icon,
    super.type,
    super.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: type.backgroundColor(context),
          foregroundColor: type.foregroundColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 5,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        child: Icon(icon, size: 24, color: type.foregroundColor(context)),
      ),
    );
  }
}
