import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../core/constants.dart';
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
  return db.getSalesForDate(DateTime.now());
});

final allSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllSales();
});

final addSaleProvider = Provider<Future<void> Function(DateTime, int, int)>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return (date, ndenguCount, meatCount) async {
    final totalRevenue =
        (ndenguCount * SamosaPrices.ndenguPrice) +
        (meatCount * SamosaPrices.meatPrice);
    await db
        .into(db.sales)
        .insert(
          SalesCompanion.insert(
            date: date,
            ndenguCount: Value(ndenguCount),
            meatCount: Value(meatCount),
            totalRevenue: Value(totalRevenue),
          ),
        );
  };
});
