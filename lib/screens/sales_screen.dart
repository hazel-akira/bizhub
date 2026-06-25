import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/api_sale.dart';
import '../providers/api_data_provider.dart';
import '../providers/business_api_provider.dart';
import '../providers/business_profile_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/unpaid_customers_provider.dart';
import '../widgets/sales/food_quick_sale_panel.dart';
import '../widgets/sales/generic_quick_sale_panel.dart';
import 'inventory_screen.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  void _refreshSalesUI() {
    ref.invalidate(todaySalesListItemsProvider);
    ref.invalidate(allSalesProvider);
    ref.invalidate(allPaymentsProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(todaySalesProvider);
    ref.invalidate(unpaidCustomersDebtProvider);
    ref.invalidate(apiSalesProvider);
    ref.invalidate(apiTodaySalesProvider);
    ref.invalidate(apiDashboardProvider);
    ref.invalidate(apiProductsProvider);
  }

  void _openInventory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InventoryScreen()),
    );
  }

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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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

  Future<void> _markPaidQuick(int saleId) async {
    await ref.read(markSalePaidProvider)(saleId);
    _refreshSalesUI();
  }

  Widget _apiSaleTile(ApiSale sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('KES ${sale.totalAmount.toStringAsFixed(0)}'),
        subtitle: Text(sale.itemsSummary),
        trailing: Text(
          sale.paymentMethod.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useCloud = ref.watch(useCloudDataProvider);
    final isFood = ref.watch(isFoodBusinessProvider);
    final typeLabel = ref.watch(businessTypeLabelProvider);
    final todaySalesItemsAsync = useCloud
        ? ref.watch(apiTodaySalesProvider)
        : ref.watch(todaySalesListItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (!isFood && useCloud)
            IconButton(
              onPressed: _openInventory,
              icon: const Icon(Icons.inventory_2_outlined),
              tooltip: 'Inventory',
            ),
          if (useCloud)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.cloud_done, color: Colors.green),
            ),
        ],
      ),
      body: todaySalesItemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          final recentApi = useCloud
              ? (items as List<ApiSale>).take(10).toList()
              : <ApiSale>[];
          final recentLocal = useCloud
              ? <SaleListItem>[]
              : (items as List<SaleListItem>).take(10).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (typeLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Chip(
                      avatar: Icon(
                        isFood ? Icons.restaurant : Icons.storefront,
                        size: 18,
                      ),
                      label: Text(typeLabel),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (isFood)
                  FoodQuickSalePanel(onSaleRecorded: _refreshSalesUI)
                else
                  GenericQuickSalePanel(
                    onSaleRecorded: _refreshSalesUI,
                    onManageInventory: _openInventory,
                  ),
                const SizedBox(height: 16),
                Text(
                  'Recent sales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                if (useCloud) ...[
                  if (recentApi.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No sales yet today',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    )
                  else
                    Column(children: recentApi.map(_apiSaleTile).toList()),
                ] else ...[
                  if (recentLocal.isEmpty)
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
                      children: recentLocal
                          .map(
                            (i) => _SaleCard(
                              item: i,
                              onRecordPayment: !i.sale.isPaid
                                  ? () => _recordPaymentDialog(i)
                                  : null,
                              onMarkPaid: !i.sale.isPaid
                                  ? () => _markPaidQuick(i.sale.id)
                                  : null,
                            ),
                          )
                          .toList(),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({
    required this.item,
    this.onRecordPayment,
    this.onMarkPaid,
  });

  final SaleListItem item;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onMarkPaid;

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
                    color:
                        sale.isPaid ? Colors.green.shade800 : Colors.red.shade800,
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
