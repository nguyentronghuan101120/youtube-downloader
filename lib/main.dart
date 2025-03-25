import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_flutter/ui/download/controller/download_controller.dart';
import 'package:youtube_downloader_flutter/ui/download/ui/download_screen.dart';
import 'package:youtube_downloader_flutter/ui/settings/controller/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _initializeSettings(
      SettingsController settingsController) async {
    await settingsController.loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DownloadController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: Builder(
        builder: (context) {
          final settingsController = context.read<SettingsController>();
          return FutureBuilder(
            future: _initializeSettings(settingsController),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Hiển thị màn hình chờ trong khi load settings
                return const MaterialApp(
                  home: Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                );
              } else if (snapshot.hasError) {
                // Xử lý lỗi nếu có
                return MaterialApp(
                  home: Scaffold(
                    body: Center(child: Text('Error: ${snapshot.error}')),
                  ),
                );
              } else {
                // Khi hoàn tất, hiển thị ứng dụng chính
                return MaterialApp(
                  title: 'YouTube Downloader',
                  theme: ThemeData(
                    colorScheme:
                        ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                    useMaterial3: true,
                  ),
                  debugShowCheckedModeBanner: false,
                  home: const DownloadScreen(),
                );
              }
            },
          );
        },
      ),
    );
  }
}
