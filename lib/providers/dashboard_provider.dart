import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_data_provider.dart';
import 'business_api_provider.dart';
import 'business_profile_provider.dart';
import 'database_provider.dart';
import 'expenses_provider.dart';
import 'payments_provider.dart';
import 'profit_tracker_provider.dart';
import 'sales_provider.dart';

final todayStatsProvider = FutureProvider<
    ({
      double totalSales,
      double totalPayments,
      double pendingPayments,
      double totalExpenses,
      double profit,
      int productsCount,
      int lowStockCount,
    })>((ref) async {
  final api = ref.watch(businessApiProvider);
  if (api != null) {
    final dash = await ref.watch(apiDashboardProvider.future);
    return (
      totalSales: dash?.todaySales ?? 0,
      totalPayments: dash?.todaySales ?? 0,
      pendingPayments: dash?.pendingCredit ?? 0,
      totalExpenses: dash?.todayExpenses ?? 0,
      profit: dash?.todayProfit ?? 0,
      productsCount: dash?.productsCount ?? 0,
      lowStockCount: dash?.lowStockCount ?? 0,
    );
  }

  final sales = await ref.watch(allSalesProvider.future);
  final payments = await ref.watch(allPaymentsProvider.future);
  final expenses = await ref.watch(allExpensesProvider.future);

  final totalSales = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  final totalPayments = payments.fold<double>(0, (sum, p) => sum + p.amount);
  final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  final pending = totalSales - totalPayments;
  final profit = totalPayments - totalExpenses;

  return (
    totalSales: totalSales,
    totalPayments: totalPayments,
    pendingPayments: pending,
    totalExpenses: totalExpenses,
    profit: profit,
    productsCount: 0,
    lowStockCount: 0,
  );
});

final dashboardAlertsProvider = FutureProvider<List<String>>((ref) async {
  final stats = await ref.watch(todayStatsProvider.future);
  final config = ref.watch(businessTypeConfigProvider);
  final alerts = <String>[];

  if (stats.pendingPayments > 0) {
    alerts.add('You have unpaid sales');
  }
  if (stats.totalSales > 0 && stats.totalExpenses >= (stats.totalSales * 0.7)) {
    alerts.add('Warning: expenses are high compared to sales');
  }
  if (!config.isFoodBusiness && stats.lowStockCount > 0) {
    alerts.add(
      '${stats.lowStockCount} ${config.productNoun}(s) running low on stock',
    );
  }
  if (!config.isFoodBusiness && stats.productsCount == 0) {
    alerts.add('No ${config.productNoun}s in inventory — add products first');
  }

  return alerts;
});

final smartInsightsProvider =
    FutureProvider<({String mostSoldItem, String bestSalesDay})>((ref) async {
  final config = ref.watch(businessTypeConfigProvider);
  final api = ref.watch(businessApiProvider);

  if (api != null) {
    final dash = await ref.watch(apiDashboardProvider.future);
    return (
      mostSoldItem: dash?.topProductToday ?? 'No sales yet today',
      bestSalesDay: (dash?.salesCount ?? 0) > 0 ? 'Today' : 'N/A',
    );
  }

  if (!config.isFoodBusiness) {
    return (mostSoldItem: 'Sign in to track products', bestSalesDay: 'N/A');
  }

  final db = ref.watch(databaseProvider);
  final sales = await db.getAllSales();
  var ndenguQty = 0;
  var meatQty = 0;
  final byWeekday = <int, double>{};
  for (final s in sales) {
    ndenguQty += s.ndenguCount;
    meatQty += s.meatCount;
    byWeekday[s.createdAt.weekday] =
        (byWeekday[s.createdAt.weekday] ?? 0) + s.totalAmount;
  }
  final mostSold = ndenguQty >= meatQty ? 'Ndengu Samosa' : 'Meat Samosa';
  final high = byWeekday.entries.isEmpty
      ? null
      : byWeekday.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  const names = {
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };
  return (
    mostSoldItem: mostSold,
    bestSalesDay: high == null ? 'N/A' : (names[high] ?? 'N/A'),
  );
});

final todayPerformanceProvider = FutureProvider<
    ({
      bool hasSales,
      int totalUnitsSold,
      double totalRevenue,
      double totalCosts,
      double netProfit,
      bool hasProfitRecord,
      int productsCount,
      String? topProductToday,
    })>((ref) async {
  final api = ref.watch(businessApiProvider);
  if (api != null) {
    final dash = await ref.watch(apiDashboardProvider.future);
    return (
      hasSales: (dash?.todaySales ?? 0) > 0,
      totalUnitsSold: dash?.todayUnitsSold ?? 0,
      totalRevenue: dash?.todaySales ?? 0,
      totalCosts: dash?.todayExpenses ?? 0,
      netProfit: dash?.todayProfit ?? 0,
      hasProfitRecord: false,
      productsCount: dash?.productsCount ?? 0,
      topProductToday: dash?.topProductToday,
    );
  }

  final config = ref.watch(businessTypeConfigProvider);
  final sales = await ref.watch(todaySalesProvider.future);
  final hasSales = sales.isNotEmpty;
  if (!hasSales) {
    return (
      hasSales: false,
      totalUnitsSold: 0,
      totalRevenue: 0.0,
      totalCosts: 0.0,
      netProfit: 0.0,
      hasProfitRecord: false,
      productsCount: 0,
      topProductToday: null,
    );
  }

  final totalUnitsSold = config.isFoodBusiness
      ? sales.fold<int>(0, (sum, s) => sum + s.ndenguCount + s.meatCount)
      : sales.length;
  final totalRevenue =
      sales.fold<double>(0, (sum, s) => sum + s.totalAmount);

  final profitRecord = await ref.watch(todayProfitRecordProvider.future);
  final totalCosts = profitRecord?.totalCosts ?? 0.0;
  final netProfit = totalRevenue - totalCosts;

  return (
    hasSales: true,
    totalUnitsSold: totalUnitsSold,
    totalRevenue: totalRevenue,
    totalCosts: totalCosts,
    netProfit: netProfit,
    hasProfitRecord: profitRecord != null,
    productsCount: 0,
    topProductToday: null,
  );
});

final apiTopProductsProvider = FutureProvider<List<({String name, int qty})>>(
  (ref) async {
    final sales = await ref.watch(apiTodaySalesProvider.future);
    final counts = <String, int>{};
    for (final sale in sales) {
      for (final item in sale.items) {
        counts[item.productName] =
            (counts[item.productName] ?? 0) + item.quantity;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(5)
        .map((e) => (name: e.key, qty: e.value))
        .toList();
  },
);
