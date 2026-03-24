import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

final productsProvider =
    StateNotifierProvider<ProductsNotifier, List<Product>>((ref) {
  return ProductsNotifier();
});

class ProductsNotifier extends StateNotifier<List<Product>> {
  ProductsNotifier() : super([]);

  int get _nextId =>
      state.isEmpty ? 1 : state.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;

  void add(Product product) {
    final p = product.id > 0 ? product : product.copyWith(id: _nextId);
    state = [...state, p];
  }

  void update(Product product) {
    state = [
      for (final p in state) p.id == product.id ? product : p,
    ];
  }

  void remove(int id) {
    state = state.where((p) => p.id != id).toList();
  }

  Product? byId(int id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Convenience provider to get a single product by id.
final productByIdProvider = Provider.family<Product?, int>((ref, id) {
  final products = ref.watch(productsProvider);
  for (final p in products) {
    if (p.id == id) return p;
  }
  return null;
});
