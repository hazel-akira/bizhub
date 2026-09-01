import 'package:flutter/material.dart';

import '../core/google_auth_config.dart';
import '../models/google_auth_exceptions.dart';

Future<void> showGoogleSignInSetupDialog(BuildContext context) {
  final webClientId = googleWebClientId ?? '(not set)';

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Google Sign-In setup needed'),
      content: SingleChildScrollView(
        child: Text(
          'Error 28444 means Google Cloud Console is missing the Android OAuth client.\n\n'
          'In the SAME Google Cloud project as your Web client:\n\n'
          '1. APIs & Services → Credentials → Create OAuth client ID\n'
          '2. Type: Android\n'
          '3. Package name: ${GoogleAuthConsoleSetupException.androidPackage}\n'
          '4. SHA-1 (debug): ${GoogleAuthConsoleSetupException.debugSha1}\n'
          '5. Keep your existing Web client ID:\n$webClientId\n\n'
          'Also check OAuth consent screen → add your Gmail as a test user.\n\n'
          'After saving, wait 5 minutes, then uninstall the app and run again.\n\n'
          'Full guide: docs/GOOGLE_OAUTH_SETUP.md',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
