import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config_service.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _explicitBaseUrl = baseUrl,
        _timeout = timeout ?? const Duration(seconds: 12);

  final http.Client _client;
  final String? _explicitBaseUrl;
  final Duration _timeout;
  String? _cachedBaseUrl;
  String? _token;

  Future<String> get baseUrl async => _resolveBaseUrl();

  void setToken(String? token) => _token = token;

  String? get token => _token;

  void clearBaseUrlCache() => _cachedBaseUrl = null;

  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('${await _resolveBaseUrl()}/api/health');
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
  }) async {
    return _decode(await _send(() async => _client.get(
          await _uri(path),
          headers: _headers(auth: auth),
        )));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    return _decode(await _send(() async => _client.post(
          await _uri(path),
          headers: _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        )));
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    return _decode(await _send(() async => _client.put(
          await _uri(path),
          headers: _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        )));
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required String filePath,
    String? fileName,
    bool auth = false,
  }) async {
    try {
      final uri = await _uri(path);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      if (auth && _token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          filePath,
          filename: fileName,
        ),
      );

      final streamed = await request.send().timeout(
        _timeout,
        onTimeout: () {
          throw ApiException(
            'Upload timed out. Tap "Test" on the login screen to check the API.',
          );
        },
      );
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException(await _connectionHelp());
    } on TimeoutException {
      throw ApiException(await _connectionHelp());
    } on http.ClientException {
      throw ApiException(await _connectionHelp());
    }
  }

  Future<String> _resolveBaseUrl() async {
    if (_explicitBaseUrl != null) {
      return _explicitBaseUrl.replaceAll(RegExp(r'/+$'), '');
    }
    _cachedBaseUrl ??= await ApiConfigService.getBaseUrl();
    return _cachedBaseUrl!;
  }

  Future<Uri> _uri(String path) async {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${await _resolveBaseUrl()}$normalized');
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(
        _timeout,
        onTimeout: () {
          throw ApiException(
            'Request timed out. Tap "Test" on the login screen to check the API.',
          );
        },
      );
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException(await _connectionHelp());
    } on TimeoutException {
      throw ApiException(await _connectionHelp());
    } on http.ClientException {
      throw ApiException(await _connectionHelp());
    }
  }

  Future<String> _connectionHelp() async {
    final url = await _resolveBaseUrl();
    return 'Cannot reach the API at $url.\n'
        '1. Run: ./scripts/start-api.sh\n'
        '2. Tap Test on the login screen\n'
        '3. On Chrome/web: use Linux desktop (flutter run → option 1) if CORS blocks';
  }

  Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] as String? ??
        _firstValidationError(body['errors']) ??
        'Request failed (${response.statusCode})';

    throw ApiException(
      message,
      statusCode: response.statusCode,
      errors: body['errors'] as Map<String, dynamic>?,
    );
  }

  String? _firstValidationError(dynamic errors) {
    if (errors is! Map) return null;
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
    }
    return null;
  }
}
