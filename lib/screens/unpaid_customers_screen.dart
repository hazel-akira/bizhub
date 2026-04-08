import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/unpaid_customers_provider.dart';

class UnpaidCustomersScreen extends ConsumerStatefulWidget {
  const UnpaidCustomersScreen({super.key});

  @override
  ConsumerState<UnpaidCustomersScreen> createState() =>
      _UnpaidCustomersScreenState();
}

class _UnpaidCustomersScreenState
    extends ConsumerState<UnpaidCustomersScreen> {
  Future<void> _markAsPaid(UnpaidCustomerDebtRow row) async {
    if (row.unpaidSales.isEmpty) return;

    // Settle each unpaid sale for this customer.
    for (final s in row.unpaidSales) {
      if (s.outstanding <= 0) continue;
      await ref.read(addPaymentProvider)(
        saleId: s.sale.id,
        amount: s.outstanding,
        method: 'cash',
      );
    }

    _refreshUI();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer marked as paid')),
    );
  }

  Future<void> _recordPartialPayment(UnpaidCustomerDebtRow row) async {
    final amountController = TextEditingController();
    String method = 'cash';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('Partial payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${row.customerName}\nOutstanding: KES ${row.outstanding.toStringAsFixed(0)}',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Payment amount (KES)',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      if (n > row.outstanding) {
                        return 'Cannot exceed outstanding';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: const InputDecoration(labelText: 'Method'),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'mpesa', child: Text('MPESA')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => method = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(
                    amountController.text.trim(),
                  );
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter amount')),
                    );
                    return;
                  }
                  if (amount > row.outstanding) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Amount exceeds outstanding')),
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) {
      amountController.dispose();
      return;
    }

    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    amountController.dispose();
    if (amount <= 0) return;

    // Allocate partial payment from oldest unpaid sales first.
    var remaining = amount;
    for (final s in row.unpaidSales) {
      if (remaining <= 0) break;
      final pay = s.outstanding < remaining ? s.outstanding : remaining;
      if (pay <= 0) continue;
      await ref.read(addPaymentProvider)(
        saleId: s.sale.id,
        amount: pay,
        method: method,
      );
      remaining -= pay;
    }

    _refreshUI();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment recorded')),
    );
  }

  void _refreshUI() {
    ref.invalidate(unpaidCustomersDebtProvider);
    ref.invalidate(salesListItemsProvider);
    ref.invalidate(allSalesProvider);
    ref.invalidate(allPaymentsProvider);
    ref.invalidate(todayStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final unpaidAsync = ref.watch(unpaidCustomersDebtProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unpaid Customers'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: unpaidAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Unpaid sales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'All caught up 🎉',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                else
                  ...rows.map((row) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Outstanding: KES ${row.outstanding.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Date: ${_formatDate(row.date)}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => _markAsPaid(row),
                                      child: const Text('Mark as Paid'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _recordPartialPayment(row),
                                      child: const Text('Partial Payment'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

