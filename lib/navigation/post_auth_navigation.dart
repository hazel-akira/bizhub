import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/app_intro_screen.dart';
import '../services/app_tour_service.dart';

/// After login / splash auth: show swipe intro once, then the main app.
Future<void> navigateAfterAuth(
  BuildContext context, {
  bool clearStack = false,
}) async {
  final introDone = await AppTourService.instance.hasCompletedIntro();
  if (!context.mounted) return;

  final route = MaterialPageRoute<void>(
    builder: (_) => introDone
        ? const MainNavScreen()
        : AppIntroScreen(
            nextBuilder: (_) => const MainNavScreen(),
          ),
  );

  if (clearStack) {
    Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
  } else {
    Navigator.of(context).pushReplacement(route);
  }
}
