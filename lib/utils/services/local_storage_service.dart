import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_downloader_flutter/utils/enums/local_storage_key.dart';
import 'package:youtube_downloader_flutter/utils/models/video_info_model.dart';

class LocalStorageService {
  // Singleton pattern để đảm bảo chỉ có một instance của SharedPreferences
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  Future<SharedPreferences> _getPrefs() async =>
      await SharedPreferences.getInstance();

  // Settings-related methods
  Future<void> saveOutputDir(String outputDir) async {
    final prefs = await _getPrefs();
    await prefs.setString(LocalStorageKey.outputDir.name, outputDir);
  }

  Future<String?> getOutputDir() async {
    final prefs = await _getPrefs();
    return prefs.getString(LocalStorageKey.outputDir.name);
  }

  Future<void> saveMaxWorkers(int maxWorkers) async {
    final prefs = await _getPrefs();
    await prefs.setInt(LocalStorageKey.maxWorkers.name, maxWorkers);
  }

  Future<int?> getMaxWorkers() async {
    final prefs = await _getPrefs();
    return prefs.getInt(LocalStorageKey.maxWorkers.name);
  }

  Future<void> saveHistory(List<VideoInfoModel> history) async {
    final prefs = await _getPrefs();
    final historyJson = jsonEncode(history.map((v) => v.toJson()).toList());
    await prefs.setString(LocalStorageKey.downloadHistory.name, historyJson);
  }

  Future<List<VideoInfoModel>> getHistory() async {
    final prefs = await _getPrefs();
    final historyJson = prefs.getString(LocalStorageKey.downloadHistory.name);
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded.map((item) => VideoInfoModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> clearHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(LocalStorageKey.downloadHistory.name);
  }

  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}
