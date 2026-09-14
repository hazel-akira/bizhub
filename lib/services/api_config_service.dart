import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';

/// Resolves the API base URL and clears leftover custom hosts from older builds.
class ApiConfigService {
  static const _urlKey = 'akira_api_base_url';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_urlKey);
    if (saved != null && saved.isNotEmpty) {
      await prefs.remove(_urlKey);
    }
    return defaultApiBaseUrl;
  }
}
