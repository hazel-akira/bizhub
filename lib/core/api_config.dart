const _buildTimeApiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// Production Laravel API on Render. Override with `--dart-define=API_BASE_URL=...`.
const productionApiBaseUrl = 'https://akira-flow-api.onrender.com';

String sanitizeApiBaseUrl(String value) =>
    value.trim().replaceAll(RegExp(r'/+$'), '');

/// Active API host. Uses `--dart-define=API_BASE_URL` when set, otherwise Render.
String get defaultApiBaseUrl {
  final buildTimeUrl = sanitizeApiBaseUrl(_buildTimeApiBaseUrl);
  if (buildTimeUrl.isNotEmpty) {
    return buildTimeUrl;
  }
  return productionApiBaseUrl;
}

/// Sync fallback before prefs load; prefer ApiConfigService.getBaseUrl().
String get apiBaseUrl => defaultApiBaseUrl;
