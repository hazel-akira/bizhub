import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/phone_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mpesa_provider.dart';
import '../../services/api_client.dart';
import '../../services/mpesa_api_service.dart';
import '../../services/mpesa_payment_listener.dart';

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

/// Cashier M-Pesa STK Push: phone prompt → processing sheet → completion.
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
      if (context.mounted) _snack(context, e.message);
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

    if (status == null) {
      _snack(context, 'M-Pesa payment was cancelled.');
      return null;
    }
    if (status.isFailed) {
      _snack(context, 'M-Pesa payment failed. Ask the customer to try again.');
      return null;
    }
    if (!status.isCompleted) {
      _snack(context, 'Timed out waiting for the M-Pesa PIN.');
      return null;
    }

    return MpesaCheckoutResult(
      status: status,
      mpesaReceiptNumber: status.mpesaReceiptNumber,
      phone: phone,
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
