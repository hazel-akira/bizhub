import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../models/api_product.dart';
import '../../providers/api_data_provider.dart';
import '../../providers/business_api_provider.dart';
import '../../providers/customers_provider.dart';
import '../../screens/sale_receipt_screen.dart';
import 'mpesa_checkout_flow.dart';

class GenericQuickSalePanel extends ConsumerStatefulWidget {
  const GenericQuickSalePanel({
    super.key,
    required this.onSaleRecorded,
    this.onManageInventory,
    this.emptyCatalogHint,
  });

  final VoidCallback onSaleRecorded;
  final VoidCallback? onManageInventory;
  final String? emptyCatalogHint;

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

  bool get _canPay => !_isSubmitting && _cart.isNotEmpty;

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
    if (product.sellingPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Set a selling price for ${product.name} in Inventory first.',
          ),
        ),
      );
      return;
    }
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

  Future<int?> _pickCustomerForCredit() async {
    final customers = await ref.read(customersProvider.future);
    if (!mounted) return null;
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a customer first, then save the unpaid sale.'),
        ),
      );
      return null;
    }

    int selectedId = customers.first.id;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Who owes this sale?'),
          content: DropdownButtonFormField<int>(
            initialValue: selectedId,
            decoration: const InputDecoration(labelText: 'Customer'),
            items: customers
                .map(
                  (c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(c.name),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setLocal(() => selectedId = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selectedId),
              child: const Text('Save unpaid'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit({required String method}) async {
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
      int? customerId;
      if (method == 'credit') {
        customerId = await _pickCustomerForCredit();
        if (customerId == null) return;
      }

      if (method == 'mpesa') {
        if (!mounted) return;
        final paid = await MpesaCheckoutFlow.collect(
          context: context,
          ref: ref,
          amount: _cartTotal,
          reference: 'sale_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (paid == null) return;
        if (!mounted) return;

        final sale = await ref.read(createApiSaleWithItemsProvider)(
          items: _cart.values
              .map((line) => (productId: line.product.id, quantity: line.quantity))
              .toList(),
          paymentMethod: 'mpesa',
        );

        widget.onSaleRecorded();
        if (!mounted) return;
        setState(() => _cart.clear());
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SaleReceiptScreen(
              sale: sale,
              mpesaReceiptNumber: paid.mpesaReceiptNumber,
              phone: paid.phone,
            ),
          ),
        );
        return;
      }

      await ref.read(createApiSaleWithItemsProvider)(
        items: _cart.values
            .map((line) => (productId: line.product.id, quantity: line.quantity))
            .toList(),
        paymentMethod: method,
        customerId: customerId,
      );

      widget.onSaleRecorded();
      if (!mounted) return;
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            method == 'credit'
                ? 'Sale saved on credit — settle in Customers → Unpaid'
                : method == 'mpesa'
                    ? 'M-Pesa sale recorded'
                    : 'Cash sale recorded',
          ),
        ),
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
                        Expanded(
                          child: Text(
                            'Product sale',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap Add on a product, then pay with cash or M-Pesa.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
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
                        hint: widget.emptyCatalogHint,
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
                              title: Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                product.sellingPrice <= 0
                                    ? 'Set selling price in Inventory'
                                    : 'KES ${product.sellingPrice.toStringAsFixed(0)}'
                                        '${product.stockQuantity > 0 ? ' • Stock: ${product.stockQuantity}' : ''}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _addProduct(product),
                                child: Text(
                                  inCart > 0 ? 'Add ($inCart)' : 'Add',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
                      _cart.isEmpty
                          ? 'Checkout'
                          : 'Cart ($_cartItemCount items)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    if (_cart.isEmpty)
                      Text(
                        'Add a product above to enable Pay.',
                        style: TextStyle(color: Colors.grey.shade700),
                      )
                    else ...[
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'KES ${line.product.sellingPrice.toStringAsFixed(0)} each',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                iconSize: 20,
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _changeQty(line.product.id, -1),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${line.quantity}'),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                iconSize: 20,
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _changeQty(line.product.id, 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              Flexible(
                                child: FitValue(
                                  text:
                                      'KES ${line.lineTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
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
                    ],
                    const SizedBox(height: 12),
                    AdaptiveButtonRow(
                      children: [
                        FilledButton.icon(
                          onPressed: _canPay
                              ? () => _submit(method: 'cash')
                              : null,
                          icon: const Icon(Icons.payments),
                          label: const Text(
                            'Pay cash',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _canPay
                              ? () => _submit(method: 'mpesa')
                              : null,
                          icon: const Icon(Icons.phone_android),
                          label: const Text(
                            'Pay M-Pesa',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (_canPay) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submit(method: 'credit'),
                        child: const Text('Save as credit / unpaid'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyProductsCard extends StatelessWidget {
  const _EmptyProductsCard({this.onManageInventory, this.hint});

  final VoidCallback? onManageInventory;
  final String? hint;

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
          hint ??
              'Add products in Inventory and set your selling price, then sell them from this screen.',
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
