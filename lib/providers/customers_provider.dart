import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllCustomers();
});

/// Returns duplicate [Customer] when phone already exists; `null` when saved.
final addCustomerProvider =
    Provider<Future<Customer?> Function(String name, {String phone})>((ref) {
  final db = ref.watch(databaseProvider);
  return (name, {phone = ''}) => db.addCustomer(name, phone: phone);
});

/// Returns duplicate [Customer] when phone taken by another row; `null` when updated.
final updateCustomerProvider =
    Provider<Future<Customer?> Function(int id, String name, {String phone})>((ref) {
  final db = ref.watch(databaseProvider);
  return (id, name, {phone = ''}) =>
      db.updateCustomer(id, name: name, phone: phone);
});

final deleteCustomerProvider = Provider<Future<bool> Function(int id)>((ref) {
  final db = ref.watch(databaseProvider);
  return (id) => db.deleteCustomer(id);
});

final customerBalanceProvider = FutureProvider.family<double, int>((ref, customerId) async {
  final db = ref.watch(databaseProvider);
  return db.getCustomerBalance(customerId);
});

final unpaidCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getUnpaidCustomers();
});
