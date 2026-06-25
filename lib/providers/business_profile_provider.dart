import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/business_type_config.dart';
import 'auth_provider.dart';

final businessTypeConfigProvider = Provider<BusinessTypeConfig>((ref) {
  final typeId = ref.watch(authProvider).user?.businessType;
  return BusinessTypeConfig.forType(typeId);
});

final isFoodBusinessProvider = Provider<bool>((ref) {
  return ref.watch(businessTypeConfigProvider).isFoodBusiness;
});

final businessTypeLabelProvider = Provider<String?>((ref) {
  final user = ref.watch(authProvider).user;
  return user?.businessTypeLabel ?? ref.watch(businessTypeConfigProvider).label;
});
