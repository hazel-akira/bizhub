import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/assistant_reply.dart';
import '../services/business_assistant_service.dart';
import '../services/cloud_business_assistant_service.dart';
import 'api_data_provider.dart';
import 'business_api_provider.dart';
import 'customers_provider.dart';
import 'database_provider.dart';

abstract class BusinessAssistant {
  Future<AssistantReply> answer(String input);
}

class _LocalBusinessAssistant implements BusinessAssistant {
  _LocalBusinessAssistant(this._service);

  final BusinessAssistantService _service;

  @override
  Future<AssistantReply> answer(String input) async {
    return AssistantReply(text: await _service.answer(input));
  }
}

class _CloudBusinessAssistant implements BusinessAssistant {
  _CloudBusinessAssistant(this._service);

  final CloudBusinessAssistantService _service;

  @override
  Future<AssistantReply> answer(String input) => _service.answer(input);
}

final businessAssistantServiceProvider = Provider<BusinessAssistant>((ref) {
  final api = ref.watch(businessApiProvider);
  if (api != null) {
    return _CloudBusinessAssistant(CloudBusinessAssistantService(api));
  }

  final db = ref.watch(databaseProvider);
  return _LocalBusinessAssistant(BusinessAssistantService(db));
});

final askAssistantProvider =
    Provider<Future<AssistantReply> Function(String)>((ref) {
  return (input) async {
    final reply = await ref.read(businessAssistantServiceProvider).answer(input);
    _invalidateForActions(ref, reply.actions);
    return reply;
  };
});

void _invalidateForActions(Ref ref, List<String> actions) {
  if (actions.isEmpty) return;

  if (actions.contains('product_created') ||
      actions.contains('product_updated')) {
    ref.invalidate(apiProductsProvider);
    ref.invalidate(apiCategoriesProvider);
    ref.invalidate(apiDashboardProvider);
  }
  if (actions.contains('expense_created')) {
    ref.invalidate(apiExpensesProvider);
    ref.invalidate(apiTodayExpensesProvider);
    ref.invalidate(apiDashboardProvider);
  }
  if (actions.contains('sale_created')) {
    ref.invalidate(apiSalesProvider);
    ref.invalidate(apiTodaySalesProvider);
    ref.invalidate(apiProductsProvider);
    ref.invalidate(apiDashboardProvider);
    ref.invalidate(cloudCustomerBalancesProvider);
  }
  if (actions.contains('customer_created')) {
    ref.invalidate(customersProvider);
    ref.invalidate(cloudCustomerBalancesProvider);
  }
}
