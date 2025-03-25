import 'package:flutter/material.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.isEnabled = true,
  });

  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final T? value;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isEnabled,
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isEnabled ? null : Theme.of(context).disabledColor,
            ),
        isDense: true,
      ),
    );
  }
}
