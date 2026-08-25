import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/business_type_config.dart';
import '../providers/api_data_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/business_api_provider.dart';
import '../providers/business_profile_provider.dart';
import '../providers/dashboard_provider.dart';
import 'inventory_screen.dart';
import 'orders_screen.dart';
import 'profit_tracker_screen.dart';
import 'sales_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useCloud = ref.watch(useCloudDataProvider);
    final auth = ref.watch(authProvider);
    final config = ref.watch(businessTypeConfigProvider);
    final statsAsync = ref.watch(todayStatsProvider);
    final performanceAsync = ref.watch(todayPerformanceProvider);
    final alertsAsync = ref.watch(dashboardAlertsProvider);
    final insightsAsync = ref.watch(smartInsightsProvider);
    final topProductsAsync = ref.watch(apiTopProductsProvider);
    final now = DateTime.now();
    final dateLabel = '${now.day}/${now.month}/${now.year}';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayStatsProvider);
          ref.invalidate(todayPerformanceProvider);
          ref.invalidate(apiDashboardProvider);
          ref.invalidate(apiTodaySalesProvider);
          ref.invalidate(apiProductsProvider);
          ref.invalidate(smartInsightsProvider);
          ref.invalidate(apiTopProductsProvider);
          await ref.read(authProvider.notifier).refreshProfile();
        },
        child: statsAsync.when(
          data: (stats) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  businessName: auth.user?.businessName ?? 'Akira Flow',
                  categoryLabel: config.label,
                  dateLabel: dateLabel,
                  useCloud: useCloud,
                  config: config,
                ),
                const SizedBox(height: 16),
                performanceAsync.when(
                  loading: () => const _LoadingPerformanceCard(),
                  error: (e, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Today performance error: $e'),
                    ),
                  ),
                  data: (p) => _PerformanceCard(
                    config: config,
                    performance: p,
                    useCloud: useCloud,
                  ),
                ),
                const SizedBox(height: 12),
                _StatsGrid(config: config, stats: stats),
                if (!config.isFoodBusiness && useCloud) ...[
                  const SizedBox(height: 12),
                  topProductsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (top) {
                      if (top.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your ${config.productNoun}s',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(config.emptyCatalogHint),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const InventoryScreen(),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Open inventory'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Top sellers today',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...top.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Icon(config.productIcon, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(item.name)),
                                      Text('${item.qty} sold'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                alertsAsync.when(
                  data: (alerts) => _AlertsCard(alerts: alerts),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text('Alerts error: $e'),
                ),
                const SizedBox(height: 12),
                insightsAsync.when(
                  data: (insights) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick insights',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            config.isFoodBusiness
                                ? 'Most sold: ${insights.mostSoldItem}'
                                : 'Top product: ${insights.mostSoldItem}',
                          ),
                          if (config.isFoodBusiness)
                            Text('Best sales day: ${insights.bestSalesDay}'),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text('Insights error: $e'),
                ),
                const SizedBox(height: 12),
                _QuickActions(config: config),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.businessName,
    required this.categoryLabel,
    required this.dateLabel,
    required this.useCloud,
    required this.config,
  });

  final String businessName;
  final String categoryLabel;
  final String dateLabel;
  final bool useCloud;
  final BusinessTypeConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                config.isFoodBusiness ? Icons.restaurant : Icons.storefront,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    categoryLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            if (useCloud)
              const Chip(
                avatar: Icon(Icons.cloud_done, size: 16),
                label: Text('Synced'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          dateLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
        ),
      ],
    );
  }
}

class _LoadingPerformanceCard extends StatelessWidget {
  const _LoadingPerformanceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Calculating today…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.config,
    required this.performance,
    required this.useCloud,
  });

  final BusinessTypeConfig config;
  final ({
    bool hasSales,
    int totalUnitsSold,
    double totalRevenue,
    double totalCosts,
    double netProfit,
    bool hasProfitRecord,
    int productsCount,
    String? topProductToday,
  }) performance;
  final bool useCloud;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up),
                const SizedBox(width: 10),
                Text(
                  "Today's performance",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!performance.hasSales && performance.productsCount == 0)
              Text(
                config.emptyCatalogHint,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (!performance.hasSales)
              Text(
                'No sales recorded today',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              )
            else ...[
              _MetricRow(
                icon: Icons.shopping_bag_outlined,
                label: config.unitsSoldLabel,
                value: '${performance.totalUnitsSold}',
              ),
              if (!config.isFoodBusiness &&
                  performance.topProductToday != null) ...[
                const SizedBox(height: 8),
                _MetricRow(
                  icon: Icons.star_outline,
                  label: 'Top seller',
                  value: performance.topProductToday!,
                ),
              ],
              const SizedBox(height: 8),
              _MetricRow(
                icon: Icons.money_outlined,
                label: 'Revenue',
                value: 'KES ${performance.totalRevenue.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 8),
              _MetricRow(
                icon: Icons.money_off_outlined,
                label: 'Expenses',
                value: 'KES ${performance.totalCosts.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 10),
              Text(
                'Profit: KES ${performance.netProfit.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: performance.netProfit >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
              ),
            ],
            if (config.isFoodBusiness && performance.hasSales) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfitTrackerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.details_outlined),
                  label: const Text('Profit details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text('$label: '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.config, required this.stats});

  final BusinessTypeConfig config;
  final ({
    double totalSales,
    double totalPayments,
    double pendingPayments,
    double totalExpenses,
    double profit,
    int productsCount,
    int lowStockCount,
  }) stats;

  @override
  Widget build(BuildContext context) {
    if (config.isFoodBusiness) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: [
          _StatCard(
            title: 'Total sales',
            value: stats.totalSales,
            icon: Icons.sell,
            color: Colors.blue,
          ),
          _StatCard(
            title: 'Money received',
            value: stats.totalPayments,
            icon: Icons.payments,
            color: Colors.green,
          ),
          _StatCard(
            title: 'Pending payments',
            value: stats.pendingPayments,
            icon: Icons.pending_actions,
            color: Colors.red,
          ),
          _StatCard(
            title: 'Expenses',
            value: stats.totalExpenses,
            icon: Icons.money_off,
            color: Colors.orange,
          ),
        ],
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _StatCard(
          title: "Today's sales",
          value: stats.totalSales,
          icon: Icons.point_of_sale,
          color: Colors.blue,
        ),
        _StatCard(
          title: "Today's profit",
          value: stats.profit,
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        _IntStatCard(
          title: 'Products',
          value: stats.productsCount,
          icon: Icons.inventory_2_outlined,
          color: Colors.indigo,
        ),
        _IntStatCard(
          title: 'Low stock',
          value: stats.lowStockCount,
          icon: Icons.warning_amber_outlined,
          color: stats.lowStockCount > 0 ? Colors.red : Colors.grey,
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.config});

  final BusinessTypeConfig config;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              if (config.showOrdersNav) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SalesScreen()),
                );
              }
            },
            icon: Icon(config.primaryQuickActionIcon),
            label: Text(config.primaryQuickActionLabel),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              if (config.showInventoryNav) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SalesScreen()),
                );
              }
            },
            icon: Icon(config.secondaryQuickActionIcon),
            label: Text(config.secondaryQuickActionLabel),
          ),
        ),
      ],
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts});

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alerts',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (alerts.isEmpty) const Text('No critical alerts'),
            ...alerts.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(i)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final double value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              radius: 20,
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'KES ${value.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntStatCard extends StatelessWidget {
  const _IntStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              radius: 20,
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
