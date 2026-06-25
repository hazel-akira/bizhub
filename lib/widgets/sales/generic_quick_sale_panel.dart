import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/api_product.dart';
import '../../providers/api_data_provider.dart';
import '../../providers/business_api_provider.dart';

class GenericQuickSalePanel extends ConsumerStatefulWidget {
  const GenericQuickSalePanel({
    super.key,
    required this.onSaleRecorded,
    this.onManageInventory,
  });

  final VoidCallback onSaleRecorded;
  final VoidCallback? onManageInventory;

  @override
  ConsumerState<GenericQuickSalePanel> createState() =>
      _GenericQuickSalePanelState();
}

class _CartLine {
  _CartLine(this.product, this.quantity);

  final ApiProduct product;
  int quantity;

  double get lineTotal => product.sellingPrice * quantity;
}

class _GenericQuickSalePanelState extends ConsumerState<GenericQuickSalePanel> {
  final _searchController = TextEditingController();
  final Map<int, _CartLine> _cart = {};
  bool _isSubmitting = false;
  String _paymentMethod = 'cash';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _cartTotal =>
      _cart.values.fold<double>(0, (sum, line) => sum + line.lineTotal);

  int get _cartItemCount =>
      _cart.values.fold<int>(0, (sum, line) => sum + line.quantity);

  void _addProduct(ApiProduct product) {
    setState(() {
      final existing = _cart[product.id];
      if (existing != null) {
        existing.quantity++;
      } else {
        _cart[product.id] = _CartLine(product, 1);
      }
    });
  }

  void _changeQty(int productId, int delta) {
    final line = _cart[productId];
    if (line == null) return;
    setState(() {
      line.quantity += delta;
      if (line.quantity <= 0) {
        _cart.remove(productId);
      }
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || _cart.isEmpty) return;

    final useCloud = ref.read(useCloudDataProvider);
    if (!useCloud) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to record product sales in the cloud'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(createApiSaleWithItemsProvider)(
        items: _cart.values
            .map((line) => (productId: line.product.id, quantity: line.quantity))
            .toList(),
        paymentMethod: _paymentMethod,
      );

      widget.onSaleRecorded();
      if (!mounted) return;
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale completed')),
      );
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
    final productsAsync = ref.watch(apiProductsProvider);
    final query = _searchController.text.trim().toLowerCase();

    return productsAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Could not load products: $e'),
        ),
      ),
      data: (products) {
        final activeProducts =
            products.where((p) => p.isActive).toList(growable: false);
        final filtered = query.isEmpty
            ? activeProducts
            : activeProducts
                .where((p) => p.name.toLowerCase().contains(query))
                .toList();

        return Column(
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
                    Row(
                      children: [
                        Icon(Icons.point_of_sale, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Product sale',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search products',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    if (activeProducts.isEmpty)
                      _EmptyProductsCard(
                        onManageInventory: widget.onManageInventory,
                      )
                    else if (filtered.isEmpty)
                      const Text('No products match your search')
                    else
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            final inCart = _cart[product.id]?.quantity ?? 0;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(product.name),
                              subtitle: Text(
                                'KES ${product.sellingPrice.toStringAsFixed(0)}'
                                '${product.stockQuantity > 0 ? ' • Stock: ${product.stockQuantity}' : ''}',
                              ),
                              trailing: inCart > 0
                                  ? Chip(
                                      label: Text('$inCart in cart'),
                                      backgroundColor: Colors.blue.shade50,
                                    )
                                  : null,
                              onTap: _isSubmitting
                                  ? null
                                  : () => _addProduct(product),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_cart.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                        'Cart ($_cartItemCount items)',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      ..._cart.values.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'KES ${line.product.sellingPrice.toStringAsFixed(0)} each',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _changeQty(line.product.id, -1),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${line.quantity}'),
                              IconButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _changeQty(line.product.id, 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              Text(
                                'KES ${line.lineTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      Text(
                        'Total: KES ${_cartTotal.toStringAsFixed(0)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_paymentMethod),
                        initialValue: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment method',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
                          DropdownMenuItem(
                            value: 'credit',
                            child: Text('Credit'),
                          ),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (v) {
                                if (v == null) return;
                                setState(() => _paymentMethod = v);
                              },
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(
                          _isSubmitting
                              ? 'Processing…'
                              : 'Complete sale (KES ${_cartTotal.toStringAsFixed(0)})',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EmptyProductsCard extends StatelessWidget {
  const _EmptyProductsCard({this.onManageInventory});

  final VoidCallback? onManageInventory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade500),
        const SizedBox(height: 8),
        const Text('No products in inventory yet.'),
        const SizedBox(height: 4),
        Text(
          'Add products first, then sell them from this screen.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        if (onManageInventory != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onManageInventory,
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Manage inventory'),
          ),
        ],
      ],
    );
  }
}
