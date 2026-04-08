import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/sales_provider.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? _selectedSaleId;
  String _method = 'cash';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate() || _selectedSaleId == null) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;
    await ref.read(addPaymentProvider)(
          saleId: _selectedSaleId!,
          amount: amount,
          method: _method,
        );
    ref.invalidate(allPaymentsProvider);
    ref.invalidate(allSalesProvider);
    ref.invalidate(todayStatsProvider);
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(allSalesProvider);
    final paymentsAsync = ref.watch(allPaymentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            salesAsync.when(
              data: (sales) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _selectedSaleId,
                          decoration: const InputDecoration(labelText: 'Sale'),
                          items: sales
                              .map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      '${s.customerName} • KES ${s.totalAmount.toStringAsFixed(0)}',
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedSaleId = v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          decoration:
                              const InputDecoration(labelText: 'Amount (KES)'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Enter valid amount';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _method,
                          decoration:
                              const InputDecoration(labelText: 'Method'),
                          items: const [
                            DropdownMenuItem(value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'mpesa', child: Text('MPESA')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _method = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _recordPayment,
                          child: const Text('Record payment'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            paymentsAsync.when(
              data: (payments) => Column(
                children: payments
                    .map(
                      (p) => Card(
                        child: ListTile(
                          title: Text('KES ${p.amount.toStringAsFixed(0)}'),
                          subtitle: Text('${p.method} • Sale #${p.saleId}'),
                        ),
                      ),
                    )
                    .toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
