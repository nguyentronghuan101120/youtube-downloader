import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:youtube_downloader_flutter/utils/services/local_storage_service.dart';

class SettingsController extends ChangeNotifier {
  String? _outputDir;
  int? _maxWorkers = 4;
  final List<int> _workerOptions = [1, 2, 4, 8, 16];
  final LocalStorageService _localStorageService = LocalStorageService();

  String? get outputDir => _outputDir;
  int? get maxWorkers => _maxWorkers;
  List<int> get workerOptions => _workerOptions;

  SettingsController() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _outputDir = await _localStorageService.getOutputDir();
    _maxWorkers = await _localStorageService.getMaxWorkers();

    if (_outputDir == null) {
      await _setDefaultDownloadDirectory();
    }

    if (_maxWorkers == null) {
      _maxWorkers = 4;
      await _localStorageService.saveMaxWorkers(_maxWorkers!);
    }
    notifyListeners();
  }

  Future<void> _setDefaultDownloadDirectory() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          await pickOutputDirectory();
          return;
        }
      }
      Directory? downloadsDir = await getDownloadsDirectory();
      _outputDir = downloadsDir != null
          ? "${downloadsDir.path}/youtube-downloader"
          : (await getExternalStorageDirectory())?.path;
      Directory(_outputDir!).createSync(recursive: true);
      await _localStorageService.saveOutputDir(_outputDir!);
    } catch (e) {
      _outputDir = null;
    }
    notifyListeners();
  }

  Future<void> pickOutputDirectory() async {
    String? selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir != null) {
      _outputDir = selectedDir;
      await _localStorageService.saveOutputDir(_outputDir!);
      notifyListeners();
    }
  }

  void setMaxWorkers(int value) {
    _maxWorkers = value;
    _localStorageService.saveMaxWorkers(_maxWorkers!);
    notifyListeners();
  }
}
