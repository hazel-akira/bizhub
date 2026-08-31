import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_data_provider.dart';
import 'business_api_provider.dart';
import 'database_provider.dart';

class UnpaidSaleRow {
  const UnpaidSaleRow({
    required this.saleId,
    required this.customerName,
    required this.outstanding,
    required this.createdAt,
  });

  final int saleId;
  final String customerName;
  final double outstanding;
  final DateTime createdAt;
}

class UnpaidCustomerDebtRow {
  final String customerName;
  final double outstanding;
  final DateTime date;
  final List<UnpaidSaleRow> unpaidSales;

  const UnpaidCustomerDebtRow({
    required this.customerName,
    required this.outstanding,
    required this.date,
    required this.unpaidSales,
  });
}

List<UnpaidCustomerDebtRow> _groupUnpaidRows(List<UnpaidSaleRow> unpaidSales) {
  final byCustomer = <String, List<UnpaidSaleRow>>{};
  for (final sale in unpaidSales) {
    byCustomer.putIfAbsent(sale.customerName, () => []).add(sale);
  }

  final result = <UnpaidCustomerDebtRow>[];
  for (final entry in byCustomer.entries) {
    final salesForCustomer = entry.value
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final outstanding = salesForCustomer.fold<double>(
      0,
      (sum, sale) => sum + sale.outstanding,
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

  result.sort((a, b) => b.date.compareTo(a.date));
  return result;
}

Future<List<UnpaidSaleRow>> _loadLocalUnpaidSales(Ref ref) async {
  final db = ref.watch(databaseProvider);
  final sales = await db.getAllSalesListItems();
  final payments = await db.getAllPayments();

  final paidBySaleId = <int, double>{};
  for (final payment in payments) {
    paidBySaleId[payment.saleId] =
        (paidBySaleId[payment.saleId] ?? 0) + payment.amount;
  }

  final rows = sales
      .where((item) => !item.sale.isPaid)
      .map((item) {
        final paid = paidBySaleId[item.sale.id] ?? 0;
        final outstanding = item.sale.totalAmount - paid;
        return UnpaidSaleRow(
          saleId: item.sale.id,
          customerName: item.customerName,
          outstanding: outstanding,
          createdAt: item.sale.createdAt,
        );
      })
      .where((row) => row.outstanding > 0)
      .toList();

  rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return rows;
}

Future<List<UnpaidSaleRow>> _loadCloudUnpaidSales(Ref ref) async {
  final api = ref.watch(businessApiProvider);
  if (api == null) return [];

  final sales = await api.getUnpaidSales();
  return sales
      .where((sale) => sale.outstanding > 0)
      .map(
        (sale) => UnpaidSaleRow(
          saleId: sale.id,
          customerName: sale.displayLabel,
          outstanding: sale.outstanding,
          createdAt: sale.saleDate,
        ),
      )
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

final unpaidSalesWithOutstandingProvider =
    FutureProvider<List<UnpaidSaleRow>>((ref) async {
  if (ref.watch(useCloudDataProvider)) {
    return _loadCloudUnpaidSales(ref);
  }
  return _loadLocalUnpaidSales(ref);
});

final unpaidCustomersDebtProvider =
    FutureProvider<List<UnpaidCustomerDebtRow>>((ref) async {
  final rows = await ref.watch(unpaidSalesWithOutstandingProvider.future);
  return _groupUnpaidRows(rows);
});

final recordSalePaymentProvider = Provider<
    Future<void> Function({
      required int saleId,
      required double amount,
      required String method,
    })>((ref) {
  return ({required int saleId, required double amount, required String method}) async {
    final api = ref.read(businessApiProvider);
    if (api != null) {
      await api.recordSalePayment(
        saleId: saleId,
        amount: amount,
        paymentMethod: method,
      );
      ref.invalidate(apiSalesProvider);
      ref.invalidate(apiDashboardProvider);
      ref.invalidate(apiTodaySalesProvider);
      ref.invalidate(unpaidCustomersDebtProvider);
      ref.invalidate(unpaidSalesWithOutstandingProvider);
      return;
    }

    final db = ref.read(databaseProvider);
    await db.addPayment(saleId: saleId, amount: amount, method: method);
  };
});

final addUnpaidSaleProvider = Provider<
    Future<void> Function({
      required String customerName,
      required int quantity,
      required double totalAmount,
    })>((ref) {
  return ({
    required String customerName,
    required int quantity,
    required double totalAmount,
  }) async {
    if (quantity <= 0 || totalAmount <= 0) return;

    final db = ref.read(databaseProvider);
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

void refreshUnpaidProviders(WidgetRef ref) {
  ref.invalidate(unpaidCustomersDebtProvider);
  ref.invalidate(unpaidSalesWithOutstandingProvider);
  ref.invalidate(apiSalesProvider);
  ref.invalidate(apiDashboardProvider);
  ref.invalidate(apiTodaySalesProvider);
}
