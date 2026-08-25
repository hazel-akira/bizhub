import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers/api_data_provider.dart';
import '../../providers/business_api_provider.dart';
import '../../providers/customers_provider.dart';
import '../../providers/sales_provider.dart';
import '../../screens/sale_receipt_screen.dart';
import '../../services/sales_reminder_service.dart';
import 'mpesa_checkout_flow.dart';

class FoodQuickSalePanel extends ConsumerStatefulWidget {
  const FoodQuickSalePanel({
    super.key,
    required this.onSaleRecorded,
  });

  final VoidCallback onSaleRecorded;

  @override
  ConsumerState<FoodQuickSalePanel> createState() =>
      _FoodQuickSalePanelState();
}

class _FoodQuickSalePanelState extends ConsumerState<FoodQuickSalePanel> {
  static const _walkInCustomer = 'Walk-in Customer';

  String _selectedProduct = 'meat';
  int _quantity = 1;
  String _selectedCustomerName = _walkInCustomer;
  bool _paymentIsPaidChip = true;
  String _paidMethod = 'cash';
  bool _isSubmitting = false;

  double get _unitPrice => _selectedProduct == 'meat'
      ? SamosaPrices.meatPrice
      : SamosaPrices.ndenguPrice;

  int get _ndenguCount => _selectedProduct == 'ndengu' ? _quantity : 0;
  int get _meatCount => _selectedProduct == 'meat' ? _quantity : 0;
  double get _totalAmount => _quantity * _unitPrice;

  Future<void> _submit({required bool paid}) async {
    if (_isSubmitting || _quantity <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      final customerName = _selectedCustomerName.trim().isEmpty
          ? _walkInCustomer
          : _selectedCustomerName.trim();
      final useCloud = ref.read(useCloudDataProvider);

      if (paid && _paidMethod == 'mpesa' && !useCloud) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to collect M-Pesa payments.'),
          ),
        );
        return;
      }

      if (useCloud) {
        if (paid && _paidMethod == 'mpesa') {
          final mpesa = await MpesaCheckoutFlow.collect(
            context: context,
            ref: ref,
            amount: _totalAmount,
            reference: 'food_${DateTime.now().millisecondsSinceEpoch}',
          );
          if (mpesa == null) return;
          if (!mounted) return;

          final sale = await ref.read(createApiSaleProvider)(
            ndenguCount: _ndenguCount,
            meatCount: _meatCount,
            paid: true,
            paymentMethod: 'mpesa',
          );

          try {
            await SalesReminderService.instance
                .syncDailyReminder(hasSalesToday: true);
          } catch (_) {}

          widget.onSaleRecorded();
          if (!mounted) return;
          setState(() => _quantity = 1);
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SaleReceiptScreen(
                sale: sale,
                mpesaReceiptNumber: mpesa.mpesaReceiptNumber,
                phone: mpesa.phone,
              ),
            ),
          );
          return;
        }

        await ref.read(createApiSaleProvider)(
          ndenguCount: _ndenguCount,
          meatCount: _meatCount,
          paid: paid,
          paymentMethod: _paidMethod,
        );
      } else {
        await ref.read(createQuickSaleProvider)(
          customerName: customerName,
          ndenguCount: _ndenguCount,
          meatCount: _meatCount,
          totalAmount: _totalAmount,
          paid: paid,
        );
      }

      try {
        await SalesReminderService.instance
            .syncDailyReminder(hasSalesToday: true);
      } catch (_) {}

      widget.onSaleRecorded();
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Samosa counter',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedProduct),
              initialValue: _selectedProduct,
              decoration: const InputDecoration(
                labelText: 'Select product',
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
              onChanged: _isSubmitting
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
                side: BorderSide(color: Theme.of(context).dividerColor),
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
                      onPressed: _isSubmitting || _quantity <= 1
                          ? null
                          : () => setState(() => _quantity--),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_quantity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed:
                          _isSubmitting ? null : () => setState(() => _quantity++),
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
                    labelText: 'Customer',
                    border: OutlineInputBorder(),
                  ),
                  items: menuItems,
                  onChanged: _isSubmitting
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _selectedCustomerName = v);
                        },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Customer error: $e'),
            ),
            const SizedBox(height: 12),
            ToggleButtons(
              isSelected: [_paymentIsPaidChip, !_paymentIsPaidChip],
              onPressed: (index) {
                if (_isSubmitting) return;
                setState(() => _paymentIsPaidChip = index == 0);
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
            if (_paymentIsPaidChip) ...[
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cash', label: Text('Cash')),
                  ButtonSegment(value: 'mpesa', label: Text('M-Pesa')),
                ],
                selected: {_paidMethod},
                onSelectionChanged: (value) {
                  if (_isSubmitting) return;
                  setState(() => _paidMethod = value.first);
                },
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() => _paymentIsPaidChip = true);
                            await _submit(paid: true);
                          },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete sale'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() => _paymentIsPaidChip = false);
                            await _submit(paid: false);
                          },
                    icon: const Icon(Icons.money_off_csred_outlined),
                    label: const Text('Save unpaid'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
