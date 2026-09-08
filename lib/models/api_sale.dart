class ApiSaleItem {
  const ApiSaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.unitCost = 0,
  });

  final int? productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double unitCost;

  double get lineProfit => (unitPrice - unitCost) * quantity;

  factory ApiSaleItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return ApiSaleItem(
      productId: json['product_id'] as int?,
      productName: product?['name'] as String? ?? 'Item',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: _toDouble(json['unit_price']),
      totalPrice: _toDouble(json['total_price']),
      unitCost: _toDouble(json['unit_cost']),
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

  bool get isUnpaid {
    if (isCollectedAtSale) return false;
    return !isPaid && outstanding > 0.001;
  }

  bool get isCollectedAtSale {
    final method = _normalizeMethod(paymentMethod);
    return method == 'cash' || method == 'mpesa' || method == 'card';
  }

  String get methodLabel {
    return switch (_normalizeMethod(paymentMethod)) {
      'mpesa' => 'M-Pesa',
      'card' => 'Card',
      'credit' => 'Credit',
      _ => 'Cash',
    };
  }

  /// Chip text: the method that was tapped, or UNPAID for credit.
  String get statusLabel => isUnpaid ? 'UNPAID' : methodLabel.toUpperCase();

  factory ApiSale.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final method = _normalizeMethod('${json['payment_method'] ?? 'cash'}');
    final total = _toDouble(json['total_amount']);
    var amountPaid = _toDouble(json['amount_paid']);
    var outstanding = json.containsKey('outstanding')
        ? _toDouble(json['outstanding'])
        : (total - amountPaid).clamp(0, double.infinity).toDouble();
    var isPaid = _toBool(json['is_paid']) ?? outstanding <= 0.001;

    final collectedNow =
        method == 'cash' || method == 'mpesa' || method == 'card';
    if (collectedNow) {
      if (amountPaid <= 0) amountPaid = total;
      outstanding = 0;
      isPaid = true;
    }

    return ApiSale(
      id: _asInt(json['id']),
      totalAmount: total,
      paymentMethod: method,
      saleDate: DateTime.tryParse('${json['sale_date'] ?? ''}') ??
          DateTime.tryParse('${json['created_at'] ?? ''}') ??
          DateTime.now(),
      invoiceNumber: json['invoice_number'] as String?,
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String?,
      amountPaid: amountPaid,
      outstanding: outstanding,
      isPaid: isPaid,
      items: rawItems
          .map((e) => ApiSaleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ApiSale copyWith({
    double? amountPaid,
    double? outstanding,
    bool? isPaid,
    String? paymentMethod,
  }) {
    return ApiSale(
      id: id,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      saleDate: saleDate,
      items: items,
      invoiceNumber: invoiceNumber,
      customerId: customerId,
      customerName: customerName,
      amountPaid: amountPaid ?? this.amountPaid,
      outstanding: outstanding ?? this.outstanding,
      isPaid: isPaid ?? this.isPaid,
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

  static String _normalizeMethod(String raw) {
    final compact = raw.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    return switch (compact) {
      'mpesa' || 'mpesastk' => 'mpesa',
      'credit' || 'unpaid' || 'debt' => 'credit',
      'card' => 'card',
      'cash' || '' => 'cash',
      _ => compact,
    };
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static bool? _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return null;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
