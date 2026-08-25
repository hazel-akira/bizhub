import 'package:flutter/material.dart';

import '../models/api_sale.dart';

class SaleReceiptScreen extends StatelessWidget {
  const SaleReceiptScreen({
    super.key,
    required this.sale,
    this.mpesaReceiptNumber,
    this.phone,
  });

  final ApiSale sale;
  final String? mpesaReceiptNumber;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale receipt'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Payment received',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KES ${sale.totalAmount.toStringAsFixed(0)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (sale.invoiceNumber != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      sale.invoiceNumber!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                  const Divider(height: 32),
                  ...sale.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${item.quantity}× ${item.productName}'),
                          ),
                          Text(
                            'KES ${item.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (mpesaReceiptNumber != null &&
                      mpesaReceiptNumber!.isNotEmpty) ...[
                    const Divider(height: 32),
                    _MetaRow(label: 'M-Pesa receipt', value: mpesaReceiptNumber!),
                  ],
                  if (phone != null && phone!.isNotEmpty)
                    _MetaRow(label: 'Phone', value: phone!),
                  _MetaRow(
                    label: 'Method',
                    value: sale.paymentMethod.toUpperCase(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
