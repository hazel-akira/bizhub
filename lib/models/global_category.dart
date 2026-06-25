class GlobalCategory {
  const GlobalCategory({
    required this.id,
    required this.name,
    this.description,
    this.productsCount = 0,
  });

  final int id;
  final String name;
  final String? description;
  final int productsCount;

  factory GlobalCategory.fromJson(Map<String, dynamic> json) {
    return GlobalCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      productsCount: json['products_count'] as int? ?? 0,
    );
  }
}
