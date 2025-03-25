import 'package:flutter/material.dart';

enum AppButtonType {
  primary,
  secondary,
  danger,
}

extension AppButtonTypeExtension on AppButtonType {
  Color backgroundColor(BuildContext context) {
    return switch (this) {
      AppButtonType.primary => Theme.of(context).colorScheme.primary,
      AppButtonType.secondary => Theme.of(context).colorScheme.secondary,
      AppButtonType.danger => Theme.of(context).colorScheme.error,
    };
  }

  Color foregroundColor(BuildContext context) {
    return switch (this) {
      AppButtonType.primary => Theme.of(context).colorScheme.onPrimary,
      AppButtonType.secondary => Theme.of(context).colorScheme.onSecondary,
      AppButtonType.danger => Theme.of(context).colorScheme.onError,
    };
  }

  Color iconColor(BuildContext context) {
    return switch (this) {
      AppButtonType.primary => Theme.of(context).colorScheme.onPrimary,
      AppButtonType.secondary => Theme.of(context).colorScheme.onSecondary,
      AppButtonType.danger => Theme.of(context).colorScheme.onError,
    };
  }
}
