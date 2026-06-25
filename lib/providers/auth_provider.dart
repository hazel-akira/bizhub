import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(authProvider);
  final client = ApiClient();
  client.setToken(auth.token);
  return client;
});

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.user,
    this.token,
    this.error,
  });

  final bool isLoading;
  final AuthUser? user;
  final String? token;
  final String? error;

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({
    bool? isLoading,
    AuthUser? user,
    String? token,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      token: clearUser ? null : (token ?? this.token),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._auth) : super(const AuthState(isLoading: true)) {
    _restore();
  }

  final AuthService _auth;

  Future<void> _restore() async {
    try {
      final session = await _auth.loadStoredSession();
      if (session == null) {
        state = const AuthState(isLoading: false);
        return;
      }

      try {
        final user = await _auth.fetchMe(session.token);
        await _auth.persistUser(session.token, user);
        state = AuthState(
          isLoading: false,
          user: user,
          token: session.token,
        );
      } catch (_) {
        state = AuthState(
          isLoading: false,
          user: session.user,
          token: session.token,
        );
      }
    } catch (_) {
      state = const AuthState(isLoading: false);
    }
  }

  Future<void> refreshProfile() async {
    final token = state.token;
    if (token == null) return;
    try {
      final user = await _auth.fetchMe(token);
      await _auth.persistUser(token, user);
      state = state.copyWith(user: user, clearError: true);
    } catch (_) {}
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _auth.login(email: email, password: password);
      state = AuthState(
        isLoading: false,
        user: session.user,
        token: session.token,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('ApiException: ', ''),
      );
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String businessName,
    required String businessType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _auth.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        businessName: businessName,
        businessType: businessType,
      );
      state = AuthState(
        isLoading: false,
        user: session.user,
        token: session.token,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('ApiException: ', ''),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    final token = state.token;
    state = state.copyWith(isLoading: true);
    if (token != null) {
      await _auth.logout(token);
    }
    await _auth.clearSession();
    state = const AuthState(isLoading: false);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
