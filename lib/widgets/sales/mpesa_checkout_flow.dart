import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/phone_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mpesa_provider.dart';
import '../../services/api_client.dart';
import '../../services/mpesa_api_service.dart';
import '../../services/mpesa_payment_listener.dart';

enum _MpesaCollectMethod { qr, stk }

class MpesaCheckoutResult {
  const MpesaCheckoutResult({
    required this.status,
    this.mpesaReceiptNumber,
    this.phone,
  });

  final StkStatusResult status;
  final String? mpesaReceiptNumber;
  final String? phone;
}

/// Cashier M-Pesa: Lipa na M-Pesa QR (customer scans) or STK Push.
class MpesaCheckoutFlow {
  static Future<MpesaCheckoutResult?> collect({
    required BuildContext context,
    required WidgetRef ref,
    required double amount,
    String? initialPhone,
    String? reference,
  }) async {
    final api = ref.read(mpesaApiProvider);
    final listener = ref.read(mpesaPaymentListenerProvider);
    final businessId = ref.read(authProvider).user?.businessId;

    if (api == null || listener == null || businessId == null) {
      _snack(context, 'Sign in to collect M-Pesa payments.');
      return null;
    }

    final config = await ref.read(mpesaConfigProvider.future);
    if (!context.mounted) return null;
    if (config == null || !config.configured) {
      _snack(
        context,
        'Add Lipa Na M-Pesa Till or Paybill credentials in Settings first.',
      );
      return null;
    }

    if (!context.mounted) return null;
    final method = await _askMethod(context, config);
    if (method == null || !context.mounted) return null;

    if (method == _MpesaCollectMethod.qr) {
      return _collectQr(
        context: context,
        api: api,
        listener: listener,
        amount: amount,
        reference: reference,
        config: config,
      );
    }

    return _collectStk(
      context: context,
      api: api,
      listener: listener,
      businessId: businessId,
      amount: amount,
      initialPhone: initialPhone,
      reference: reference,
    );
  }

  static Future<MpesaCheckoutResult?> _collectQr({
    required BuildContext context,
    required MpesaApiService api,
    required MpesaPaymentListener listener,
    required double amount,
    required MpesaConfigInfo config,
    String? reference,
  }) async {
    MpesaQrInitResult init;
    try {
      init = await api.generatePaymentQr(amount: amount, reference: reference);
    } on ApiException catch (e) {
      if (context.mounted) {
        final mpesaErr = e.errors?['mpesa'];
        final extra = mpesaErr is List && mpesaErr.isNotEmpty
            ? mpesaErr.first.toString()
            : e.message;
        _snack(context, extra);
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        _snack(context, e.toString().replaceFirst('Exception: ', ''));
      }
      return null;
    }

    if (!context.mounted) return null;
    final status = await _showQrSheet(
      context: context,
      api: api,
      listener: listener,
      qr: init,
      config: config,
    );
    if (!context.mounted) return null;
    return _resultFromStatus(context, status);
  }

  static Future<MpesaCheckoutResult?> _collectStk({
    required BuildContext context,
    required MpesaApiService api,
    required MpesaPaymentListener listener,
    required int businessId,
    required double amount,
    String? initialPhone,
    String? reference,
  }) async {
    final phone = await _askPhone(context, initialPhone);
    if (phone == null || !context.mounted) return null;

    StkInitResult init;
    try {
      init = await api.initiateStkPush(
        businessId: businessId,
        amount: amount,
        phone: phone,
        reference: reference,
      );
    } on ApiException catch (e) {
      if (context.mounted) {
        final mpesaErr = e.errors?['mpesa'];
        final extra = mpesaErr is List && mpesaErr.isNotEmpty
            ? mpesaErr.first.toString()
            : e.message;
        _snack(context, extra);
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        _snack(context, e.toString().replaceFirst('Exception: ', ''));
      }
      return null;
    }

    if (init.checkoutRequestId.isEmpty) {
      if (context.mounted) {
        _snack(context, 'M-Pesa did not return a checkout request.');
      }
      return null;
    }
    if (!context.mounted) return null;

    final status = await _showProcessingSheet(
      context: context,
      listener: listener,
      checkoutRequestId: init.checkoutRequestId,
    );
    if (!context.mounted) return null;
    final result = _resultFromStatus(context, status);
    if (result == null) return null;
    return MpesaCheckoutResult(
      status: result.status,
      mpesaReceiptNumber: result.mpesaReceiptNumber,
      phone: phone,
    );
  }

  static MpesaCheckoutResult? _resultFromStatus(
    BuildContext context,
    StkStatusResult? status,
  ) {
    if (status == null) {
      _snack(context, 'M-Pesa payment was cancelled.');
      return null;
    }
    if (status.isFailed) {
      _snack(context, 'M-Pesa payment failed. Ask the customer to try again.');
      return null;
    }
    if (!status.isCompleted) {
      _snack(context, 'Timed out waiting for the M-Pesa payment.');
      return null;
    }
    return MpesaCheckoutResult(
      status: status,
      mpesaReceiptNumber: status.mpesaReceiptNumber,
    );
  }

  static Future<_MpesaCollectMethod?> _askMethod(
    BuildContext context,
    MpesaConfigInfo config,
  ) {
    final tillLabel = config.accountType == 'till' ? 'Till' : 'Paybill';
    final shortcode = config.shortcode ?? '';
    return showDialog<_MpesaCollectMethod>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pay with M-Pesa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              shortcode.isEmpty
                  ? 'Lipa na M-Pesa is configured.'
                  : '$tillLabel $shortcode is ready.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, _MpesaCollectMethod.qr),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Show QR to scan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, _MpesaCollectMethod.stk),
              icon: const Icon(Icons.phone_android),
              label: const Text('Send STK to phone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static Future<String?> _askPhone(BuildContext context, String? initial) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MpesaPhoneDialog(initialPhone: initial),
    );
  }

