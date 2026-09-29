class ApiCategory {
  const ApiCategory({
    required this.id,
    required this.name,
    this.description,
  });

  final int id;
  final String name;
  final String? description;

  factory ApiCategory.fromJson(Map<String, dynamic> json) {
    return ApiCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}
