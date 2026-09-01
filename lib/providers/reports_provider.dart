import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_data_provider.dart';
import 'business_api_provider.dart';
import 'database_provider.dart';

final dailyProfitProvider =
    FutureProvider.family<double, DateTime>((ref, date) async {
  final api = ref.watch(businessApiProvider);
  if (api != null) {
    final dash = await ref.watch(apiDashboardProvider.future);
    return dash?.todayProfit ?? 0;
  }

  final db = ref.watch(databaseProvider);
  final sales = await db.getSalesForDate(date);
  final expenses = await db.getExpensesForDate(date);
  final totalSales = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  return totalSales - totalExpenses;
});

final weeklyProfitProvider =
    FutureProvider.family<double, DateTime>((ref, date) async {
  final api = ref.watch(businessApiProvider);
  if (api != null) {
    final sales = await ref.watch(apiSalesProvider.future);
    final expenses = await ref.watch(apiExpensesProvider.future);
    final weekStart = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    var totalSales = 0.0;
    for (final sale in sales) {
      final d = sale.saleDate;
      if (!d.isBefore(weekStart) && d.isBefore(weekEnd)) {
        totalSales += sale.totalAmount;
      }
    }

    var totalExpenses = 0.0;
    for (final expense in expenses) {
      final d = expense.expenseDate;
      if (!d.isBefore(weekStart) && d.isBefore(weekEnd)) {
        totalExpenses += expense.amount;
      }
    }

    return totalSales - totalExpenses;
  }

  final db = ref.watch(databaseProvider);
  final sales = await db.getSalesForWeek(date);
  final expenses = await db.getExpensesForWeek(date);
  final totalSales = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  return totalSales - totalExpenses;
});
