import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/pending_order_view.dart';
import 'api_data_provider.dart';
import 'business_api_provider.dart';
import 'database_provider.dart';

final pendingOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final api = ref.watch(businessApiProvider);
  if (api != null) {
    final orders = await api.getShopOrders();
    return orders
        .map(
          (o) => Order(
            id: o.id,
            customerId: 0,
            ndenguCount: o.ndenguCount,
            meatCount: o.meatCount,
            orderDate: o.orderDate,
            status: 'pending',
          ),
        )
        .toList();
  }

  final db = ref.watch(databaseProvider);
  return db.getPendingOrders();
});

final pendingOrdersWithNamesProvider =
    FutureProvider<List<PendingOrderView>>((ref) async {
  final api = ref.watch(businessApiProvider);
  if (api != null) {
    return api.getShopOrders();
  }

  final db = ref.watch(databaseProvider);
  final rows = await db.getPendingOrdersWithNames();
  return rows
      .map(
        (record) => PendingOrderView(
          id: record.$1.id,
          customerName: record.$2,
          ndenguCount: record.$1.ndenguCount,
          meatCount: record.$1.meatCount,
          orderDate: record.$1.orderDate,
        ),
      )
      .toList();
});

final createOrderProvider =
    Provider<Future<void> Function(int customerId, int ndengu, int meat)>((
  ref,
) {
  return (customerId, ndengu, meat) async {
    final api = ref.read(businessApiProvider);
    if (api != null) {
      await api.createShopOrder(
        customerId: customerId,
        ndenguCount: ndengu,
        meatCount: meat,
      );
      ref.invalidate(pendingOrdersWithNamesProvider);
      ref.invalidate(pendingOrdersProvider);
      return;
    }

    final db = ref.read(databaseProvider);
    await db.createOrder(customerId, ndengu, meat);
  };
});

final fulfillOrderProvider = Provider<Future<void> Function(int orderId)>((ref) {
  return (orderId) async {
    final api = ref.read(businessApiProvider);
    if (api != null) {
      await api.fulfillShopOrder(orderId);
      ref.invalidate(pendingOrdersWithNamesProvider);
      ref.invalidate(pendingOrdersProvider);
      ref.invalidate(apiSalesProvider);
      ref.invalidate(apiDashboardProvider);
      ref.invalidate(apiTodaySalesProvider);
      ref.invalidate(cloudCustomerBalancesProvider);
      return;
    }

    final db = ref.read(databaseProvider);
    await db.fulfillOrder(orderId);
  };
});
