import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/layout.dart';
import '../database/app_database.dart';
import '../models/api_expense.dart';
import '../models/api_sale.dart';
import '../providers/api_data_provider.dart';
import '../providers/business_api_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/reports_provider.dart';
import '../providers/sales_provider.dart';
import '../services/backup_export.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useCloud = ref.watch(useCloudDataProvider);
    final now = DateTime.now();
    final dailyProfit = ref.watch(dailyProfitProvider(now));
    final weeklyProfit = ref.watch(weeklyProfitProvider(now));
    final salesAsync = useCloud
        ? ref.watch(apiSalesProvider)
        : ref.watch(allSalesProvider);
    final expensesAsync = useCloud
        ? ref.watch(apiExpensesProvider)
        : ref.watch(allExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            tooltip: 'Backup history',
            icon: const Icon(Icons.backup_outlined),
            onPressed: () => _backup(
              context,
              ref,
              useCloud: useCloud,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyProfitProvider(now));
          ref.invalidate(weeklyProfitProvider(now));
          if (useCloud) {
            ref.invalidate(apiSalesProvider);
            ref.invalidate(apiExpensesProvider);
            ref.invalidate(apiDashboardProvider);
          } else {
            ref.invalidate(allSalesProvider);
            ref.invalidate(allExpensesProvider);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'As of ${AppLayout.stamp(now)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ProfitCard(
                      title: 'Daily Profit',
                      async: dailyProfit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProfitCard(
                      title: 'Weekly Profit',
                      async: weeklyProfit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sales and expenses grouped by day (dd/mm/yyyy).',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 12),
              salesAsync.when(
                data: (sales) {
                  return expensesAsync.when(
                    data: (expenses) {
                      final transactions = useCloud
                          ? _mergeCloudTransactions(
                              sales as List<ApiSale>,
                              expenses as List<ApiExpense>,
                            )
                          : _mergeTransactions(
                              sales as List<Sale>,
                              expenses as List<Expense>,
                            );
                      if (transactions.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No history yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final group in _groupByDay(transactions)) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 6,
                              ),
                              child: Text(
                                group.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            ...group.items.map(
                              (t) => _TransactionTile(transaction: t),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _backup(
    BuildContext context,
    WidgetRef ref, {
    required bool useCloud,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final transactions = useCloud
          ? _mergeCloudTransactions(
              await ref.read(apiSalesProvider.future),
              await ref.read(apiExpensesProvider.future),
            )
          : _mergeTransactions(
              await ref.read(allSalesProvider.future),
              await ref.read(allExpensesProvider.future),
            );

      final buffer = StringBuffer(
        'date,time,type,description,amount,direction\n',
      );
      for (final t in transactions) {
        final local = t.date.toLocal();
        buffer.writeln(
          [
            BackupExport.cell(AppLayout.dateLabel(local)),
            BackupExport.cell(AppLayout.stamp(local).split(' ').last),
            BackupExport.cell(t.type),
            BackupExport.cell(t.description),
            BackupExport.cell(t.amount.toStringAsFixed(2)),
            BackupExport.cell(t.isIncome ? 'in' : 'out'),
          ].join(','),
        );
      }

      final stamp = AppLayout.dateLabel(DateTime.now()).replaceAll('/', '-');
      await BackupExport.shareCsv(
        filename: 'akira-flow-reports-$stamp.csv',
        csv: buffer.toString(),
        subject: 'Akira Flow reports backup $stamp',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  static List<_DayGroup> _groupByDay(List<_Transaction> transactions) {
    final groups = <String, _DayGroup>{};
    final order = <String>[];
    for (final t in transactions) {
      final label = AppLayout.dateLabel(t.date);
      if (!groups.containsKey(label)) {
        order.add(label);
        groups[label] = _DayGroup(label: label, items: []);
      }
      groups[label]!.items.add(t);
    }
    return [for (final key in order) groups[key]!];
  }

  static List<_Transaction> _mergeCloudTransactions(
    List<ApiSale> sales,
    List<ApiExpense> expenses,
  ) {
    final list = <_Transaction>[];
    for (final s in sales) {
      list.add(
        _Transaction(
          date: s.saleDate,
          type: 'Sale',
          description: s.itemsSummary.isNotEmpty
              ? s.itemsSummary
              : 'Sale #${s.id}',
          amount: s.totalAmount,
          isIncome: true,
        ),
      );
    }
    for (final e in expenses) {
      list.add(
        _Transaction(
          date: e.expenseDate,
          type: 'Expense',
          description: e.title,
          amount: e.amount,
          isIncome: false,
        ),
      );
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static List<_Transaction> _mergeTransactions(
    List<Sale> sales,
    List<Expense> expenses,
  ) {
    final list = <_Transaction>[];
    for (final s in sales) {
      list.add(
        _Transaction(
          date: s.createdAt,
          type: 'Sale',
          description: 'Ndengu: ${s.ndenguCount}, Meat: ${s.meatCount}',
          amount: s.totalAmount,
          isIncome: true,
        ),
      );
    }
    for (final e in expenses) {
      list.add(
        _Transaction(
          date: e.createdAt,
          type: 'Expense',
          description: e.name,
          amount: e.amount,
          isIncome: false,
        ),
      );
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}

class _DayGroup {
  _DayGroup({required this.label, required this.items});

  final String label;
  final List<_Transaction> items;
}

class _ProfitCard extends StatelessWidget {
  final String title;
  final AsyncValue<double> async;

  const _ProfitCard({required this.title, required this.async});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            async.when(
              data: (value) => FitValue(
                text: 'KES ${value.toStringAsFixed(0)}',
                alignment: Alignment.centerLeft,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: value >= 0 ? Colors.teal : Colors.red,
                ),
              ),
              loading: () => const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) =>
                  Text('Error', style: TextStyle(color: Colors.red[700])),
            ),
          ],
        ),
      ),
    );
  }
}

class _Transaction {
  final DateTime date;
  final String type;
  final String description;
  final double amount;
  final bool isIncome;

  _Transaction({
    required this.date,
    required this.type,
    required this.description,
    required this.amount,
    required this.isIncome,
  });
}

class _TransactionTile extends StatelessWidget {
  final _Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isIncome
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
          child: Icon(
            transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: transaction.isIncome ? Colors.green : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${transaction.type} • ${AppLayout.stamp(transaction.date)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Text(
          '${transaction.isIncome ? '+' : '-'} KES ${transaction.amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: transaction.isIncome ? Colors.green : Colors.orange,
          ),
        ),
      ),
    );
  }
}
