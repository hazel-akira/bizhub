class ApiProduct {
  const ApiProduct({
    required this.id,
    required this.name,
    required this.sellingPrice,
    this.stockQuantity = 0,
    this.isActive = true,
    this.globalProductId,
    this.isFromGlobalCatalog = false,
    this.unit,
    this.imagePath,
  });

  final int id;
  final String name;
  final double sellingPrice;
  final int stockQuantity;
  final bool isActive;
  final int? globalProductId;
  final bool isFromGlobalCatalog;
  final String? unit;
  final String? imagePath;

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      sellingPrice: _toDouble(json['selling_price'] ?? json['price']),
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      globalProductId: json['global_product_id'] as int?,
      isFromGlobalCatalog: json['is_from_global_catalog'] as bool? ?? false,
      unit: json['unit'] as String?,
      imagePath: json['image_path'] as String?,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
