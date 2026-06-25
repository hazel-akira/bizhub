import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_expense.dart';
import '../models/api_product.dart';
import '../models/api_sale.dart';
import '../models/global_category.dart';
import '../models/global_product.dart';
import 'business_api_provider.dart';

final apiProductsProvider = FutureProvider<List<ApiProduct>>((ref) async {
  final api = ref.watch(businessApiProvider);
  if (api == null) return [];
  return api.getProducts();
});

final apiDashboardProvider = FutureProvider((ref) async {
  final api = ref.watch(businessApiProvider);
  if (api == null) return null;
  return api.getDashboard();
});

final apiSalesProvider = FutureProvider<List<ApiSale>>((ref) async {
  final api = ref.watch(businessApiProvider);
  if (api == null) return [];
  return api.getSales();
});

final apiTodaySalesProvider = FutureProvider<List<ApiSale>>((ref) async {
  final sales = await ref.watch(apiSalesProvider.future);
  final today = DateTime.now();
  return sales.where((s) {
    return s.saleDate.year == today.year &&
        s.saleDate.month == today.month &&
        s.saleDate.day == today.day;
  }).toList();
});

final apiExpensesProvider = FutureProvider<List<ApiExpense>>((ref) async {
  final api = ref.watch(businessApiProvider);
  if (api == null) return [];
  return api.getExpenses();
});

final apiTodayExpensesProvider = FutureProvider<List<ApiExpense>>((ref) async {
  final expenses = await ref.watch(apiExpensesProvider.future);
  final today = DateTime.now();
  return expenses.where((e) {
    return e.expenseDate.year == today.year &&
        e.expenseDate.month == today.month &&
        e.expenseDate.day == today.day;
  }).toList();
});

final createApiSaleProvider = Provider<
    Future<void> Function({
  required int ndenguCount,
  required int meatCount,
  required bool paid,
})>((ref) {
  return ({
    required int ndenguCount,
    required int meatCount,
    required bool paid,
  }) async {
    final api = ref.read(businessApiProvider);
    if (api == null) throw Exception('Not signed in');

    await api.createSale(
      ndenguCount: ndenguCount,
      meatCount: meatCount,
      paymentMethod: paid ? 'cash' : 'credit',
    );

    ref.invalidate(apiSalesProvider);
    ref.invalidate(apiDashboardProvider);
    ref.invalidate(apiTodaySalesProvider);
  };
});

final createApiExpenseProvider =
    Provider<Future<void> Function(String title, double amount)>((ref) {
  return (title, amount) async {
    final api = ref.read(businessApiProvider);
    if (api == null) throw Exception('Not signed in');

    await api.createExpense(title: title, amount: amount);

    ref.invalidate(apiExpensesProvider);
    ref.invalidate(apiTodayExpensesProvider);
    ref.invalidate(apiDashboardProvider);
  };
});

final createApiSaleWithItemsProvider = Provider<
    Future<void> Function({
  required List<({int productId, int quantity})> items,
  required String paymentMethod,
})>((ref) {
  return ({
    required List<({int productId, int quantity})> items,
    required String paymentMethod,
  }) async {
    final api = ref.read(businessApiProvider);
    if (api == null) throw Exception('Not signed in');

    await api.createSaleWithItems(
      items: items,
      paymentMethod: paymentMethod,
    );

    ref.invalidate(apiSalesProvider);
    ref.invalidate(apiDashboardProvider);
    ref.invalidate(apiTodaySalesProvider);
    ref.invalidate(apiProductsProvider);
  };
});

final createApiProductProvider = Provider<
    Future<ApiProduct> Function({
  required String name,
  required double sellingPrice,
  int stockQuantity,
})>((ref) {
  return ({
    required String name,
    required double sellingPrice,
    int stockQuantity = 0,
  }) async {
    final api = ref.read(businessApiProvider);
    if (api == null) throw Exception('Not signed in');

    final product = await api.createCustomProduct(
      name: name,
      sellingPrice: sellingPrice,
      stockQuantity: stockQuantity,
    );

    ref.invalidate(apiProductsProvider);
    ref.invalidate(apiDashboardProvider);
    return product;
  };
});

final addProductFromGlobalProvider = Provider<
    Future<ApiProduct> Function({
  required int globalProductId,
  required double sellingPrice,
  int stockQuantity,
  double? costPrice,
})>((ref) {
  return ({
    required int globalProductId,
    required double sellingPrice,
    int stockQuantity = 0,
    double? costPrice,
  }) async {
    final api = ref.read(businessApiProvider);
    if (api == null) throw Exception('Not signed in');

    final product = await api.addProductFromGlobal(
      globalProductId: globalProductId,
      sellingPrice: sellingPrice,
      stockQuantity: stockQuantity,
      costPrice: costPrice,
    );

    ref.invalidate(apiProductsProvider);
    ref.invalidate(apiDashboardProvider);
    return product;
  };
});

final searchGlobalProductsProvider = Provider<
    Future<List<GlobalProduct>> Function(String query)>((ref) {
  return (query) async {
    final api = ref.read(businessApiProvider);
    if (api == null) throw Exception('Not signed in');
    if (query.trim().length < 2) return [];
    return api.searchGlobalProducts(query.trim());
  };
});

final globalCategoriesProvider =
    FutureProvider<List<GlobalCategory>>((ref) async {
  final api = ref.watch(businessApiProvider);
  if (api == null) return [];
  return api.getGlobalCategories();
});

final globalProductsCatalogProvider =
    FutureProvider<List<GlobalProduct>>((ref) async {
  final api = ref.watch(businessApiProvider);
  if (api == null) return [];
  return api.getGlobalProducts();
});

final globalProductsByCategoryProvider =
    FutureProvider.family<List<GlobalProduct>, int?>((ref, categoryId) async {
  final api = ref.watch(businessApiProvider);
  if (api == null) return [];
  return api.getGlobalProducts(categoryId: categoryId);
});

final uploadProductImageProvider = Provider<
    Future<ApiProduct> Function({
  required int productId,
  required List<int> bytes,
  required String fileName,
})>((ref) {
  return ({
    required int productId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final api = ref.read(businessApiProvider);
    if (api == null) throw Exception('Not signed in');

    final product = await api.uploadProductImage(
      productId: productId,
      bytes: bytes,
      fileName: fileName,
    );

    ref.invalidate(apiProductsProvider);
    return product;
  };
});

final updateApiProductProvider = Provider<
    Future<ApiProduct> Function({
  required int productId,
  String? name,
  double? sellingPrice,
  int? stockQuantity,
  bool? isActive,
})>((ref) {
  return ({
    required int productId,
    String? name,
    double? sellingPrice,
    int? stockQuantity,
    bool? isActive,
  }) async {
    final api = ref.read(businessApiProvider);
    if (api == null) throw Exception('Not signed in');

    final product = await api.updateProduct(
      productId: productId,
      name: name,
      sellingPrice: sellingPrice,
      stockQuantity: stockQuantity,
      isActive: isActive,
    );

    ref.invalidate(apiProductsProvider);
    ref.invalidate(apiDashboardProvider);
    return product;
  };
});
