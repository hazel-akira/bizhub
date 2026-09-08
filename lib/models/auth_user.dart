import '../core/staff_access.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.roles = const [],
    this.permissions = const [],
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
  final List<String> roles;
  final List<String> permissions;
  final int? businessId;
  final String? businessName;
  final String? businessType;
  final String? businessTypeLabel;
  final bool isActive;

  bool get isFoodBusiness =>
      businessType == 'food_vendor' || businessType == 'small_restaurant';

  List<String> get resolvedRoles {
    final normalized = StaffAccess.normalize(
      roles.isNotEmpty ? roles : [role ?? StaffAccess.owner],
    );
    return normalized.isEmpty ? const [StaffAccess.owner] : normalized;
  }

  List<String> get resolvedPermissions {
    if (permissions.isNotEmpty) return permissions;
    return StaffAccess.permissionsFor(resolvedRoles);
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String?,
      roles: _stringList(json['roles']),
      permissions: _stringList(json['permissions']),
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
        'roles': roles,
        'permissions': permissions,
        'business_id': businessId,
        'business_name': businessName,
        'business_type': businessType,
        'business_type_label': businessTypeLabel,
        'is_active': isActive,
      };

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}
