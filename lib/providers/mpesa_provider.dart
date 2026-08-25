import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/mpesa_api_service.dart';
import '../services/mpesa_payment_listener.dart';
import 'auth_provider.dart';

final mpesaApiProvider = Provider<MpesaApiService?>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated || auth.token == null) {
    return null;
  }
  return MpesaApiService(ref.watch(apiClientProvider));
});

final mpesaPaymentListenerProvider = Provider<MpesaPaymentListener?>((ref) {
  final api = ref.watch(mpesaApiProvider);
  if (api == null) return null;
  return MpesaPaymentListener(api);
});

final mpesaConfigProvider = FutureProvider<MpesaConfigInfo?>((ref) async {
  final api = ref.watch(mpesaApiProvider);
  if (api == null) return null;
  return api.getConfig();
});
