import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

class UnpaidSaleRow {
  final Sale sale;
  final String customerName;
  final double outstanding;
  final DateTime createdAt;

  const UnpaidSaleRow({
    required this.sale,
    required this.customerName,
    required this.outstanding,
    required this.createdAt,
  });
}

class UnpaidCustomerDebtRow {
  final String customerName;
  final double outstanding;
  final DateTime date; // oldest unpaid sale date
  final List<UnpaidSaleRow> unpaidSales; // oldest -> newest

  const UnpaidCustomerDebtRow({
    required this.customerName,
    required this.outstanding,
    required this.date,
    required this.unpaidSales,
  });
}

final unpaidSalesWithOutstandingProvider =
    FutureProvider<List<UnpaidSaleRow>>((ref) async {
  final db = ref.watch(databaseProvider);

  final sales = await db.getAllSalesListItems();
  final payments = await db.getAllPayments();

  final paidBySaleId = <int, double>{};
  for (final p in payments) {
    paidBySaleId[p.saleId] = (paidBySaleId[p.saleId] ?? 0) + p.amount;
  }

  final rows = sales
      .where((item) => !item.sale.isPaid)
      .map((item) {
        final paid = paidBySaleId[item.sale.id] ?? 0;
        final outstanding = item.sale.totalAmount - paid;
        return UnpaidSaleRow(
          sale: item.sale,
          customerName: item.customerName,
          outstanding: outstanding,
          createdAt: item.sale.createdAt,
        );
      })
      .where((r) => r.outstanding > 0)
      .toList();

  rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return rows;
});

final unpaidCustomersDebtProvider =
    FutureProvider<List<UnpaidCustomerDebtRow>>((ref) async {
  final db = ref.watch(databaseProvider);

  final sales = await db.getAllSalesListItems();
  final payments = await db.getAllPayments();

  final paidBySaleId = <int, double>{};
  for (final p in payments) {
    paidBySaleId[p.saleId] = (paidBySaleId[p.saleId] ?? 0) + p.amount;
  }

  final unpaidSales = sales
      .where((item) => !item.sale.isPaid)
      .map((item) {
        final paid = paidBySaleId[item.sale.id] ?? 0;
        final outstanding = item.sale.totalAmount - paid;
        return UnpaidSaleRow(
          sale: item.sale,
          customerName: item.customerName,
          outstanding: outstanding,
          createdAt: item.sale.createdAt,
        );
      })
      .where((r) => r.outstanding > 0)
      .toList();

  // Group unpaid sales by customer and compute total outstanding.
  final byCustomer = <String, List<UnpaidSaleRow>>{};
  for (final s in unpaidSales) {
    byCustomer.putIfAbsent(s.customerName, () => []).add(s);
  }

  final result = <UnpaidCustomerDebtRow>[];
  for (final entry in byCustomer.entries) {
    final salesForCustomer = entry.value;
    salesForCustomer.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // oldest first

    final outstanding = salesForCustomer.fold<double>(
      0,
      (sum, s) => sum + s.outstanding,
    );

    result.add(
      UnpaidCustomerDebtRow(
        customerName: entry.key,
        outstanding: outstanding,
        date: salesForCustomer.first.createdAt,
        unpaidSales: salesForCustomer,
      ),
    );
  }

  // Sort by oldest debt start date (newest debts first).
  result.sort((a, b) => b.date.compareTo(a.date));
  return result;
});

final addUnpaidSaleProvider = Provider<
    Future<void> Function({
      required String customerName,
      required int quantity,
      required double totalAmount,
    })>((ref) {
  final db = ref.watch(databaseProvider);
  return ({
    required String customerName,
    required int quantity,
    required double totalAmount,
  }) async {
    if (quantity <= 0 || totalAmount <= 0) return;

    // We store the provided `quantity` in `meatCount` for now since the
    // unpaid entry only captures a single quantity field.
    await db.addSaleEntry(
      date: DateTime.now(),
      totalRevenue: totalAmount,
      customerName: customerName,
      purchaseDetails: 'Unpaid sale',
      isPaid: false,
      ndenguCount: 0,
      meatCount: quantity,
    );
  };
});

