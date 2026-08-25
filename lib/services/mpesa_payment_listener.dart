import 'dart:async';

import 'mpesa_api_service.dart';

/// Listens for STK Push completion.
///
/// The Laravel backend broadcasts [MpesaPaymentReceived] on
/// `private-business.{businessId}` as soon as Safaricom confirms the payment.
/// This listener intercepts that completion by watching the same transaction
/// over `/api/mpesa/status/{checkoutRequestId}` (the project's existing
/// real-time mechanism, which does not require Reverb on the device).
class MpesaPaymentListener {
  MpesaPaymentListener(this._api);

  final MpesaApiService _api;

  Stream<StkStatusResult> watch({
    required String checkoutRequestId,
    Duration interval = const Duration(seconds: 2),
    int maxAttempts = 60,
  }) {
    late StreamController<StkStatusResult> controller;
    Timer? timer;
    var attempts = 0;
    var closed = false;

    Future<void> tick() async {
      if (closed) return;
      attempts++;
      try {
        final status = await _api.getStatus(checkoutRequestId);
        if (closed) return;
        controller.add(status);
        if (status.isCompleted || status.isFailed || attempts >= maxAttempts) {
          closed = true;
          await controller.close();
        }
      } catch (e, st) {
        if (closed) return;
        if (attempts >= maxAttempts) {
          closed = true;
          controller.addError(e, st);
          await controller.close();
        }
      }
    }

    controller = StreamController<StkStatusResult>(
      onListen: () {
        timer = Timer.periodic(interval, (_) => tick());
        tick();
      },
      onCancel: () {
        closed = true;
        timer?.cancel();
      },
    );

    controller.done.then((_) {
      closed = true;
      timer?.cancel();
    });

    return controller.stream;
  }

  Future<StkStatusResult?> waitForCompletion({
    required String checkoutRequestId,
    Duration interval = const Duration(seconds: 2),
    int maxAttempts = 60,
  }) async {
    await for (final status in watch(
      checkoutRequestId: checkoutRequestId,
      interval: interval,
      maxAttempts: maxAttempts,
    )) {
      if (status.isCompleted || status.isFailed) {
        return status;
      }
    }
    return null;
  }
}
