import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { customer, businessOwner }

class UserRoleService {
  UserRoleService._();
  static final UserRoleService instance = UserRoleService._();

  static const _roleKey = 'user_role';

  Future<UserRole?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roleKey);
    if (raw == null) return null;
    return UserRole.values.firstWhere(
      (role) => role.name == raw,
      orElse: () => UserRole.businessOwner,
    );
  }

  Future<void> saveRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
  }
}
