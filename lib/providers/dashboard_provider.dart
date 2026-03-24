import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sales_provider.dart';
import 'expenses_provider.dart';

final todayStatsProvider = FutureProvider<({double sales, double expenses, double profit})>((ref) async {
  final sales = await ref.watch(todaySalesProvider.future);
  final expenses = await ref.watch(todayExpensesProvider.future);

  final totalSales = sales.fold<double>(0, (sum, s) => sum + s.totalRevenue);
  final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  final profit = totalSales - totalExpenses;

  return (sales: totalSales, expenses: totalExpenses, profit: profit);
});
