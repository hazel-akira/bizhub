import 'package:flutter/material.dart';

import '../services/user_role_service.dart';
import '../main.dart';
import 'customer_home_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, UserRole role) async {
    await UserRoleService.instance.saveRole(role);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => role == UserRole.customer
            ? const CustomerHomeScreen()
            : const MainNavScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Role')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How will you use Akira BizHub?',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('Customer'),
                subtitle: const Text('Browse products and order via WhatsApp'),
                onTap: () => _selectRole(context, UserRole.customer),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Business Owner'),
                subtitle: const Text('Manage products, sales, and reports'),
                onTap: () => _selectRole(context, UserRole.businessOwner),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
