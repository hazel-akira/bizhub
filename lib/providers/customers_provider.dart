import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllCustomers();
});

final addCustomerProvider =
    Provider<Future<void> Function(String name, {String phone})>((ref) {
      final db = ref.watch(databaseProvider);
      return (name, {phone = ''}) async {
        await db.addCustomer(name, phone: phone);
      };
    });
