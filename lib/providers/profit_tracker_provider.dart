import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

final profitRecordsProvider = FutureProvider<List<ProfitRecord>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllProfitRecords();
});

final todayProfitRecordProvider =
    FutureProvider<ProfitRecord?>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getProfitRecordForDate(DateTime.now());
});

final addProfitRecordProvider = Provider<
    Future<void> Function({
      required int samosasPrepared,
      required double pricePerSamosa,
      required double meatCost,
      required double dhaniaCost,
      required double flourWeeklyCost,
      required double onionsWeeklyCost,
      required double oilMonthlyCost,
      required double gasCost,
      required double transportCost,
      required double labourCost,
      required double revenue,
      required double totalCosts,
      required double profit,
    })>((ref) {
  final db = ref.watch(databaseProvider);
  return ({
    required int samosasPrepared,
    required double pricePerSamosa,
    required double meatCost,
    required double dhaniaCost,
    required double flourWeeklyCost,
    required double onionsWeeklyCost,
    required double oilMonthlyCost,
    required double gasCost,
    required double transportCost,
    required double labourCost,
    required double revenue,
    required double totalCosts,
    required double profit,
  }) async {
    await db.saveProfitRecord(
      date: DateTime.now(),
      samosasPrepared: samosasPrepared,
      pricePerSamosa: pricePerSamosa,
      meatCost: meatCost,
      dhaniaCost: dhaniaCost,
      flourWeeklyCost: flourWeeklyCost,
      onionsWeeklyCost: onionsWeeklyCost,
      oilMonthlyCost: oilMonthlyCost,
      gasCost: gasCost,
      transportCost: transportCost,
      labourCost: labourCost,
      revenue: revenue,
      totalCosts: totalCosts,
      profit: profit,
    );
  };
});

