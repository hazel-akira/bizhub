import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/whatsapp_helper.dart';
import '../main.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';
import '../services/business_profile_service.dart';
import '../services/user_role_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  static const _cartStorageKey = 'customer_cart_items';
  String _businessName = 'Akira Bites';
  String _businessWhatsApp = '';
  final Map<int, int> _cart = {};
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
    _loadPersistedCart();
  }

  Future<void> _loadBusinessProfile() async {
    final profile = await BusinessProfileService.instance.getProfile();
    if (!mounted) return;
    setState(() {
      _businessName = profile.name.trim().isEmpty
          ? 'Akira Bites'
          : profile.name;
      _businessWhatsApp = profile.whatsappPhone.trim();
    });
  }

  Future<void> _switchRole() async {
    await UserRoleService.instance.saveRole(UserRole.businessOwner);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
      (route) => false,
    );
  }

  Future<void> _loadPersistedCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartStorageKey);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final restored = <int, int>{};
      decoded.forEach((key, value) {
        final id = int.tryParse(key);
        if (id == null) return;
        if (value is int && value > 0) {
          restored[id] = value;
        }
      });
      if (!mounted) return;
      setState(() {
        _cart
          ..clear()
          ..addAll(restored);
      });
    } catch (_) {
      // Ignore malformed persisted data.
    }
  }

  Future<void> _persistCart() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, int>{};
    for (final entry in _cart.entries) {
      map['${entry.key}'] = entry.value;
    }
    await prefs.setString(_cartStorageKey, jsonEncode(map));
  }

  List<Product> _catalog(List<Product> existing) {
    if (existing.isNotEmpty) return existing;
    return const [
      Product(
        id: 1,
        name: 'Ndengu Samosa',
        price: SamosaPrices.ndenguPrice,
        category: 'Legume',
        unit: 'Legume',
      ),
      Product(
        id: 2,
        name: 'Meat Samosa',
        price: SamosaPrices.meatPrice,
        category: 'Meat',
        unit: 'Meat',
      ),
    ];
  }

  void _addToCart(Product product) {
    setState(() {
      _cart[product.id] = (_cart[product.id] ?? 0) + 1;
    });
    _persistCart();
  }

  void _updateQty(Product product, int qty) {
    setState(() {
      if (qty <= 0) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = qty;
      }
    });
    _persistCart();
  }

  String _categoryFor(Product product) {
    final explicit = (product.category ?? product.unit)?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final lower = product.name.toLowerCase();
    if (lower.contains('meat') ||
        lower.contains('beef') ||
        lower.contains('chicken')) {
      return 'Meat';
    }
    if (lower.contains('ndengu') || lower.contains('veg')) {
      return 'Legume';
    }
    return 'General';
  }

  Widget _productImage(Product product) {
    final path = (product.imagePath ?? '').trim();
    if (path.isEmpty) {
      return _fallbackImageIcon(product);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          path,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackImageIcon(product),
        ),
      );
    }
    if (!kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackImageIcon(product),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        path,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackImageIcon(product),
      ),
    );
  }

  Widget _fallbackImageIcon(Product product) {
    return CircleAvatar(
      backgroundColor: Colors.orange.withValues(alpha: 0.2),
      child: Icon(
        _categoryFor(product) == 'Meat' ? Icons.restaurant : Icons.eco_outlined,
        color: Colors.brown,
      ),
    );
  }

  List<Product> _filteredProducts(List<Product> products) {
    final search = _searchQuery.trim().toLowerCase();
    return products.where((product) {
      final category = _categoryFor(product);
      final categoryOk =
          _selectedCategory == 'All' || category == _selectedCategory;
      if (!categoryOk) return false;
      if (search.isEmpty) return true;
      return product.name.toLowerCase().contains(search) ||
          category.toLowerCase().contains(search);
    }).toList();
  }

  List<String> _availableCategories(List<Product> products) {
    final set = {'All', ...products.map(_categoryFor)};
    return set.toList();
  }

  double _total(List<Product> products) {
    final byId = {for (final p in products) p.id: p};
    return _cart.entries.fold<double>(0, (sum, entry) {
      final product = byId[entry.key];
      if (product == null) return sum;
      return sum + (product.price * entry.value);
    });
  }

  String _buildOrderMessage(List<Product> products) {
    final byId = {for (final p in products) p.id: p};
    final lines = <String>[
      'Hello $_businessName,',
      'I would like to place an order:',
      '',
    ];
    for (final entry in _cart.entries) {
      final product = byId[entry.key];
      if (product == null) continue;
      final subtotal = product.price * entry.value;
      lines.add(
        '• ${entry.value} x ${product.name} = ${subtotal.toStringAsFixed(0)} KES',
      );
    }
    lines.add('');
    lines.add('Total: ${_total(products).toStringAsFixed(0)} KES');
    lines.add('Thank you.');
    return lines.join('\n');
  }

  Future<void> _checkoutViaWhatsApp(List<Product> products) async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }
    if (_businessWhatsApp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business WhatsApp number is not set in Settings'),
        ),
      );
      return;
    }
    final ok = await openWhatsAppChat(
      _businessWhatsApp,
      message: _buildOrderMessage(products),
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
      return;
    }
    setState(_cart.clear);
    _persistCart();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening WhatsApp with your order')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_businessName),
        actions: [
          IconButton(
            tooltip: 'Switch role',
            onPressed: _switchRole,
            icon: const Icon(Icons.switch_account),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final catalog = _catalog(ref.watch(productsProvider));
          final visibleProducts = _filteredProducts(catalog);
          final categories = _availableCategories(catalog);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Product Catalog',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search products or category',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: categories
                    .map(
                      (category) => ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = category),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              if (visibleProducts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No products match your search/filter'),
                  ),
                ),
              ...visibleProducts.map(
                (product) => Card(
                  child: ListTile(
                    leading: _productImage(product),
                    title: Text(product.name),
                    subtitle: Text(
                      '${_categoryFor(product)} • KES ${product.price.toStringAsFixed(0)}',
                    ),
                    trailing: FilledButton.icon(
                      onPressed: () => _addToCart(product),
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Add'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cart',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (_cart.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No items in cart'),
                  ),
                )
              else
                ..._cart.entries.map((entry) {
                  final candidates = catalog
                      .where((p) => p.id == entry.key)
                      .toList();
                  if (candidates.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final product = candidates.first;
                  final subtotal = product.price * entry.value;
                  return Card(
                    child: ListTile(
                      leading: _productImage(product),
                      title: Text(product.name),
                      subtitle: Text(
                        '${entry.value} x ${product.price.toStringAsFixed(0)} = ${subtotal.toStringAsFixed(0)} KES',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                _updateQty(product, entry.value - 1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${entry.value}'),
                          IconButton(
                            onPressed: () =>
                                _updateQty(product, entry.value + 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 10),
              Text(
                'Total: ${_total(catalog).toStringAsFixed(0)} KES',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _checkoutViaWhatsApp(catalog),
                icon: const Icon(Icons.chat),
                label: const Text('Order via WhatsApp'),
              ),
            ],
          );
        },
      ),
    );
  }
}
