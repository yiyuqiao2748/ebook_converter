import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_info.dart';

class StorageService {
  static const String _historyKey = 'conversion_history';
  static const String _settingsKey = 'app_settings';

  static Future<List<BookInfo>> getConversionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);

    if (jsonString == null) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => BookInfo.fromJson(json)).toList();
  }

  static Future<void> saveToHistory(BookInfo book) async {
    final history = await getConversionHistory();
    history.insert(0, book);

    // 最多保留50条历史记录
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(history.map((b) => b.toJson()).toList());
    await prefs.setString(_historyKey, jsonString);
  }

  static Future<void> removeFromHistory(BookInfo book) async {
    final history = await getConversionHistory();
    history.removeWhere((item) =>
      item.title == book.title &&
      item.createdAt == book.createdAt
    );

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(history.map((b) => b.toJson()).toList());
    await prefs.setString(_historyKey, jsonString);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  static Future<Map<String, dynamic>> getAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString == null) {
      return {
        'theme_mode': 'system',
        'default_chapter_mode': ChapterDetectionMode.auto.index,
        'default_separator': '\n\n\n',
        'auto_fill_title': true,
        'save_to_history': true,
      };
    }

    return jsonDecode(jsonString);
  }

  static Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings);
    await prefs.setString(_settingsKey, jsonString);
  }

  static Future<void> saveThemeMode(String themeMode) async {
    final settings = await getAppSettings();
    settings['theme_mode'] = themeMode;
    await saveAppSettings(settings);
  }

  static Future<String> getThemeMode() async {
    final settings = await getAppSettings();
    return settings['theme_mode'] as String? ?? 'system';
  }

  static Future<ChapterDetectionMode> getDefaultChapterMode() async {
    final settings = await getAppSettings();
    final index = settings['default_chapter_mode'] as int? ?? ChapterDetectionMode.auto.index;
    return ChapterDetectionMode.values[index];
  }

  static Future<void> saveDefaultChapterMode(ChapterDetectionMode mode) async {
    final settings = await getAppSettings();
    settings['default_chapter_mode'] = mode.index;
    await saveAppSettings(settings);
  }

  static Future<String> getDefaultSeparator() async {
    final settings = await getAppSettings();
    return settings['default_separator'] as String? ?? '\n\n\n';
  }

  static Future<void> saveDefaultSeparator(String separator) async {
    final settings = await getAppSettings();
    settings['default_separator'] = separator;
    await saveAppSettings(settings);
  }

  static Future<bool> getAutoFillTitle() async {
    final settings = await getAppSettings();
    return settings['auto_fill_title'] as bool? ?? true;
  }

  static Future<void> saveAutoFillTitle(bool value) async {
    final settings = await getAppSettings();
    settings['auto_fill_title'] = value;
    await saveAppSettings(settings);
  }

  static Future<bool> getSaveToHistory() async {
    final settings = await getAppSettings();
    return settings['save_to_history'] as bool? ?? true;
  }

  static Future<void> saveSaveToHistory(bool value) async {
    final settings = await getAppSettings();
    settings['save_to_history'] = value;
    await saveAppSettings(settings);
  }
}
