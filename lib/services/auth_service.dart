import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import 'api_client.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class AuthService {
  AuthService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  static const _tokenKey = 'akira_bites_access_token';
  static const _userKey = 'akira_bites_user';

  final ApiClient _api;

  ApiClient get apiClient => _api;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    _api.clearBaseUrlCache();
    final json = await _api.post('/api/auth/login', body: {
      'email': email.trim(),
      'password': password,
    });

    return _sessionFromResponse(json);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String businessName,
    required String businessType,
  }) async {
    _api.clearBaseUrlCache();
    final json = await _api.post('/api/auth/register', body: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
      'business_name': businessName.trim(),
      'business_type': businessType,
    });

    return _sessionFromResponse(json);
  }

  Future<AuthUser> fetchMe(String token) async {
    _api.setToken(token);
    final json = await _api.get('/api/auth/me', auth: true);
    final data = json['data'] as Map<String, dynamic>;
    return AuthUser.fromJson(data);
  }

  Future<void> logout(String token) async {
    _api.setToken(token);
    try {
      await _api.post('/api/auth/logout', auth: true);
    } on ApiException {
      // Clear local session even if the server call fails.
    }
  }

  /// Restores session from device storage (no network call — fast startup).
  Future<AuthSession?> loadStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);

    if (token == null || token.isEmpty || userJson == null) {
      return null;
    }

    try {
      final user = AuthUser.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      _api.setToken(token);
      return AuthSession(token: token, user: user);
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _api.setToken(null);
  }

  Future<void> persistUser(String token, AuthUser user) async {
    await _persist(token, user);
  }

  Future<AuthSession> _sessionFromResponse(Map<String, dynamic> json) async {
    final data = json['data'] as Map<String, dynamic>;
    final token = data['access_token'] as String;
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    _api.setToken(token);
    await _persist(token, user);
    return AuthSession(token: token, user: user);
  }

  Future<void> _persist(String token, AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _api.setToken(token);
  }
}
