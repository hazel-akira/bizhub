class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.businessId,
    this.businessName,
    this.businessType,
    this.businessTypeLabel,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String email;
  final String? role;
  final int? businessId;
  final String? businessName;
  final String? businessType;
  final String? businessTypeLabel;
  final bool isActive;

  bool get isFoodBusiness =>
      businessType == 'food_vendor' || businessType == 'small_restaurant';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String?,
      businessId: json['business_id'] as int?,
      businessName: json['business_name'] as String?,
      businessType: json['business_type'] as String?,
      businessTypeLabel: json['business_type_label'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'business_id': businessId,
        'business_name': businessName,
        'business_type': businessType,
        'business_type_label': businessTypeLabel,
        'is_active': isActive,
      };
}
