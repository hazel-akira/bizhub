import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

final pendingOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getPendingOrders();
});

final pendingOrdersWithNamesProvider = FutureProvider<List<(Order, String)>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  return db.getPendingOrdersWithNames();
});

final createOrderProvider =
    Provider<Future<void> Function(int customerId, int ndengu, int meat)>((
      ref,
    ) {
      final db = ref.watch(databaseProvider);
      return (customerId, ndengu, meat) async {
        await db.createOrder(customerId, ndengu, meat);
      };
    });

final fulfillOrderProvider =
    Provider<Future<void> Function(int orderId)>((ref) {
      final db = ref.watch(databaseProvider);
      return (orderId) async => db.fulfillOrder(orderId);
    });
