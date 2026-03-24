import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';

final dailyProfitProvider = FutureProvider.family<double, DateTime>((ref, date) async {
  final db = ref.watch(databaseProvider);
  final sales = await db.getSalesForDate(date);
  final expenses = await db.getExpensesForDate(date);
  final totalSales = sales.fold<double>(0, (sum, s) => sum + s.totalRevenue);
  final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  return totalSales - totalExpenses;
});

final weeklyProfitProvider = FutureProvider.family<double, DateTime>((ref, date) async {
  final db = ref.watch(databaseProvider);
  final sales = await db.getSalesForWeek(date);
  final expenses = await db.getExpensesForWeek(date);
  final totalSales = sales.fold<double>(0, (sum, s) => sum + s.totalRevenue);
  final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  return totalSales - totalExpenses;
});
