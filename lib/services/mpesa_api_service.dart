import '../core/phone_utils.dart';
import 'api_client.dart';

class MpesaConfigInfo {
  const MpesaConfigInfo({
    required this.configured,
    this.shortcode,
    this.accountType = 'paybill',
    this.accountTypeLabel,
  });

  final bool configured;
  final String? shortcode;
  final String accountType;
  final String? accountTypeLabel;

  factory MpesaConfigInfo.fromJson(Map<String, dynamic> json) {
    return MpesaConfigInfo(
      configured: json['configured'] as bool? ?? false,
      shortcode: json['shortcode'] as String?,
      accountType: json['account_type'] as String? ?? 'paybill',
      accountTypeLabel: json['account_type_label'] as String?,
    );
  }
}

class StkInitResult {
  const StkInitResult({
    required this.checkoutRequestId,
    required this.status,
    this.id,
    this.amount,
    this.phone,
  });

  final int? id;
  final String checkoutRequestId;
  final String status;
  final int? amount;
  final String? phone;

  factory StkInitResult.fromJson(Map<String, dynamic> json) {
    return StkInitResult(
      id: json['id'] as int?,
      checkoutRequestId: json['checkout_request_id'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      amount: json['amount'] as int?,
      phone: json['phone'] as String?,
    );
  }
}

class StkStatusResult {
  const StkStatusResult({
    required this.status,
    this.reference,
    this.mpesaReceiptNumber,
    this.amount,
  });

  final String status;
  final String? reference;
  final String? mpesaReceiptNumber;
  final int? amount;

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isFailed => status.toUpperCase() == 'FAILED';
  bool get isPending => !isCompleted && !isFailed;

  factory StkStatusResult.fromJson(Map<String, dynamic> json) {
    return StkStatusResult(
      status: json['status'] as String? ?? 'PENDING',
      reference: json['reference'] as String?,
      mpesaReceiptNumber: json['mpesa_receipt_number'] as String?,
      amount: json['amount'] as int?,
    );
  }
}

/// Calls the Laravel M-Pesa API using the signed-in tenant.
class MpesaApiService {
  MpesaApiService(this._api);

  final ApiClient _api;

  Future<MpesaConfigInfo> getConfig() async {
    final json = await _api.get('/api/mpesa/config', auth: true);
    return MpesaConfigInfo.fromJson(_data(json));
  }

  Future<MpesaConfigInfo> saveConfig({
    required String shortcode,
    required String accountType,
    String? consumerKey,
    String? consumerSecret,
    String? passkey,
  }) async {
    final body = <String, dynamic>{
      'shortcode': shortcode,
      'account_type': accountType,
    };
    if (consumerKey != null && consumerKey.trim().isNotEmpty) {
      body['consumer_key'] = consumerKey.trim();
    }
    if (consumerSecret != null && consumerSecret.trim().isNotEmpty) {
      body['consumer_secret'] = consumerSecret.trim();
    }
    if (passkey != null && passkey.trim().isNotEmpty) {
      body['passkey'] = passkey.trim();
    }

    final json = await _api.put('/api/mpesa/config', auth: true, body: body);
    return MpesaConfigInfo.fromJson(_data(json));
  }

  /// Initiates STK Push for the current tenant.
  Future<StkInitResult> initiateStkPush({
    required int businessId,
    required double amount,
    required String phone,
    String? reference,
  }) async {
    final json = await _api.post(
      '/api/mpesa/stk-push',
      auth: true,
      timeout: const Duration(seconds: 30),
      body: {
        'business_id': businessId,
        'tenant_id': businessId,
        'amount': amount,
        'phone': normalizePhoneKey(phone),
        'reference': ?reference,
      },
    );

    return StkInitResult.fromJson(_data(json));
  }

  /// Unpaid-screen compatibility helper.
  Future<StkInitResult> initiateStk({
    required double amount,
    required String phone,
    required String reference,
    required int businessId,
  }) {
    return initiateStkPush(
      businessId: businessId,
      amount: amount,
      phone: phone,
      reference: reference,
    );
  }

  Future<StkStatusResult> getStatus(String checkoutRequestId) async {
    final path =
        '/api/mpesa/status/${Uri.encodeComponent(checkoutRequestId)}';
    final json = await _api.get(path, auth: true);
    return StkStatusResult.fromJson(_data(json));
  }

  Map<String, dynamic> _data(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
}
