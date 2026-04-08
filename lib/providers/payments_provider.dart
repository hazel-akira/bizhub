import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

final allPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllPayments();
});

final addPaymentProvider = Provider<
    Future<void> Function({
      required int saleId,
      required double amount,
      required String method,
    })>((ref) {
  final db = ref.watch(databaseProvider);
  return ({required saleId, required amount, required method}) async {
    await db.addPayment(saleId: saleId, amount: amount, method: method);
  };
});
