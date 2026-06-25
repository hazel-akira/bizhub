import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/business_api_service.dart';
import 'auth_provider.dart';

final businessApiProvider = Provider<BusinessApiService?>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated || auth.token == null) {
    return null;
  }

  final client = ApiClient();
  client.setToken(auth.token);
  return BusinessApiService(client);
});

/// True when the app should read/write via Laravel API.
final useCloudDataProvider = Provider<bool>((ref) {
  return ref.watch(businessApiProvider) != null;
});
