import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';

/// Result of initiating STK Push.
class StkInitResult {
  const StkInitResult({
    required this.checkoutRequestId,
    required this.status,
  });

  final String? checkoutRequestId;
  final String status;
}

/// Result of polling payment status.
class StkStatusResult {
  const StkStatusResult({
    required this.status,
    this.reference,
    this.mpesaReceiptNumber,
  });

  final String status;
  final String? reference;
  final String? mpesaReceiptNumber;
}

/// Calls the M-Pesa bridge API.
class MpesaApiService {
  MpesaApiService({String? baseUrl}) : _baseUrl = baseUrl ?? apiBaseUrl;

  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl/api$path');

  /// Initiates STK Push. Throws on network/API error.
  Future<StkInitResult> initiateStk({
    required double amount,
    required String phone,
    required String reference,
  }) async {
    final response = await http.post(
      _uri('/mpesa/stk'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'phone': phone,
        'reference': reference,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>?;

    if (response.statusCode == 201) {
      return StkInitResult(
        checkoutRequestId: body?['checkout_request_id'] as String?,
        status: body?['status'] as String? ?? 'processing',
      );
    }

    final message = body?['message'] as String? ?? 'Request failed';
    throw Exception(message);
  }

  /// Polls payment status. Throws on network error.
  Future<StkStatusResult> getStatus(String checkoutRequestId) async {
    final path = '/mpesa/status/${Uri.encodeComponent(checkoutRequestId)}';
    final response = await http.get(_uri(path));

    final body = jsonDecode(response.body) as Map<String, dynamic>?;

    if (response.statusCode == 200) {
      return StkStatusResult(
        status: body?['status'] as String? ?? 'pending',
        reference: body?['reference'] as String?,
        mpesaReceiptNumber: body?['mpesa_receipt_number'] as String?,
      );
    }

    if (response.statusCode == 404) {
      throw Exception('Unknown checkout request');
    }

    throw Exception('Failed to get status');
  }
}
