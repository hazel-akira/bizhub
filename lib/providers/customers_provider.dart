import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../services/api_client.dart';
import 'api_data_provider.dart';
import 'business_api_provider.dart';
import 'database_provider.dart';
import 'unpaid_customers_provider.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final api = ref.watch(businessApiProvider);
  if (api != null) {
    return api.getCustomers();
  }

  final db = ref.watch(databaseProvider);
  return db.getAllCustomers();
});

/// Returns duplicate [Customer] when phone already exists; `null` when saved.
final addCustomerProvider =
    Provider<Future<Customer?> Function(String name, {String phone})>((ref) {
      return (name, {phone = ''}) async {
        final api = ref.read(businessApiProvider);
        if (api != null) {
          try {
            await api.createCustomer(name: name, phone: phone);
            ref.invalidate(customersProvider);
            return null;
          } on ApiException catch (e) {
            if (e.statusCode == 422) {
              final customers = await ref.read(customersProvider.future);
              final normalized = phone.trim();
              if (normalized.isNotEmpty) {
                for (final c in customers) {
                  if (c.phone.trim() == normalized) return c;
                }
              }
              throw Exception(e.message);
            }
            rethrow;
          }
        }

        final db = ref.read(databaseProvider);
        return db.addCustomer(name, phone: phone);
      };
    });

/// Returns duplicate [Customer] when phone taken by another row; `null` when updated.
final updateCustomerProvider =
    Provider<Future<Customer?> Function(int id, String name, {String phone})>((
      ref,
    ) {
      return (id, name, {phone = ''}) async {
        final api = ref.read(businessApiProvider);
        if (api != null) {
          try {
            await api.updateCustomer(id: id, name: name, phone: phone);
            ref.invalidate(customersProvider);
            return null;
          } on ApiException catch (e) {
            if (e.statusCode == 422) {
              final customers = await ref.read(customersProvider.future);
              final normalized = phone.trim();
              for (final c in customers) {
                if (c.id != id && c.phone.trim() == normalized) return c;
              }
              throw Exception(e.message);
            }
            rethrow;
          }
        }

        final db = ref.read(databaseProvider);
        return db.updateCustomer(id, name: name, phone: phone);
      };
    });

/// Returns `null` on success, or a reason code: `orders`, `balance`.
final deleteCustomerProvider = Provider<Future<String?> Function(int id)>((
  ref,
) {
  return (id) async {
    final api = ref.read(businessApiProvider);
    if (api != null) {
      final balance = await ref.read(customerBalanceProvider(id).future);
      if (balance > 0) return 'balance';

      try {
        await api.deleteCustomer(id);
        ref.invalidate(customersProvider);
        return null;
      } on ApiException catch (e) {
        if (e.statusCode == 422 || e.statusCode == 409) {
          return 'orders';
        }
        rethrow;
      }
    }

    final db = ref.read(databaseProvider);
    return db.deleteCustomer(id);
  };
});

void refreshCustomerRelatedProviders(WidgetRef ref) {
  ref.invalidate(customersProvider);
  ref.invalidate(unpaidCustomersProvider);
  ref.invalidate(customerBalanceProvider);
  ref.invalidate(cloudCustomerBalancesProvider);
  refreshUnpaidProviders(ref);
}

final customerBalanceProvider = FutureProvider.family<double, int>((
  ref,
  customerId,
) async {
  final api = ref.watch(businessApiProvider);
  if (api != null) {
    final balances = await ref.watch(cloudCustomerBalancesProvider.future);
    return balances[customerId] ?? 0;
  }

  final db = ref.watch(databaseProvider);
  return db.getCustomerBalance(customerId);
});

final unpaidCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  if (ref.watch(useCloudDataProvider)) {
    final rows = await ref.watch(unpaidCustomersDebtProvider.future);
    if (rows.isEmpty) return [];

    final customers = await ref.watch(customersProvider.future);
    final names = rows.map((r) => r.customerName.toLowerCase()).toSet();
    return customers
        .where((c) => names.contains(c.name.toLowerCase()))
        .toList();
  }

  final db = ref.watch(databaseProvider);
  return db.getUnpaidCustomers();
});
