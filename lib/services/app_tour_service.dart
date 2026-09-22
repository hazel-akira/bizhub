import 'package:shared_preferences/shared_preferences.dart';

/// First-run swipe intro + in-app coach tour completion flags.
class AppTourService {
  AppTourService._();
  static final AppTourService instance = AppTourService._();

  static const _introKey = 'app_tour_intro_completed';
  static const _coachKey = 'app_tour_coach_completed';

  Future<bool> hasCompletedIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_introKey) ?? false;
  }

  Future<void> markIntroCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introKey, true);
  }

  Future<bool> hasCompletedCoachTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_coachKey) ?? false;
  }

  Future<void> markCoachTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_coachKey, true);
  }

  /// Clears both so Settings "Replay" can run the full experience again.
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_introKey);
    await prefs.remove(_coachKey);
  }

  Future<void> resetCoachTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coachKey);
  }
}
