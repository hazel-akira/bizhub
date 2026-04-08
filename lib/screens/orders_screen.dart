import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../database/app_database.dart';
import '../providers/customers_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/sales_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  final int? initialCustomerId;

  const OrdersScreen({super.key, this.initialCustomerId});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  int? _selectedCustomerId;
  int _ndenguQty = 0;
  int _meatQty = 0;
  bool _isCreatingOrder = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.initialCustomerId;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _createOrder() async {
    if (_isCreatingOrder) return false;
    final customerId = _selectedCustomerId;
    if (customerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a customer')));
      return false;
    }
    if (_ndenguQty == 0 && _meatQty == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one quantity')),
      );
      return false;
    }

    setState(() => _isCreatingOrder = true);
    try {
      final createOrder = ref.read(createOrderProvider);
      await createOrder(customerId, _ndenguQty, _meatQty);
      ref.invalidate(pendingOrdersProvider);
      ref.invalidate(pendingOrdersWithNamesProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order created')));
        _ndenguQty = 0;
        _meatQty = 0;
        _selectedCustomerId = null;
        setState(() {});
      }
      return true;
    } finally {
      if (mounted) {
        setState(() => _isCreatingOrder = false);
      }
    }
  }

  Future<void> _showCreateOrderSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final customersAsync = ref.watch(customersProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: customersAsync.when(
              data: (customers) => Form(
                key: _formKey,
                child: StatefulBuilder(
                  builder: (context, setModalState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _selectedCustomerId,
                        decoration: const InputDecoration(labelText: 'Customer'),
                        items: customers
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) {
                          setModalState(() => _selectedCustomerId = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      _QtySelector(
                        label: 'Ndengu',
                        value: _ndenguQty,
                        onChanged: (v) {
                          setModalState(() => _ndenguQty = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      _QtySelector(
                        label: 'Meat',
                        value: _meatQty,
                        onChanged: (v) {
                          setModalState(() => _meatQty = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isCreatingOrder
                            ? null
                            : () async {
                                final created = await _createOrder();
                                if (!created) return;
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                              },
                        child: _isCreatingOrder
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Order'),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onBought(Order order, String customerName) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as served'),
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
            const Text('This will convert order to sale.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Served'),
          )
        ],
      ),
    );

    if (proceed == true) {
      final fulfillOrder = ref.read(fulfillOrderProvider);
      await fulfillOrder(order.id);
      ref.invalidate(pendingOrdersProvider);
      ref.invalidate(pendingOrdersWithNamesProvider);
      ref.invalidate(todaySalesProvider);
      ref.invalidate(allSalesProvider);
      ref.invalidate(todayStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order converted to sale')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(pendingOrdersWithNamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOrderSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Pending orders',
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
                              label: const Text('Mark as Served'),
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

class _QtySelector extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _QtySelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            IconButton(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$value', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}
