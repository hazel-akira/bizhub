import 'package:shared_preferences/shared_preferences.dart';

class EtimsSettings {
  const EtimsSettings({
    required this.enabled,
    required this.kraPin,
    required this.deviceToken,
  });

  final bool enabled;
  final String kraPin;
  final String deviceToken;

  bool get hasCredentials =>
      kraPin.trim().isNotEmpty && deviceToken.trim().isNotEmpty;
}

/// Persists KRA eTIMS integration preferences for the store.
class EtimsSettingsService {
  EtimsSettingsService._();
  static final EtimsSettingsService instance = EtimsSettingsService._();

  static const _enabledKey = 'etims_integration_enabled';
  static const _kraPinKey = 'etims_kra_pin';
  static const _deviceTokenKey = 'etims_device_token';

  Future<EtimsSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return EtimsSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      kraPin: prefs.getString(_kraPinKey) ?? '',
      deviceToken: prefs.getString(_deviceTokenKey) ?? '',
    );
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> saveCredentials({
    required String kraPin,
    required String deviceToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kraPinKey, kraPin.trim());
    await prefs.setString(_deviceTokenKey, deviceToken.trim());
  }

  Future<void> saveSettings(EtimsSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setString(_kraPinKey, settings.kraPin.trim());
    await prefs.setString(_deviceTokenKey, settings.deviceToken.trim());
  }
}
