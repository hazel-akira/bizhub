import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/etims_settings_service.dart';

final etimsSettingsProvider =
    StateNotifierProvider<EtimsSettingsNotifier, AsyncValue<EtimsSettings>>(
  (ref) => EtimsSettingsNotifier(),
);

/// Convenience watch for the enable flag used at sale checkout.
final etimsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(etimsSettingsProvider).valueOrNull?.enabled ?? false;
});

class EtimsSettingsNotifier extends StateNotifier<AsyncValue<EtimsSettings>> {
  EtimsSettingsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await EtimsSettingsService.instance.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final previous = current;
    state = AsyncValue.data(
      EtimsSettings(
        enabled: enabled,
        kraPin: current.kraPin,
        deviceToken: current.deviceToken,
      ),
    );

    try {
      await EtimsSettingsService.instance.setEnabled(enabled);
    } catch (e, st) {
      state = AsyncValue.data(previous);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> saveCredentials({
    required String kraPin,
    required String deviceToken,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final next = EtimsSettings(
      enabled: current.enabled,
      kraPin: kraPin.trim(),
      deviceToken: deviceToken.trim(),
    );
    state = AsyncValue.data(next);

    try {
      await EtimsSettingsService.instance.saveCredentials(
        kraPin: kraPin,
        deviceToken: deviceToken,
      );
    } catch (e, st) {
      state = AsyncValue.data(current);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
