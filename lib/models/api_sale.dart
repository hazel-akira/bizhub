class ApiSaleItem {
  const ApiSaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final int? productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  factory ApiSaleItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return ApiSaleItem(
      productId: json['product_id'] as int?,
      productName: product?['name'] as String? ?? 'Item',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: _toDouble(json['unit_price']),
      totalPrice: _toDouble(json['total_price']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}

class ApiSale {
  const ApiSale({
    required this.id,
    required this.totalAmount,
    required this.paymentMethod,
    required this.saleDate,
    required this.items,
    this.invoiceNumber,
    this.customerId,
    this.customerName,
    this.amountPaid = 0,
    this.outstanding = 0,
    this.isPaid = true,
  });

  final int id;
  final double totalAmount;
  final String paymentMethod;
  final DateTime saleDate;
  final List<ApiSaleItem> items;
  final String? invoiceNumber;
  final int? customerId;
  final String? customerName;
  final double amountPaid;
  final double outstanding;
  final bool isPaid;

  factory ApiSale.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ApiSale(
      id: json['id'] as int,
      totalAmount: _toDouble(json['total_amount']),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      saleDate: DateTime.tryParse(json['sale_date'] as String? ?? '') ??
          DateTime.now(),
      invoiceNumber: json['invoice_number'] as String?,
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String?,
      amountPaid: _toDouble(json['amount_paid']),
      outstanding: _toDouble(json['outstanding']),
      isPaid: json['is_paid'] as bool? ?? false,
      items: rawItems
          .map((e) => ApiSaleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get displayLabel {
    if (customerName != null && customerName!.trim().isNotEmpty) {
      return customerName!.trim();
    }
    if (invoiceNumber != null && invoiceNumber!.trim().isNotEmpty) {
      return invoiceNumber!.trim();
    }
    return 'Sale #$id';
  }

  String get itemsSummary =>
      items.map((i) => '${i.quantity}× ${i.productName}').join(', ');

  int get totalQuantity =>
      items.fold<int>(0, (sum, i) => sum + i.quantity);

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
