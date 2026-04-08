import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/business_assistant_service.dart';
import 'database_provider.dart';

final businessAssistantServiceProvider = Provider<BusinessAssistantService>((ref) {
  final db = ref.watch(databaseProvider);
  return BusinessAssistantService(db);
});

