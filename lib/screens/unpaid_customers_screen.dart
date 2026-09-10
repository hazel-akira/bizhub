import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/layout.dart';
import '../providers/customers_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/business_api_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/unpaid_customers_provider.dart';

class UnpaidCustomersScreen extends ConsumerStatefulWidget {
  const UnpaidCustomersScreen({super.key});

  @override
  ConsumerState<UnpaidCustomersScreen> createState() =>
      _UnpaidCustomersScreenState();
}

class _UnpaidCustomersScreenState extends ConsumerState<UnpaidCustomersScreen> {
  bool _busy = false;

  String _paymentError(Object e) {
    final raw = e.toString().replaceFirst('ApiException: ', '');
    if (raw.toLowerCase().contains('timed out')) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return raw;
  }

  Future<void> _markAsPaid(UnpaidCustomerDebtRow row) async {
    if (row.unpaidSales.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      for (final sale in row.unpaidSales) {
        if (sale.outstanding <= 0) continue;
        await ref.read(recordSalePaymentProvider)(
          saleId: sale.saleId,
          amount: sale.outstanding,
          method: 'cash',
        );
      }
      _refreshUI();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer marked as paid')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_paymentError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recordPartialPayment(UnpaidCustomerDebtRow row) async {
    if (_busy) return;

    final result = await showDialog<(double, String)?>(
      context: context,
      builder: (ctx) => _PartialPaymentDialog(
        customerName: row.customerName,
        outstanding: row.outstanding,
      ),
    );
    if (result == null || !mounted) return;

    final amount = result.$1;
    final method = result.$2;
    if (amount <= 0) return;

    setState(() => _busy = true);
    try {
      var remaining = amount;
      for (final sale in row.unpaidSales) {
        if (remaining <= 0) break;
        final pay =
            sale.outstanding < remaining ? sale.outstanding : remaining;
        if (pay <= 0) continue;
        await ref.read(recordSalePaymentProvider)(
          saleId: sale.saleId,
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_paymentError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refreshUI() {
    refreshUnpaidProviders(ref);
    refreshCustomerRelatedProviders(ref);
    ref.invalidate(todayStatsProvider);

    if (!ref.read(useCloudDataProvider)) {
      ref.invalidate(salesListItemsProvider);
      ref.invalidate(allSalesProvider);
      ref.invalidate(allPaymentsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unpaidAsync = ref.watch(unpaidCustomersDebtProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unpaid Customers'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshUI();
          await ref.read(unpaidCustomersDebtProvider.future);
        },
        child: unpaidAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: $e'),
              ),
            ],
          ),
          data: (rows) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Credit / unpaid sales',
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
                  ...rows.map(
                    (row) => Card(
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
                            if (row.unpaidSales.length > 1) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${row.unpaidSales.length} unpaid sales',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                            const SizedBox(height: 12),
                            AdaptiveButtonRow(
                              children: [
                                FilledButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _markAsPaid(row),
                                  child: const Text(
                                    'Mark paid',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _recordPartialPayment(row),
                                  child: const Text(
                                    'Pay partially',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _PartialPaymentDialog extends StatefulWidget {
  const _PartialPaymentDialog({
    required this.customerName,
    required this.outstanding,
  });

  final String customerName;
  final double outstanding;

  @override
  State<_PartialPaymentDialog> createState() => _PartialPaymentDialogState();
}

class _PartialPaymentDialogState extends State<_PartialPaymentDialog> {
  late final TextEditingController _amount;
  String _method = 'cash';
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter amount');
      return;
    }
    if (amount > widget.outstanding) {
      setState(() => _error = 'Amount exceeds outstanding');
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.pop(context, (amount, _method));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pay partially'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.customerName}\nOutstanding: KES ${widget.outstanding.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Payment amount (KES)',
                errorText: _error,
              ),
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 16),
            Text('Method', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Cash'),
                  selected: _method == 'cash',
                  onSelected: (_) => setState(() => _method = 'cash'),
                ),
                ChoiceChip(
                  label: const Text('M-Pesa'),
                  selected: _method == 'mpesa',
                  onSelected: (_) => setState(() => _method = 'mpesa'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
