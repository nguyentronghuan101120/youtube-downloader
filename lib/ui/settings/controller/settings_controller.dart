import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:youtube_downloader_flutter/utils/services/local_storage_service.dart';

class SettingsController extends ChangeNotifier {
  String? _outputDir;
  int? _maxWorkers = 4;
  final LocalStorageService _localStorageService = LocalStorageService();

  // Biến tạm thời để theo dõi thay đổi trước khi submit
  String? _tempOutputDir;
  int? _tempMaxWorkers;

  String? get outputDir => _outputDir;
  int? get maxWorkers => _maxWorkers;
  String? get tempOutputDir => _tempOutputDir;
  int? get tempMaxWorkers => _tempMaxWorkers;

  // Getter động để tạo danh sách workerOptions dựa trên số lõi CPU
  List<int> get workerOptions {
    final int cpuCores = Platform.numberOfProcessors; // Lấy số lõi CPU của thiết bị
    const int maxAllowedWorkers = 16; // Giới hạn tối đa hợp lý
    final int maxWorkersForDevice = cpuCores.clamp(1, maxAllowedWorkers); // Giới hạn từ 1 đến maxAllowedWorkers

    // Tạo danh sách các tùy chọn dựa trên số lõi CPU (ví dụ: 1, 2, 4, 8, ... đến maxWorkersForDevice)
    List<int> options = [];
    int value = 1;
    while (value <= maxWorkersForDevice) {
      options.add(value);
      value *= 2; // Tăng theo cấp số nhân (1, 2, 4, 8, ...)
    }
    return options;
  }

  SettingsController() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      _outputDir = await _localStorageService.getOutputDir();
      _maxWorkers = await _localStorageService.getMaxWorkers();
      _tempOutputDir = _outputDir;
      _tempMaxWorkers = _maxWorkers ?? 4;

      if (_outputDir == null) {
        await _setDefaultDownloadDirectory();
        _tempOutputDir = _outputDir;
      }
      if (_maxWorkers == null || !workerOptions.contains(_maxWorkers)) {
        _maxWorkers = workerOptions.isNotEmpty ? workerOptions.last : 4; // Chọn giá trị lớn nhất hợp lệ
        _tempMaxWorkers = _maxWorkers;
        await _localStorageService.saveMaxWorkers(_maxWorkers!);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
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
      _tempOutputDir = selectedDir;
      notifyListeners();
    }
  }

  void setMaxWorkers(int value) {
    if (workerOptions.contains(value)) {
      _tempMaxWorkers = value;
      notifyListeners();
    }
  }

  Future<bool> submitChanges() async {
    try {
      if (_tempOutputDir != _outputDir) {
        _outputDir = _tempOutputDir;
        await _localStorageService.saveOutputDir(_outputDir!);
      }
      if (_tempMaxWorkers != _maxWorkers && workerOptions.contains(_tempMaxWorkers)) {
        _maxWorkers = _tempMaxWorkers;
        await _localStorageService.saveMaxWorkers(_maxWorkers!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving settings: $e');
      return false;
    }
  }

  void resetTempValues() {
    _tempOutputDir = _outputDir;
    _tempMaxWorkers = _maxWorkers;
    notifyListeners();
  }
}