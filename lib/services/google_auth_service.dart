import 'package:google_sign_in/google_sign_in.dart';

import '../core/google_auth_config.dart';

class GoogleSignInAccountInfo {
  const GoogleSignInAccountInfo({
    required this.idToken,
    required this.email,
    required this.displayName,
  });

  final String idToken;
  final String email;
  final String displayName;
}

class GoogleAuthCancelledException implements Exception {
  const GoogleAuthCancelledException();

  @override
  String toString() => 'Google sign-in was cancelled.';
}

class GoogleAuthNotConfiguredException implements Exception {
  const GoogleAuthNotConfiguredException();

  @override
  String toString() =>
      'Google Sign-In is not configured. Set GOOGLE_WEB_CLIENT_ID.';
}

class GoogleAuthService {
  Future<void>? _initFuture;

  Future<void> _ensureInitialized() {
    final webClientId = googleWebClientId;
    if (webClientId == null) {
      throw const GoogleAuthNotConfiguredException();
    }

    return _initFuture ??= GoogleSignIn.instance.initialize(
      serverClientId: webClientId,
    );
  }

  Future<GoogleSignInAccountInfo> signIn() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();

    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google did not return an ID token. Check GOOGLE_WEB_CLIENT_ID.',
        );
      }

      return GoogleSignInAccountInfo(
        idToken: idToken,
        email: account.email.trim(),
        displayName: account.displayName?.trim().isNotEmpty == true
            ? account.displayName!.trim()
            : account.email.split('@').first,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const GoogleAuthCancelledException();
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_initFuture == null) return;
    await GoogleSignIn.instance.signOut();
  }
}
