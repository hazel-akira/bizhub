import '../core/constants.dart';
import '../models/api_dashboard.dart';
import '../models/api_expense.dart';
import '../models/api_product.dart';
import '../models/api_sale.dart';
import '../models/global_category.dart';
import '../models/global_product.dart';
import 'api_client.dart';

class BusinessApiService {
  BusinessApiService(this._api);

  final ApiClient _api;

  Future<ApiDashboard> getDashboard() async {
    final json = await _api.get('/api/dashboard', auth: true);
    return ApiDashboard.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<ApiProduct>> getProducts() async {
    final json = await _api.get('/api/products', auth: true);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ApiProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ensures Ndengu + Meat products exist; returns name → product map.
  Future<Map<String, ApiProduct>> ensureDefaultProducts() async {
    var products = await getProducts();

    final hasNdengu = products.any(
      (p) => p.name.toLowerCase().contains('ndengu'),
    );
    final hasMeat = products.any(
      (p) => p.name.toLowerCase().contains('meat'),
    );

    if (!hasNdengu) {
      await _createProduct('Ndengu Samosa', SamosaPrices.ndenguPrice);
    }
    if (!hasMeat) {
      await _createProduct('Meat Samosa', SamosaPrices.meatPrice);
    }

    if (!hasNdengu || !hasMeat) {
      products = await getProducts();
    }

    final map = <String, ApiProduct>{};
    for (final p in products) {
      final lower = p.name.toLowerCase();
      if (lower.contains('ndengu')) map['ndengu'] = p;
      if (lower.contains('meat')) map['meat'] = p;
    }
    return map;
  }

  Future<ApiProduct> _createProduct(String name, double price) async {
    final json = await _api.post(
      '/api/products',
      auth: true,
      body: {
        'name': name,
        'selling_price': price,
        'cost_price': price * 0.5,
        'stock_quantity': 0,
        'is_active': true,
      },
    );
    return ApiProduct.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<ApiSale>> getSales() async {
    final json = await _api.get('/api/sales', auth: true);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ApiSale.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiSale> createSale({
    required int ndenguCount,
    required int meatCount,
    required String paymentMethod,
  }) async {
    final products = await ensureDefaultProducts();
    final items = <Map<String, dynamic>>[];

    if (ndenguCount > 0 && products['ndengu'] != null) {
      items.add({
        'product_id': products['ndengu']!.id,
        'quantity': ndenguCount,
      });
    }
    if (meatCount > 0 && products['meat'] != null) {
      items.add({
        'product_id': products['meat']!.id,
        'quantity': meatCount,
      });
    }

    if (items.isEmpty) {
      throw Exception('No products configured for this sale');
    }

    return createSaleWithItems(
      items: items
          .map(
            (item) => (
              productId: item['product_id'] as int,
              quantity: item['quantity'] as int,
            ),
          )
          .toList(),
      paymentMethod: paymentMethod,
    );
  }

  Future<ApiSale> createSaleWithItems({
    required List<({int productId, int quantity})> items,
    required String paymentMethod,
  }) async {
    if (items.isEmpty) {
      throw Exception('Add at least one product to the sale');
    }

    final json = await _api.post(
      '/api/sales',
      auth: true,
      body: {
        'payment_method': paymentMethod,
        'items': items
            .map(
              (item) => {
                'product_id': item.productId,
                'quantity': item.quantity,
              },
            )
            .toList(),
      },
    );

    return ApiSale.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<GlobalProduct>> searchGlobalProducts(String query) async {
    final json = await _api.get(
      '/api/global-products/search?q=${Uri.encodeQueryComponent(query)}',
      auth: true,
    );
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => GlobalProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GlobalCategory>> getGlobalCategories() async {
    final json = await _api.get('/api/global-categories', auth: true);
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final list = data['categories'] as List<dynamic>? ?? [];
    return list
        .map((e) => GlobalCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GlobalProduct>> getGlobalProducts({int? categoryId}) async {
    final path = categoryId != null
        ? '/api/global-products?global_category_id=$categoryId'
        : '/api/global-products';
    final json = await _api.get(path, auth: true);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => GlobalProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiProduct> addProductFromGlobal({
    required int globalProductId,
    required double sellingPrice,
    double? costPrice,
    int stockQuantity = 0,
    int reorderLevel = 5,
  }) async {
    final json = await _api.post(
      '/api/products/from-global',
      auth: true,
      body: {
        'global_product_id': globalProductId,
        'selling_price': sellingPrice,
        'cost_price': costPrice ?? sellingPrice * 0.6,
        'stock_quantity': stockQuantity,
        'reorder_level': reorderLevel,
      },
    );
    return ApiProduct.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ApiProduct> createCustomProduct({
    required String name,
    required double sellingPrice,
    int stockQuantity = 0,
    double? costPrice,
  }) async {
    final json = await _api.post(
      '/api/products/custom',
      auth: true,
      body: {
        'name': name,
        'selling_price': sellingPrice,
        'cost_price': costPrice ?? sellingPrice * 0.6,
        'stock_quantity': stockQuantity,
        'is_active': true,
      },
    );
    return ApiProduct.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ApiProduct> createProduct({
    required String name,
    required double sellingPrice,
    int stockQuantity = 0,
    double? costPrice,
  }) async {
    return createCustomProduct(
      name: name,
      sellingPrice: sellingPrice,
      stockQuantity: stockQuantity,
      costPrice: costPrice,
    );
  }

  Future<ApiProduct> updateProduct({
    required int productId,
    String? name,
    double? sellingPrice,
    int? stockQuantity,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (sellingPrice != null) body['selling_price'] = sellingPrice;
    if (stockQuantity != null) body['stock_quantity'] = stockQuantity;
    if (isActive != null) body['is_active'] = isActive;

    final json = await _api.put(
      '/api/products/$productId',
      auth: true,
      body: body,
    );
    return ApiProduct.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ApiProduct> uploadProductImage({
    required int productId,
    required String filePath,
  }) async {
    final json = await _api.postMultipart(
      '/api/products/$productId/image',
      fieldName: 'image',
      filePath: filePath,
      auth: true,
    );
    final data = json['data'] as Map<String, dynamic>;
    return ApiProduct.fromJson(data['product'] as Map<String, dynamic>);
  }

  Future<List<ApiExpense>> getExpenses() async {
    final json = await _api.get('/api/expenses', auth: true);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ApiExpense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiExpense> createExpense({
    required String title,
    required double amount,
  }) async {
    final json = await _api.post(
      '/api/expenses',
      auth: true,
      body: {
        'title': title,
        'amount': amount,
        'expense_date': DateTime.now().toIso8601String(),
      },
    );
    return ApiExpense.fromJson(json['data'] as Map<String, dynamic>);
  }
}
