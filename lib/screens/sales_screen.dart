import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/sales_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/unpaid_customers_provider.dart';
import '../providers/payments_provider.dart';
import '../core/constants.dart';
import '../services/sales_reminder_service.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  static const _walkInCustomer = 'Walk-in Customer';

  String _selectedProduct = 'meat'; // meat | ndengu
  int _quantity = 1;
  String _selectedCustomerName = _walkInCustomer;
  bool _paymentIsPaidChip = true;
  bool _isSubmittingQuickSale = false;

  double get _unitPrice => _selectedProduct == 'meat'
      ? SamosaPrices.meatPrice
      : SamosaPrices.ndenguPrice;

  int get _ndenguCount => _selectedProduct == 'ndengu' ? _quantity : 0;
  int get _meatCount => _selectedProduct == 'meat' ? _quantity : 0;
  double get _totalAmount => _quantity * _unitPrice;

  Future<void> _recordPaymentDialog(SaleListItem item) async {
    final amountCtrl =
        TextEditingController(text: item.sale.totalAmount.toStringAsFixed(0));
    String method = 'cash';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Payment amount',
                  prefixText: 'KES ',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(labelText: 'Payment method'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'mpesa', child: Text('MPESA')),
                ],
                onChanged: (v) {
                  if (v != null) setLocal(() => method = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;
    await ref.read(addPaymentProvider)(
          saleId: item.sale.id,
          amount: amount,
          method: method,
        );
    _refreshSalesUI();
  }

  void _refreshSalesUI() {
    ref.invalidate(todaySalesListItemsProvider);
    ref.invalidate(allSalesProvider);
    ref.invalidate(allPaymentsProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(todaySalesProvider);
    ref.invalidate(unpaidCustomersDebtProvider);
  }

  Future<void> _markPaidQuick(int saleId) async {
    final markPaid = ref.read(markSalePaidProvider);
    await markPaid(saleId);
    _refreshSalesUI();
  }

  Future<void> _submitQuickSale({required bool paid}) async {
    if (_isSubmittingQuickSale) return;
    if (_quantity <= 0) return;

    setState(() => _isSubmittingQuickSale = true);
    try {
      final saleTotal = _totalAmount;
      final customerName = _selectedCustomerName.trim().isEmpty
          ? _walkInCustomer
          : _selectedCustomerName.trim();

      await ref.read(createQuickSaleProvider)(
        customerName: customerName,
        ndenguCount: _ndenguCount,
        meatCount: _meatCount,
        totalAmount: saleTotal,
        paid: paid,
      );
      try {
        await SalesReminderService.instance
            .syncDailyReminder(hasSalesToday: true);
      } catch (_) {
        // Reminder failure should never block completing a sale.
      }

      _refreshSalesUI();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paid ? 'Sale completed' : 'Sale saved as unpaid'),
        ),
      );
      setState(() => _quantity = 1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingQuickSale = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todaySalesItemsAsync = ref.watch(todaySalesListItemsProvider);
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: todaySalesItemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          final recent = items.take(10).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Today Quick Sale',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          key: ValueKey(_selectedProduct),
                          initialValue: _selectedProduct,
                          decoration: const InputDecoration(
                            labelText: 'Select Product',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'meat',
                              child: Text('Meat Samosa (KES 40)'),
                            ),
                            DropdownMenuItem(
                              value: 'ndengu',
                              child: Text('Ndengu Samosa (KES 20)'),
                            ),
                          ],
                          onChanged: _isSubmittingQuickSale
                              ? null
                              : (v) {
                                  if (v == null) return;
                                  setState(() => _selectedProduct = v);
                                },
                        ),

                        const SizedBox(height: 12),

                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Quantity',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _isSubmittingQuickSale
                                      ? null
                                      : () {
                                          if (_quantity <= 1) return;
                                          setState(() => _quantity--);
                                        },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$_quantity',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                IconButton(
                                  onPressed: _isSubmittingQuickSale
                                      ? null
                                      : () {
                                          setState(() => _quantity++);
                                        },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        Text(
                          'Total: KES ${_totalAmount.toStringAsFixed(0)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),

                        const SizedBox(height: 12),

                        customersAsync.when(
                          data: (customers) {
                            final menuItems = <DropdownMenuItem<String>>[
                              const DropdownMenuItem(
                                value: _walkInCustomer,
                                child: Text(_walkInCustomer),
                              ),
                              ...customers.map(
                                (c) => DropdownMenuItem<String>(
                                  value: c.name,
                                  child: Text(c.name),
                                ),
                              ),
                            ];

                            final selectedValue = menuItems.any(
                                  (e) => e.value == _selectedCustomerName,
                                )
                                ? _selectedCustomerName
                                : _walkInCustomer;

                            return DropdownButtonFormField<String>(
                              key: ValueKey(selectedValue),
                              initialValue: selectedValue,
                              decoration: const InputDecoration(
                                labelText: 'Select Customer',
                                border: OutlineInputBorder(),
                              ),
                              items: menuItems,
                              onChanged: _isSubmittingQuickSale
                                  ? null
                                  : (v) {
                                      if (v == null) return;
                                      setState(() => _selectedCustomerName = v);
                                    },
                            );
                          },
                          loading: () => DropdownButtonFormField<String>(
                            key: const ValueKey(_walkInCustomer),
                            initialValue: _walkInCustomer,
                            decoration: const InputDecoration(
                              labelText: 'Select Customer',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: _walkInCustomer,
                                child: Text(_walkInCustomer),
                              ),
                            ],
                            onChanged: null,
                          ),
                          error: (e, _) => Text('Customer error: $e'),
                        ),

                        const SizedBox(height: 12),

                        ToggleButtons(
                          isSelected: [
                            _paymentIsPaidChip,
                            !_paymentIsPaidChip
                          ],
                          onPressed: (index) {
                            if (_isSubmittingQuickSale) return;
                            setState(() {
                              _paymentIsPaidChip = index == 0;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18),
                              child: Text('Paid'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18),
                              child: Text('Unpaid'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isSubmittingQuickSale
                                    ? null
                                    : () async {
                                        setState(() => _paymentIsPaidChip = true);
                                        await _submitQuickSale(paid: true);
                                      },
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Complete Sale (Paid)'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isSubmittingQuickSale
                                    ? null
                                    : () async {
                                        setState(() => _paymentIsPaidChip = false);
                                        await _submitQuickSale(paid: false);
                                      },
                                icon: const Icon(Icons.money_off_csred_outlined),
                                label: const Text('Save as Unpaid'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Recent Sales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),

                if (recent.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No sales yet',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  )
                else
                  Column(
                    children: recent
                        .map(
                          (i) => _SaleCard(
                            item: i,
                            onRecordPayment:
                                !i.sale.isPaid ? () => _recordPaymentDialog(i) : null,
                            onMarkPaid:
                                !i.sale.isPaid ? () => _markPaidQuick(i.sale.id) : null,
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final SaleListItem item;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onMarkPaid;

  const _SaleCard({
    required this.item,
    this.onRecordPayment,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final sale = item.sale;
    final qty = sale.ndenguCount + sale.meatCount;
    final time =
        '${sale.createdAt.hour.toString().padLeft(2, '0')}:${sale.createdAt.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: sale.isPaid ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.customerName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Qty: $qty pcs'),
            const SizedBox(height: 4),
            Text('Total: KES ${sale.totalAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 4),
            Text(
              'Time: $time',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(sale.isPaid ? 'PAID' : 'UNPAID'),
                  backgroundColor: sale.isPaid
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  labelStyle: TextStyle(
                    color: sale.isPaid ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (!sale.isPaid) ...[
                  OutlinedButton(
                    onPressed: onRecordPayment,
                    child: const Text('Record Payment'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onMarkPaid,
                    child: const Text('Mark as Paid'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
