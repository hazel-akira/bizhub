import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/sales_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyProfit = ref.watch(dailyProfitProvider(DateTime.now()));
    final weeklyProfit = ref.watch(weeklyProfitProvider(DateTime.now()));
    final salesAsync = ref.watch(allSalesProvider);
    final expensesAsync = ref.watch(allExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyProfitProvider(DateTime.now()));
          ref.invalidate(weeklyProfitProvider(DateTime.now()));
          ref.invalidate(allSalesProvider);
          ref.invalidate(allExpensesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                'All Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              salesAsync.when(
                data: (sales) {
                  return expensesAsync.when(
                    data: (expenses) {
                      final transactions = _mergeTransactions(sales, expenses);
                      if (transactions.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No transactions yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: transactions
                            .map((t) => _TransactionTile(transaction: t))
                            .toList(),
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

  List<_Transaction> _mergeTransactions(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            async.when(
              data: (value) => Text(
                'KES ${value.toStringAsFixed(0)}',
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
        title: Text(transaction.description),
        subtitle: Text(
          '${transaction.type} • ${_formatDate(transaction.date)}',
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

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
