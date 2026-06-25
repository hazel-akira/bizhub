class BusinessTypeOption {
  const BusinessTypeOption({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;

  factory BusinessTypeOption.fromJson(Map<String, dynamic> json) {
    return BusinessTypeOption(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  bool get isFoodBusiness =>
      id == 'food_vendor' || id == 'small_restaurant';
}
