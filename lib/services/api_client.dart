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
        _timeout = timeout ?? const Duration(seconds: 25);

  final http.Client _client;
  final String? _explicitBaseUrl;
  final Duration _timeout;
  String? _cachedBaseUrl;
  String? _token;

  Future<String> get baseUrl async => _resolveBaseUrl();

  void setToken(String? token) => _token = token;

  String? get token => _token;

  void clearBaseUrlCache() => _cachedBaseUrl = null;

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
    Duration? timeout,
  }) async {
    return _decode(await _send(
      () async => _client.get(
        await _uri(path),
        headers: _headers(auth: auth),
      ),
      timeout: timeout,
    ));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
    Duration? timeout,
  }) async {
    return _decode(await _send(
      () async => _client.post(
        await _uri(path),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
      timeout: timeout,
    ));
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
    Duration? timeout,
  }) async {
    return _decode(await _send(
      () async => _client.put(
        await _uri(path),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
      timeout: timeout,
    ));
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = false,
    Duration? timeout,
  }) async {
    return _decode(await _send(
      () async => _client.delete(
        await _uri(path),
        headers: _headers(auth: auth),
      ),
      timeout: timeout,
    ));
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String fileName,
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
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: fileName,
        ),
      );

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException(_unreachableMessage);
    } on TimeoutException {
      throw ApiException(_slowServerMessage);
    } on http.ClientException {
      throw ApiException(_unreachableMessage);
    } on IOException {
      throw ApiException(_unreachableMessage);
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
    Future<http.Response> Function() request, {
    Duration? timeout,
  }) async {
    try {
      return await request().timeout(timeout ?? _timeout);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException(_unreachableMessage);
    } on TimeoutException {
      throw ApiException(_slowServerMessage);
    } on http.ClientException {
      throw ApiException(_unreachableMessage);
    } on IOException {
      throw ApiException(_unreachableMessage);
    }
  }

  static const _slowServerMessage =
      'The server took too long to respond. Pull to refresh and try again.';

  static const _unreachableMessage =
      'Cannot reach the server right now. Try again in a moment.';

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
    final Map<String, dynamic> body;
    if (response.body.isEmpty) {
      body = <String, dynamic>{};
    } else {
      try {
        final decoded = jsonDecode(response.body);
        body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      } on FormatException {
        throw ApiException(
          'The server sent an unexpected response. Try again in a moment.',
        );
      }
    }

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
