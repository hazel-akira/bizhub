import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

final selectedProductionDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final todayProductionBatchProvider = FutureProvider<ProductionBatche?>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getBatchForDate(DateTime.now());
});

final productionBatchProvider = FutureProvider<ProductionBatche?>((ref) async {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedProductionDateProvider);
  return db.getBatchForDate(date);
});

final productionSummaryProvider = FutureProvider<ProductionSummary>((ref) async {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedProductionDateProvider);
  return db.getProductionSummary(date);
});

final saveProductionBatchProvider = Provider<
    Future<void> Function({
      required DateTime date,
      required int ndenguPrepared,
      required int meatPrepared,
    })>((ref) {
  final db = ref.watch(databaseProvider);
  return ({required date, required ndenguPrepared, required meatPrepared}) async {
    await db.saveDailyProduction(
      date: date,
      ndenguPreparedQty: ndenguPrepared,
      meatPreparedQty: meatPrepared,
    );
  };
});
