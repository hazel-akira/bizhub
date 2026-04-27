import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/business_profile_provider.dart';
import '../providers/dashboard_provider.dart';
import 'orders_screen.dart';
import 'sales_screen.dart';
import 'profit_tracker_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessProfileAsync = ref.watch(businessProfileProvider);
    final businessName = businessProfileAsync.maybeWhen(
      data: (profile) => profile.name.isEmpty ? 'Akira Bites' : profile.name,
      orElse: () => 'Akira Bites',
    );
    final statsAsync = ref.watch(todayStatsProvider);
    final performanceAsync = ref.watch(todayPerformanceProvider);
    final alertsAsync = ref.watch(dashboardAlertsProvider);
    final insightsAsync = ref.watch(smartInsightsProvider);
    final now = DateTime.now();
    final dateLabel =
        '${now.day}/${now.month}/${now.year}';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayStatsProvider);
          ref.invalidate(todayPerformanceProvider);
        },
        child: statsAsync.when(
          data: (stats) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  businessName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
                const SizedBox(height: 16),
                performanceAsync.when(
                  loading: () => Card(
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
                            'Calculating today...',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  error: (e, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Today performance error: $e'),
                    ),
                  ),
                  data: (p) => Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                                'Today\'s Performance',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (!p.hasSales)
                            Text(
                              'No sales recorded today',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.shopping_bag_outlined,
                                        size: 18),
                                    const SizedBox(width: 8),
                                    Text('Samosas Sold: ${p.totalSamosasSold}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.money_outlined, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Revenue: KES ${p.totalRevenue.toStringAsFixed(0)}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.money_off_outlined, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Costs: KES ${p.totalCosts.toStringAsFixed(0)}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Builder(
                                  builder: (context) {
                                    final profitColor =
                                        p.netProfit >= 0 ? Colors.green : Colors.red;
                                    return Text(
                                      '👉 Profit: KES ${p.netProfit.toStringAsFixed(0)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: profitColor,
                                          ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p.netProfit >= 0
                                      ? 'Today you made KES ${p.netProfit.toStringAsFixed(0)} profit'
                                      : 'Today you lost KES ${p.netProfit.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: p.netProfit >= 0
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ProfitTrackerScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.details_outlined),
                                    label: const Text('View Details'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _StatCard(
                      title: 'Total Sales',
                      value: stats.totalSales,
                      icon: Icons.sell,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: 'Money Received',
                      value: stats.totalPayments,
                      icon: Icons.payments,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: 'Pending Payments',
                      value: stats.pendingPayments,
                      icon: Icons.pending_actions,
                      color: Colors.red,
                    ),
                    _StatCard(
                      title: 'Expenses',
                      value: stats.totalExpenses,
                      icon: Icons.money_off,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                alertsAsync.when(
                  data: (alerts) => Card(
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
                  ),
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
                            'Quick Insights',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Most sold item: ${insights.mostSoldItem}'),
                          Text('Best sales day: ${insights.bestSalesDay}'),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text('Insights error: $e'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const OrdersScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add Order'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SalesScreen()),
                          );
                        },
                        icon: const Icon(Icons.payments),
                        label: const Text('Record Payment'),
                      ),
                    ),
                  ],
                ),
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

class _StatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

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
