import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_flutter/ui/settings/controller/settings_controller.dart';

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Output Directory',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          controller.outputDir ?? 'No directory selected',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: controller.pickOutputDirectory,
                        child: const Text('Choose'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Max Concurrent Downloads',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    value: controller.maxWorkers,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
