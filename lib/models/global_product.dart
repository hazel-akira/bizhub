class GlobalProduct {
  const GlobalProduct({
    required this.id,
    required this.name,
    this.description,
    this.barcode,
    this.unit = 'pcs',
    this.globalCategoryId,
    this.categoryName,
  });

  final int id;
  final String name;
  final String? description;
  final String? barcode;
  final String unit;
  final int? globalCategoryId;
  final String? categoryName;

  factory GlobalProduct.fromJson(Map<String, dynamic> json) {
    return GlobalProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      barcode: json['barcode'] as String?,
      unit: json['unit'] as String? ?? 'pcs',
      globalCategoryId: json['global_category_id'] as int?,
      categoryName: json['category_name'] as String?,
    );
  }
}
