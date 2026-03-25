import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/whatsapp_helper.dart';
import '../database/app_database.dart';
import '../providers/customers_provider.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickFromContacts() async {
    try {
      final pickedId = await FlutterContacts.native.showPicker();
      if (pickedId == null || !mounted) return;

      final contact = await FlutterContacts.get(
        pickedId,
        properties: {ContactProperty.name, ContactProperty.phone},
      );
      if (contact == null || !mounted) return;

      final name = contact.displayName ?? '';
      final phone = contact.phones.isNotEmpty
          ? contact.phones.first.number
          : '';

      setState(() {
        _nameController.text = name;
        _phoneController.text = phone;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('permission')
                  ? 'Contact access denied'
                  : 'Could not pick contact',
            ),
          ),
        );
      }
    }
  }

  Future<void> _addCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final addCustomer = ref.read(addCustomerProvider);
    final duplicate = await addCustomer(name, phone: phone);
    if (!mounted) return;

    if (duplicate != null) {
      await _showDuplicateCustomerDialog(duplicate, name);
      return;
    }

    ref.invalidate(customersProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer added')),
    );
    _nameController.clear();
    _phoneController.clear();
  }

  Future<void> _showDuplicateCustomerDialog(Customer existing, String attemptedName) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customer already exists'),
        content: Text(
          'The phone number matches "${existing.name}" '
          '${existing.phone.isNotEmpty ? "(${existing.phone})" : ""}.\n\n'
          'Each phone can only be added once.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showCustomerSheet(existing);
            },
            child: const Text('View customer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomerSheet(Customer c) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                c.name,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (c.phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  c.phone,
                  style: Theme.of(ctx).textTheme.bodyLarge,
                ),
              ] else
                Text(
                  'No phone on file',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.outline,
                      ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showEditCustomerDialog(c);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              const SizedBox(height: 8),
              if (c.phone.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await openWhatsAppChat(
                      c.phone,
                      message:
                          'Hi ${c.name}! I\'d like to place a samosa order.',
                    );
                    if (!ctx.mounted) return;
                    if (!ok) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Could not open WhatsApp')),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat, color: Colors.green),
                  label: const Text('Message on WhatsApp'),
                ),
              if (c.phone.isNotEmpty) const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmDeleteCustomer(c);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditCustomerDialog(Customer c) async {
    final nameCtrl = TextEditingController(text: c.name);
    final phoneCtrl = TextEditingController(text: c.phone);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit customer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      return;
    }

    final update = ref.read(updateCustomerProvider);
    final dup = await update(
      c.id,
      nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();

    if (!mounted) return;
    ref.invalidate(customersProvider);

    if (dup != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'That phone is already used by "${dup.name}".',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer updated')),
    );
  }

  Future<void> _confirmDeleteCustomer(Customer c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text(
          'Remove "${c.name}" from your list? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final deleteFn = ref.read(deleteCustomerProvider);
    final deleted = await deleteFn(c.id);
    if (!mounted) return;
    ref.invalidate(customersProvider);

    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete: this customer has orders. Fulfill or archive orders first.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regular Customers'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add customer',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickFromContacts,
                            icon: const Icon(Icons.contacts, size: 20),
                            label: const Text('From contacts'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you enter a phone, we match duplicates using the same number (e.g. 07… and 254… count as one).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Customer name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone (optional)',
                          hintText: 'e.g. 07XX XXX XXX',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addCustomer,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Customer'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your customers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a customer for edit, delete, or WhatsApp.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            customersAsync.when(
              data: (customers) => customers.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No customers yet. Add your regulars above.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  : Column(
                      children: customers
                          .map(
                            (c) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                onTap: () => _showCustomerSheet(c),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: Text(
                                    c.name.isNotEmpty
                                        ? c.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: c.phone.isNotEmpty
                                    ? Text(c.phone)
                                    : const Text('No phone'),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            ),
                          )
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
