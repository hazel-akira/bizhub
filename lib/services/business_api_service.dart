import '../database/app_database.dart';
import '../models/api_dashboard.dart';
import '../models/api_expense.dart';
import '../models/api_product.dart';
import '../models/api_sale.dart';
import '../models/auth_user.dart';
import '../models/global_category.dart';
import '../models/global_product.dart';
import '../models/pending_order_view.dart';
import '../core/staff_access.dart';
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

  /// Finds Ndengu / Meat Samosa products if the shop added them in Inventory.
  Future<Map<String, ApiProduct>> ensureDefaultProducts() async {
    final products = await getProducts();
    final map = <String, ApiProduct>{};
    for (final p in products) {
      final lower = p.name.toLowerCase();
      if (lower.contains('ndengu')) map['ndengu'] = p;
      if (lower.contains('meat samosa') || lower == 'meat samosa') {
        map['meat'] = p;
      } else if (!map.containsKey('meat') &&
          lower.contains('meat') &&
          lower.contains('samosa')) {
        map['meat'] = p;
      }
    }
    return map;
  }

  Future<List<ApiSale>> getSales() async {
    final json = await _api.get('/api/sales', auth: true);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ApiSale.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ApiSale>> getUnpaidSales() async {
    final json = await _api.get('/api/sales/unpaid', auth: true);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ApiSale.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Customer>> getCustomers() async {
    final json = await _api.get('/api/customers', auth: true);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => _customerFromApi(e as Map<String, dynamic>))
        .toList();
  }

  Future<Customer> createCustomer({
    required String name,
    String phone = '',
  }) async {
    final json = await _api.post(
      '/api/customers',
      auth: true,
      body: {'name': name, if (phone.isNotEmpty) 'phone': phone},
    );
    return _customerFromApi(json['data'] as Map<String, dynamic>);
  }

  Future<Customer> updateCustomer({
    required int id,
    required String name,
    String phone = '',
  }) async {
    final json = await _api.put(
      '/api/customers/$id',
      auth: true,
      body: {'name': name, 'phone': phone},
    );
    return _customerFromApi(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteCustomer(int id) async {
    await _api.delete('/api/customers/$id', auth: true);
  }

  Future<List<PendingOrderView>> getShopOrders() async {
    final json = await _api.get('/api/shop-orders', auth: true);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => PendingOrderView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PendingOrderView> createShopOrder({
    required int customerId,
    required int ndenguCount,
    required int meatCount,
  }) async {
    final json = await _api.post(
      '/api/shop-orders',
      auth: true,
      body: {
        'customer_id': customerId,
        'ndengu_count': ndenguCount,
        'meat_count': meatCount,
      },
    );
    return PendingOrderView.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> fulfillShopOrder(int orderId) async {
    await _api.post('/api/shop-orders/$orderId/fulfill', auth: true);
  }

  Customer _customerFromApi(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Future<ApiSale> recordSalePayment({
    required int saleId,
    required double amount,
    required String paymentMethod,
  }) async {
    final json = await _api.post(
      '/api/sales/$saleId/payments',
      auth: true,
      body: {'amount': amount, 'payment_method': paymentMethod},
    );
    return ApiSale.fromJson(json['data'] as Map<String, dynamic>);
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
      items.add({'product_id': products['meat']!.id, 'quantity': meatCount});
    }

    if (items.isEmpty) {
      throw Exception(
        'Add Ndengu Samosa and Meat Samosa in Inventory and set their prices first.',
      );
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
    int? customerId,
    double? unitPrice,
  }) async {
    if (items.isEmpty) {
      throw Exception('Add at least one product to the sale');
    }

    final json = await _api.post(
      '/api/sales',
      auth: true,
      body: {
        'payment_method': paymentMethod,
        'customer_id': ?customerId,
        'items': items
            .map(
              (item) => {
                'product_id': item.productId,
                'quantity': item.quantity,
                'unit_price': ?unitPrice,
              },
            )
            .toList(),
      },
    );

    final data = json['data'] as Map<String, dynamic>;
    var sale = ApiSale.fromJson(data);

    if (sale.isCollectedAtSale) {
      double asDouble(dynamic v) {
        if (v is num) return v.toDouble();
        return double.tryParse('$v') ?? 0;
      }

      final rawPaid = data['is_paid'] == true || data['is_paid'] == 1;
      final rawAmountPaid = asDouble(data['amount_paid']);
      final rawOutstanding = data.containsKey('outstanding')
          ? asDouble(data['outstanding'])
          : sale.totalAmount - rawAmountPaid;
      final due = rawOutstanding > 0.001
          ? rawOutstanding
          : (rawPaid || rawAmountPaid > 0 ? 0.0 : sale.totalAmount);

      if (due > 0.001) {
        try {
          sale = await recordSalePayment(
            saleId: sale.id,
            amount: due,
            paymentMethod: paymentMethod,
          );
        } catch (_) {
          sale = sale.copyWith(
            amountPaid: sale.totalAmount,
            outstanding: 0,
            isPaid: true,
            paymentMethod: paymentMethod,
          );
        }
      }
    }

    return sale;
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
    required double costPrice,
    int stockQuantity = 0,
    int reorderLevel = 5,
  }) async {
    final json = await _api.post(
      '/api/products/from-global',
      auth: true,
      body: {
        'global_product_id': globalProductId,
        'selling_price': sellingPrice,
        'cost_price': costPrice,
        'stock_quantity': stockQuantity,
        'reorder_level': reorderLevel,
      },
    );
    return ApiProduct.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ApiProduct> createCustomProduct({
    required String name,
    required double sellingPrice,
    required double costPrice,
    int stockQuantity = 0,
  }) async {
    final json = await _api.post(
      '/api/products/custom',
      auth: true,
      body: {
        'name': name,
        'selling_price': sellingPrice,
        'cost_price': costPrice,
        'stock_quantity': stockQuantity,
        'is_active': true,
      },
    );
    return ApiProduct.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ApiProduct> createProduct({
    required String name,
    required double sellingPrice,
    required double costPrice,
    int stockQuantity = 0,
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
    double? costPrice,
    int? stockQuantity,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (sellingPrice != null) body['selling_price'] = sellingPrice;
    if (costPrice != null) body['cost_price'] = costPrice;
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
    required List<int> bytes,
    required String fileName,
  }) async {
    final json = await _api.postMultipart(
      '/api/products/$productId/image',
      fieldName: 'image',
      bytes: bytes,
      fileName: fileName,
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

  Future<List<StaffRoleInfo>> getStaffRoles() async {
    final json = await _api.get('/api/staff/roles', auth: true);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map(
          (e) => StaffRoleInfo(
            id: e['id'] as String,
            label: e['label'] as String? ?? e['id'] as String,
            summary: e['summary'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<List<AuthUser>> getStaff() async {
    final json = await _api.get('/api/staff', auth: true);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AuthUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AuthUser> createStaff({
    required String name,
    required String email,
    required String password,
    required List<String> roles,
  }) async {
    final json = await _api.post(
      '/api/staff',
      auth: true,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'roles': roles,
      },
    );
    return AuthUser.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<AuthUser> updateStaff({
    required int staffId,
    String? name,
    String? email,
    String? password,
    List<String>? roles,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (roles != null) body['roles'] = roles;
    if (isActive != null) body['is_active'] = isActive;
    final json = await _api.put('/api/staff/$staffId', auth: true, body: body);
    return AuthUser.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<AuthUser> deactivateStaff(int staffId) async {
    final json = await _api.delete('/api/staff/$staffId', auth: true);
    return AuthUser.fromJson(json['data'] as Map<String, dynamic>);
  }
}
