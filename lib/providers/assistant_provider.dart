import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/business_assistant_service.dart';
import '../services/cloud_business_assistant_service.dart';
import 'business_api_provider.dart';
import 'database_provider.dart';

abstract class BusinessAssistant {
  Future<String> answer(String input);
}

class _LocalBusinessAssistant implements BusinessAssistant {
  _LocalBusinessAssistant(this._service);

  final BusinessAssistantService _service;

  @override
  Future<String> answer(String input) => _service.answer(input);
}

class _CloudBusinessAssistant implements BusinessAssistant {
  _CloudBusinessAssistant(this._service);

  final CloudBusinessAssistantService _service;

  @override
  Future<String> answer(String input) => _service.answer(input);
}

final businessAssistantServiceProvider = Provider<BusinessAssistant>((ref) {
  final api = ref.watch(businessApiProvider);
  if (api != null) {
    return _CloudBusinessAssistant(CloudBusinessAssistantService(api));
  }

  final db = ref.watch(databaseProvider);
  return _LocalBusinessAssistant(BusinessAssistantService(db));
});

