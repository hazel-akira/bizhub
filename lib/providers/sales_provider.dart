import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

final salesProvider = FutureProvider.family<List<Sale>, DateTime>((
  ref,
  date,
) async {
  final db = ref.watch(databaseProvider);
  return db.getSalesForDate(date);
});

final todaySalesProvider = FutureProvider<List<Sale>>((ref) async {
  final db = ref.watch(databaseProvider);
  final sales = await db.getSalesForDate(DateTime.now());
  // Only count completed/paid sales as "revenue".
  return sales.where((s) => s.isPaid).toList();
});

final allSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllSales();
});

final salesListItemsProvider = FutureProvider<List<SaleListItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllSalesListItems();
});

final todaySalesListItemsProvider =
    FutureProvider<List<SaleListItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getSalesListItemsForDate(DateTime.now());
});

final markSalePaidProvider = Provider<Future<void> Function(int saleId)>((ref) {
  final db = ref.watch(databaseProvider);
  return (saleId) async {
    final paid = await db.totalPaymentsForSale(saleId);
    final sale = (await db.getAllSales()).firstWhere((s) => s.id == saleId);
    if (paid < sale.totalAmount) {
      await db.addPayment(
        saleId: saleId,
        amount: sale.totalAmount - paid,
        method: 'cash',
      );
    }
  };
});

final createQuickSaleProvider =
    Provider<Future<void> Function({
  required String customerName,
  required int ndenguCount,
  required int meatCount,
  required double totalAmount,
  required bool paid,
})>((ref) {
  final db = ref.watch(databaseProvider);
  return ({
    required customerName,
    required ndenguCount,
    required meatCount,
    required totalAmount,
    required paid,
  }) async {
    // Insert the sale first. For paid sales we then create a full payment,
    // which flips `is_paid` to true via Drift logic in `addPayment()`.
    final saleId = await db.addSaleEntry(
      date: DateTime.now(),
      totalRevenue: totalAmount,
      customerName: customerName,
      purchaseDetails: 'Quick sale',
      isPaid: false,
      paymentMethod: 'cash',
      ndenguCount: ndenguCount,
      meatCount: meatCount,
    );

    if (paid) {
      await db.addPayment(
        saleId: saleId,
        amount: totalAmount,
        method: 'cash',
      );
    }
  };
});
