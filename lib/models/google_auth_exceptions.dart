class GoogleRegistrationRequiredException implements Exception {
  const GoogleRegistrationRequiredException({
    required this.email,
    required this.name,
  });

  final String email;
  final String name;

  @override
  String toString() =>
      'No account found for this Google email. Complete business setup to register.';
}

/// Android/iOS Google Cloud Console is missing package name, SHA-1, or Web client.
class GoogleAuthConsoleSetupException implements Exception {
  const GoogleAuthConsoleSetupException({
    this.details,
  });

  final String? details;

  static const androidPackage = 'app.akirabizhub.pos';

  /// Debug keystore SHA-1 for `flutter run` on this dev machine.
  static const debugSha1 =
      '09:AD:A7:5C:1C:41:CD:6C:C8:8D:00:34:8D:A5:D8:A1:3D:CC:5B:0B';

  @override
  String toString() => 'Google Cloud Console is not set up for this app. '
      'Create an Android OAuth client with package $androidPackage '
      'and SHA-1 $debugSha1 in the same project as your Web client ID. '
      'See docs/GOOGLE_OAUTH_SETUP.md';
}
