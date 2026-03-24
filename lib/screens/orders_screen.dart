import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../database/app_database.dart';
import '../providers/customers_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/unpaid_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  int? _selectedCustomerId;
  final _ndenguController = TextEditingController(text: '0');
  final _meatController = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ndenguController.dispose();
    _meatController.dispose();
    super.dispose();
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final customerId = _selectedCustomerId;
    if (customerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a customer')));
      return;
    }
    final ndengu = int.tryParse(_ndenguController.text) ?? 0;
    final meat = int.tryParse(_meatController.text) ?? 0;
    if (ndengu == 0 && meat == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one quantity')),
      );
      return;
    }

    final createOrder = ref.read(createOrderProvider);
    await createOrder(customerId, ndengu, meat);
    ref.invalidate(pendingOrdersProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order created')));
      _ndenguController.text = '0';
      _meatController.text = '0';
      _selectedCustomerId = null;
      setState(() {});
    }
  }

  Future<void> _onBought(Order order, String customerName) async {
    final paid = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bought'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customerName),
            Text(
              '${order.ndenguCount} ndengu, ${order.meatCount} meat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Total: KES ${((order.ndenguCount * SamosaPrices.ndenguPrice) + (order.meatCount * SamosaPrices.meatPrice)).toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('Have they paid?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not paid'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Paid'),
          ),
        ],
      ),
    );

    if (paid != null) {
      final fulfillOrder = ref.read(fulfillOrderProvider);
      await fulfillOrder(order.id, paid);
      ref.invalidate(pendingOrdersProvider);
      ref.invalidate(pendingOrdersWithNamesProvider);
      ref.invalidate(unpaidRecordsProvider);
      ref.invalidate(todaySalesProvider);
      ref.invalidate(allSalesProvider);
      ref.invalidate(todayStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paid ? 'Recorded as paid' : 'Added to unpaid list'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(pendingOrdersWithNamesProvider);
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create order',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      customersAsync.when(
                        data: (customers) {
                          if (customers.isEmpty) {
                            return Text(
                              'Add customers first in the Customers tab',
                              style: TextStyle(color: Colors.grey[600]),
                            );
                          }
                          return DropdownButtonFormField<int>(
                            initialValue: _selectedCustomerId,
                            decoration: InputDecoration(
                              labelText: 'Customer',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: customers
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCustomerId = v),
                            validator: (v) =>
                                v == null ? 'Select customer' : null,
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ndenguController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Ndengu',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _meatController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Meat',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _createOrder,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Create Order'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pending orders (tap Bought when they buy)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ordersAsync.when(
              data: (ordersWithNames) {
                if (ordersWithNames.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No pending orders',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }
                return Column(
                  children: ordersWithNames
                      .map(
                        (record) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              record.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${record.$1.ndenguCount} ndengu, ${record.$1.meatCount} meat • KES ${((record.$1.ndenguCount * SamosaPrices.ndenguPrice) + (record.$1.meatCount * SamosaPrices.meatPrice)).toStringAsFixed(0)}',
                            ),
                            trailing: FilledButton.icon(
                              onPressed: () => _onBought(record.$1, record.$2),
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text('Bought'),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
