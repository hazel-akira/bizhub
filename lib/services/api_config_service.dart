import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart' show defaultApiBaseUrl;

/// Persists a custom API base URL (overrides platform default).
class ApiConfigService {
  static const _urlKey = 'akira_api_base_url';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_urlKey)?.trim();
    if (saved != null && saved.isNotEmpty) {
      return saved.replaceAll(RegExp(r'/+$'), '');
    }
    return defaultApiBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.isEmpty) {
      await prefs.remove(_urlKey);
    } else {
      await prefs.setString(_urlKey, trimmed);
    }
  }

  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_urlKey);
  }
}