  static Future<StkStatusResult?> _showProcessingSheet({
    required BuildContext context,
    required MpesaPaymentListener listener,
    required String checkoutRequestId,
  }) {
    return showModalBottomSheet<StkStatusResult>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) => _MpesaProcessingSheet(
        checkoutRequestId: checkoutRequestId,
        listener: listener,
      ),
    );
  }

  static Future<StkStatusResult?> _showQrSheet({
    required BuildContext context,
    required MpesaApiService api,
    required MpesaPaymentListener listener,
    required MpesaQrInitResult qr,
    required MpesaConfigInfo config,
  }) {
    return showModalBottomSheet<StkStatusResult>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) => _MpesaQrSheet(
        qr: qr,
        config: config,
        api: api,
        listener: listener,
      ),
    );
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MpesaPhoneDialog extends StatefulWidget {
  const _MpesaPhoneDialog({this.initialPhone});

  final String? initialPhone;

  @override
  State<_MpesaPhoneDialog> createState() => _MpesaPhoneDialogState();
}

class _MpesaPhoneDialogState extends State<_MpesaPhoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('M-Pesa number'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Customer phone',
            hintText: '0712 345 678',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final digits = normalizePhoneKey(value ?? '');
            if (digits.length < 12) return 'Enter a valid M-Pesa number';
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Send STK Push'),
        ),
      ],
    );
  }
}

class _MpesaProcessingSheet extends StatefulWidget {
  const _MpesaProcessingSheet({
    required this.checkoutRequestId,
    required this.listener,
  });

  final String checkoutRequestId;
  final MpesaPaymentListener listener;

  @override
  State<_MpesaProcessingSheet> createState() => _MpesaProcessingSheetState();
}

class _MpesaProcessingSheetState extends State<_MpesaProcessingSheet> {
  StreamSubscription<StkStatusResult>? _subscription;
  var _finished = false;
  StkStatusResult? _lastStatus;

  @override
  void initState() {
    super.initState();
    _subscription = widget.listener
        .watch(checkoutRequestId: widget.checkoutRequestId)
        .listen(
          (status) {
            _lastStatus = status;
            if (status.isCompleted || status.isFailed) {
              _finish(status);
            }
          },
          onError: (_) => _finish(_lastStatus),
          onDone: () => _finish(_lastStatus),
        );
  }

  void _finish([StkStatusResult? status]) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(status);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Processing transaction...',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enter your M-Pesa PIN on your phone',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _finish(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MpesaQrSheet extends StatefulWidget {
  const _MpesaQrSheet({
    required this.qr,
    required this.config,
    required this.api,
    required this.listener,
  });

  final MpesaQrInitResult qr;
  final MpesaConfigInfo config;
  final MpesaApiService api;
  final MpesaPaymentListener listener;

  @override
  State<_MpesaQrSheet> createState() => _MpesaQrSheetState();
}

class _MpesaQrSheetState extends State<_MpesaQrSheet> {
  StreamSubscription<StkStatusResult>? _subscription;
  var _finished = false;
  var _confirming = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.listener
        .watch(checkoutRequestId: widget.qr.checkoutRequestId)
        .listen(
          (status) {
            if (status.isCompleted || status.isFailed) {
              _finish(status);
            }
          },
          onError: (_) {},
        );
  }

  void _finish([StkStatusResult? status]) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(status);
  }

  Future<void> _enterReceipt() async {
    final receiptCtrl = TextEditingController();
    final receipt = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('M-Pesa code'),
        content: TextField(
          controller: receiptCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Receipt from the customer SMS',
            hintText: 'e.g. QLK7RT61SV',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, receiptCtrl.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (receipt == null || receipt.length < 6 || !mounted) return;

    setState(() => _confirming = true);
    try {
      final status = await widget.api.confirmQrPayment(
        checkoutRequestId: widget.qr.checkoutRequestId,
        mpesaReceiptNumber: receipt,
      );
      _finish(status);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Uint8List? get _qrBytes {
    final raw = widget.qr.qrCode.trim();
    if (raw.isEmpty) return null;
    try {
      final payload = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bytes = _qrBytes;
    final tillLabel = widget.config.accountType == 'till' ? 'Till' : 'Paybill';
    final shortcode = widget.qr.shortcode ?? widget.config.shortcode ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan to pay with M-Pesa',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'KES ${widget.qr.amount}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (shortcode.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '$tillLabel $shortcode',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (bytes != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Image.memory(bytes, width: 240, height: 240),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: QrImageView(
                    data: widget.qr.qrPayload ??
                        'Lipa na M-Pesa $tillLabel $shortcode\nKES ${widget.qr.amount}',
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
              if (widget.qr.sandbox || shortcode == '174379') ...[
                const SizedBox(height: 12),
                Text(
                  'Sandbox QR: the image can be generated, but a real M-Pesa app cannot pay 174379. Use STK for sandbox tests, or type a test receipt with “I have the M-Pesa code”. Live scan-to-pay needs a production Till or Paybill.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade800,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  'Ask the customer to open M-Pesa → Scan QR, then enter PIN.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_confirming)
                const CircularProgressIndicator()
              else
                OutlinedButton(
                  onPressed: _enterReceipt,
                  child: const Text('I have the M-Pesa code'),
                ),
              TextButton(
                onPressed: () => _finish(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
