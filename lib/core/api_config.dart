import 'dart:io';

import 'package:flutter/foundation.dart';

const _buildTimeApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String _sanitizeUrl(String value) => value.trim().replaceAll(RegExp(r'/+$'), '');

/// Platform default — use [ApiConfigService.getBaseUrl] for the active URL.
String get defaultApiBaseUrl {
  final buildTimeUrl = _sanitizeUrl(_buildTimeApiBaseUrl);
  if (buildTimeUrl.isNotEmpty) {
    return buildTimeUrl;
  }

  if (kReleaseMode) {
    // Production builds should pass API_BASE_URL via --dart-define.
    return 'https://api.example.com';
  }

  if (kIsWeb) {
    return 'http://127.0.0.1:8000';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}

/// Sync fallback before prefs load; prefer ApiConfigService.getBaseUrl().
String get apiBaseUrl => defaultApiBaseUrl;
