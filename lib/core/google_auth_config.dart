const _buildTimeGoogleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

/// Default Web client ID (override with --dart-define=GOOGLE_WEB_CLIENT_ID=...).
const _defaultGoogleWebClientId =
    '445326255543-m8hh5al6s529h1c97h4v1ueif4e0hdgd.apps.googleusercontent.com';

/// OAuth 2.0 Web client ID from Google Cloud Console.
/// Required for Google Sign-In on Android/iOS to return an ID token.
String? get googleWebClientId {
  final fromDefine = _buildTimeGoogleWebClientId.trim();
  if (fromDefine.isNotEmpty) return fromDefine;
  return _defaultGoogleWebClientId;
}

bool get isGoogleSignInConfigured => googleWebClientId != null;
