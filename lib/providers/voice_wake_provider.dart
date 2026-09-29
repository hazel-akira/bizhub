import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/voice_wake_phrases.dart';
import 'assistant_provider.dart';
import 'auth_provider.dart';

void _agentLog({
  required String location,
  required String message,
  required String hypothesisId,
  Map<String, Object?> data = const {},
}) {
  // #region agent log
  final payload = <String, Object?>{
    'sessionId': 'b48b82',
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  debugPrint('AGENT_LOG ${jsonEncode(payload)}');
  http
      .post(
        Uri.parse(
          'http://127.0.0.1:7337/ingest/ed1b7cbf-e433-4e26-8c0b-00b9389f928c',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': 'b48b82',
        },
        body: jsonEncode(payload),
      )
      .catchError((_) => http.Response('', 599));
  // #endregion
}

enum VoiceWakePhase { off, sleeping, armed, listening, processing }

class VoiceWakeState {
  const VoiceWakeState({
    this.enabled = true,
    this.allowed = false,
    this.available = true,
    this.phase = VoiceWakePhase.off,
    this.partialHeard = '',
    this.lastReply,
    this.error,
  });

  final bool enabled;
  final bool allowed;
  final bool available;
  final VoiceWakePhase phase;
  final String partialHeard;
  final String? lastReply;
  final String? error;

  bool get isActive =>
      allowed &&
      enabled &&
      available &&
      phase != VoiceWakePhase.off &&
      phase != VoiceWakePhase.processing;

  VoiceWakeState copyWith({
    bool? enabled,
    bool? allowed,
    bool? available,
    VoiceWakePhase? phase,
    String? partialHeard,
    String? lastReply,
    String? error,
    bool clearReply = false,
    bool clearError = false,
  }) {
    return VoiceWakeState(
      enabled: enabled ?? this.enabled,
      allowed: allowed ?? this.allowed,
      available: available ?? this.available,
      phase: phase ?? this.phase,
      partialHeard: partialHeard ?? this.partialHeard,
      lastReply: clearReply ? null : (lastReply ?? this.lastReply),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class VoiceWakeNotifier extends StateNotifier<VoiceWakeState> {
  VoiceWakeNotifier(this._ref) : super(const VoiceWakeState()) {
    _loadPref();
  }

  static const _prefKey = 'voice_wake_enabled';

  final Ref _ref;
  final SpeechToText _speech = SpeechToText();
  int _generation = 0;
  bool _direct = false;
  bool _restarting = false;
  Future<void>? _loadFuture;

  Future<void> _loadPref() async {
    _loadFuture ??= () async {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_prefKey) ?? true;
      if (!mounted) return;
      state = state.copyWith(enabled: enabled);
    }();
    await _loadFuture;
  }

  Future<void> setEnabled(bool enabled) async {
    await _loadPref();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    if (!mounted) return;
    state = state.copyWith(enabled: enabled, clearError: true);
    await sync(allowed: state.allowed);
  }

  Future<void> sync({required bool allowed}) async {
    await _loadPref();
    if (!mounted) return;
    // #region agent log
    _agentLog(
      location: 'voice_wake_provider.dart:sync',
      message: 'voice wake sync',
      hypothesisId: 'E',
      data: {
        'allowed': allowed,
        'enabled': state.enabled,
        'phase': state.phase.name,
        'isWeb': kIsWeb,
      },
    );
    // #endregion
    state = state.copyWith(allowed: allowed);
    if (!allowed || !state.enabled) {
      await stop();
      return;
    }
    await _ensureListening();
  }

  Future<void> pause() async {
    // #region agent log
    _agentLog(
      location: 'voice_wake_provider.dart:pause',
      message: 'voice wake paused',
      hypothesisId: 'B',
      data: {'phase': state.phase.name, 'isWeb': kIsWeb},
    );
    // #endregion
    _generation++;
    await _speech.stop();
    if (!mounted) return;
    if (state.phase != VoiceWakePhase.off && state.phase != VoiceWakePhase.processing) {
      state = state.copyWith(phase: VoiceWakePhase.off, partialHeard: '');
    }
  }

  Future<void> stop() async {
    _generation++;
    _direct = false;
    await _speech.stop();
    if (!mounted) return;
    state = state.copyWith(phase: VoiceWakePhase.off, partialHeard: '');
  }

  /// Skip the wake phrase for one command (Assistant mic button).
  Future<void> listenDirect() async {
    if (state.phase == VoiceWakePhase.processing) return;
    _direct = true;
    state = state.copyWith(
      phase: VoiceWakePhase.listening,
      partialHeard: '',
      clearError: true,
    );
    await _startSession();
  }

  Future<void> _ensureListening() async {
    if (!state.allowed || !state.enabled) return;
    if (state.phase == VoiceWakePhase.processing) return;
    if (state.phase == VoiceWakePhase.sleeping ||
        state.phase == VoiceWakePhase.armed ||
        state.phase == VoiceWakePhase.listening) {
      return;
    }
    _direct = false;
    state = state.copyWith(phase: VoiceWakePhase.sleeping, clearError: true);
    await _startSession();
  }

  Future<void> _startSession() async {
    final gen = ++_generation;
    final available = await _speech.initialize(
      onStatus: (status) {
        // #region agent log
        _agentLog(
          location: 'voice_wake_provider.dart:onStatus',
          message: 'speech status',
          hypothesisId: 'A',
          data: {'status': status, 'isListening': _speech.isListening},
        );
        // #endregion
        if (!mounted || gen != _generation) return;
        if (status == 'done' || status == 'notListening') {
          _scheduleRestart(gen);
        }
      },
      onError: (error) {
        // #region agent log
        _agentLog(
          location: 'voice_wake_provider.dart:onError',
          message: 'speech error',
          hypothesisId: 'A',
          data: {
            'error': error.errorMsg,
            'permanent': error.permanent,
          },
        );
        // #endregion
        if (!mounted || gen != _generation) return;
        debugPrint('Voice wake: ${error.errorMsg}');
        _scheduleRestart(gen);
      },
    );

    if (!mounted || gen != _generation) return;

    // #region agent log
    _agentLog(
      location: 'voice_wake_provider.dart:_startSession',
      message: 'speech initialize result',
      hypothesisId: 'A',
      data: {
        'available': available,
        'isWeb': kIsWeb,
        'phase': state.phase.name,
        'isListening': _speech.isListening,
      },
    );
    // #endregion

    if (!available) {
      state = state.copyWith(
        available: false,
        phase: VoiceWakePhase.off,
        error: 'Voice is not available. Check microphone permission.',
      );
      return;
    }

    state = state.copyWith(available: true);
    try {
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 25),
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
        onResult: (result) {
          if (!mounted || gen != _generation) return;
          final text = result.recognizedWords.trim();
          // #region agent log
          _agentLog(
            location: 'voice_wake_provider.dart:onResult',
            message: 'speech result',
            hypothesisId: 'C',
            data: {
              'text': text,
              'finalResult': result.finalResult,
            },
          );
          // #endregion
          state = state.copyWith(partialHeard: text);
          if (result.finalResult) {
            _handleFinal(text);
          }
        },
      );
      // #region agent log
      _agentLog(
        location: 'voice_wake_provider.dart:_startSession',
        message: 'listen started',
        hypothesisId: 'A',
        data: {'isListening': _speech.isListening},
      );
      // #endregion
    } catch (e) {
      // #region agent log
      _agentLog(
        location: 'voice_wake_provider.dart:_startSession',
        message: 'listen threw',
        hypothesisId: 'A',
        data: {'error': e.toString()},
      );
      // #endregion
    }
  }

  void _scheduleRestart(int gen) {
    if (_restarting) return;
    _restarting = true;
    Future<void>.delayed(const Duration(milliseconds: 400), () async {
      _restarting = false;
      if (!mounted || gen != _generation) return;
      if (!state.allowed || !state.enabled || !state.available) return;
      if (state.phase == VoiceWakePhase.processing) return;
      if (_direct) {
        _direct = false;
        state = state.copyWith(
          phase: VoiceWakePhase.sleeping,
          partialHeard: '',
        );
      } else if (state.phase == VoiceWakePhase.off) {
        state = state.copyWith(phase: VoiceWakePhase.sleeping);
      }
      await _startSession();
    });
  }

  Future<void> _handleFinal(String raw) async {
    if (raw.isEmpty) return;

    if (_direct) {
      _direct = false;
      await _runCommand(raw);
      return;
    }

    final parsed = parseVoiceWake(raw);
    // #region agent log
    _agentLog(
      location: 'voice_wake_provider.dart:_handleFinal',
      message: 'wake parse',
      hypothesisId: 'D',
      data: {
        'raw': raw,
        'heardWake': parsed.heardWake,
        'command': parsed.command,
        'phase': state.phase.name,
        'direct': _direct,
      },
    );
    // #endregion
    if (state.phase == VoiceWakePhase.armed) {
      final command = parsed.heardWake && parsed.command.isNotEmpty
          ? parsed.command
          : raw.trim();
      if (command.isEmpty) return;
      await _runCommand(command);
      return;
    }

    if (!parsed.heardWake) return;

    if (parsed.command.isEmpty) {
      state = state.copyWith(
        phase: VoiceWakePhase.armed,
        partialHeard: '',
        clearError: true,
        clearReply: true,
      );
      return;
    }

    await _runCommand(parsed.command);
  }

  Future<void> _runCommand(String command) async {
    if (!mounted) return;
    if (!_ref.read(authProvider).isAuthenticated) {
      state = state.copyWith(error: 'Sign in to use voice commands.');
      return;
    }

    _generation++;
    await _speech.stop();
    state = state.copyWith(
      phase: VoiceWakePhase.processing,
      partialHeard: command,
      clearError: true,
      clearReply: true,
    );

    try {
      final reply = await _ref.read(askAssistantProvider)(command);
      if (!mounted) return;
      state = state.copyWith(
        lastReply: reply.text,
        phase: VoiceWakePhase.sleeping,
        partialHeard: '',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        error: e.toString(),
        phase: VoiceWakePhase.sleeping,
        partialHeard: '',
      );
    }

    await _startSession();
  }

  @override
  void dispose() {
    _generation++;
    _speech.stop();
    super.dispose();
  }
}

final voiceWakeProvider =
    StateNotifierProvider<VoiceWakeNotifier, VoiceWakeState>((ref) {
  return VoiceWakeNotifier(ref);
});
