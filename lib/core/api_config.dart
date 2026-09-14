const _buildTimeApiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// Production Laravel API on Render. Override with `--dart-define=API_BASE_URL=...`.
const productionApiBaseUrl = 'https://akira-flow-api.onrender.com';

String sanitizeApiBaseUrl(String value) =>
    value.trim().replaceAll(RegExp(r'/+$'), '');

/// Retired hosts that must never be used, including leftover prefs from older builds.
bool isRetiredApiBaseUrl(String value) {
  final sanitized = sanitizeApiBaseUrl(value);
  if (sanitized.isEmpty) return false;

  final parsed = Uri.tryParse(sanitized);
  final host = (parsed?.host.isNotEmpty == true ? parsed!.host : sanitized)
      .toLowerCase();

  return host == 'akirabites.shop' || host.endsWith('.akirabites.shop');
}

/// Active API host. Uses `--dart-define=API_BASE_URL` when set, otherwise Render.
String get defaultApiBaseUrl {
  final buildTimeUrl = sanitizeApiBaseUrl(_buildTimeApiBaseUrl);
  if (buildTimeUrl.isNotEmpty && !isRetiredApiBaseUrl(buildTimeUrl)) {
    return buildTimeUrl;
  }
  return productionApiBaseUrl;
}

/// Sync fallback before prefs load; prefer ApiConfigService.getBaseUrl().
String get apiBaseUrl => defaultApiBaseUrl;
