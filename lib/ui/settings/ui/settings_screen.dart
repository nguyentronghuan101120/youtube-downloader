import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_flutter/ui/common/app_button.dart';
import 'package:youtube_downloader_flutter/ui/common/app_dropdown.dart';
import 'package:youtube_downloader_flutter/ui/settings/controller/settings_controller.dart';
import 'package:youtube_downloader_flutter/utils/services/show_log_service.dart';

class SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget subtitle;
  final VoidCallback? onTap;

  const SettingsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  overflow: TextOverflow.ellipsis)),
          subtitle: subtitle,
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsController(),
      child: Consumer<SettingsController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Settings'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SettingsCard(
                    icon: Icons.folder,
                    title: 'Output Directory',
                    subtitle: Text(
                      controller.tempOutputDir ?? 'No directory selected',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: controller.pickOutputDirectory,
                  ),
                  const SizedBox(height: 16),
                  SettingsCard(
                    icon: Icons.download,
                    title: 'Max Concurrent Downloads',
                    subtitle: AppDropdown<int>(
                      value: controller.tempMaxWorkers,
                      items: controller.workerOptions
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text('$value workers'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) controller.setMaxWorkers(value);
                      },
                    ),
                  ),
                  const Spacer(),
                  AppButton(
                    label: 'Submit',
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Are you sure?'),
                          content: const Text('Settings will be updated.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final success =
                                    await controller.submitChanges();
                                if (context.mounted) {
                                  if (success) {
                                    Navigator.pop(context);
                                    Navigator.pop(context, true);
                                  } else {
                                    ShowLogService.showLog(
                                        context, 'Failed to save settings');
                                  }
                                }
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
