import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/phone_utils.dart';
import '../core/whatsapp_helper.dart';
import '../database/app_database.dart';
import '../providers/dashboard_provider.dart';
import '../providers/business_api_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/unpaid_customers_provider.dart';
import 'orders_screen.dart';
import 'unpaid_customers_screen.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _showAddUnpaidSaleSheet() async {
    final qtyCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final scrollController = ScrollController();
    int? selectedCustomerId;
    bool isSaving = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) {
          final customersAsync = ref.watch(customersProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: customersAsync.when(
                data: (customers) {
                  if (customers.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Add a customer first before recording an unpaid sale.',
                            style: Theme.of(ctx).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }

                  selectedCustomerId ??= customers.first.id;
                  final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
                  return StatefulBuilder(
                    builder: (ctx, setLocal) {
                      void scrollToTop() {
                        Future.delayed(const Duration(milliseconds: 80), () {
                          if (!scrollController.hasClients) return;
                          scrollController.animateTo(
                            scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        });
                      }

                      return SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.only(bottom: bottomInset),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Add Sale (Unpaid)',
                              style: Theme.of(ctx).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int?>(
                              key: ValueKey(selectedCustomerId),
                              initialValue: selectedCustomerId,
                              decoration: const InputDecoration(
                                labelText: 'Customer',
                              ),
                              items: customers
                                  .map(
                                    (c) => DropdownMenuItem<int?>(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setLocal(() => selectedCustomerId = v),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: qtyCtrl,
                              onTap: scrollToTop,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                hintText: 'e.g. 10',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: amountCtrl,
                              onTap: scrollToTop,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Total amount (KES)',
                                hintText: 'e.g. 400',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final customerId = selectedCustomerId;
                                      if (customerId == null) {
                                        if (!ctx.mounted) return;
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text('Select a customer'),
                                          ),
                                        );
                                        return;
                                      }

                                      final qtyRaw = double.tryParse(
                                        qtyCtrl.text.trim(),
                                      );
                                      final qty = qtyRaw == null
                                          ? 0
                                          : qtyRaw.round();
                                      final total =
                                          double.tryParse(
                                            amountCtrl.text.trim(),
                                          ) ??
                                          0;
                                      if (qty <= 0 || total <= 0) {
                                        if (!ctx.mounted) return;
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Enter valid quantity and amount',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final customer = customers.firstWhere(
                                        (c) => c.id == customerId,
                                      );

                                      final addUnpaid = ref.read(
                                        addUnpaidSaleProvider,
                                      );
                                      setLocal(() => isSaving = true);
                                      try {
                                        await addUnpaid(
                                          customerName: customer.name,
                                          quantity: qty,
                                          totalAmount: total,
                                          customerId: customerId,
                                        );

                                        ref.invalidate(allSalesProvider);
                                        ref.invalidate(salesListItemsProvider);
                                        refreshCustomerRelatedProviders(ref);
                                        ref.invalidate(
                                          unpaidSalesWithOutstandingProvider,
                                        );
                                        ref.invalidate(
                                          unpaidCustomersDebtProvider,
                                        );
                                        ref.invalidate(todayStatsProvider);

                                        if (!ctx.mounted) return;
                                        Navigator.pop(ctx);

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Unpaid sale added'),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!ctx.mounted) return;
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to add unpaid sale: $e',
                                            ),
                                          ),
                                        );
                                      } finally {
                                        if (ctx.mounted) {
                                          setLocal(() => isSaving = false);
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.add),
                              label: const Text('Save as Unpaid'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ),
          );
        },
      );
    } finally {
      qtyCtrl.dispose();
      amountCtrl.dispose();
      scrollController.dispose();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickFromContacts() async {
    try {
      final hasAccess =
          await FlutterContacts.permissions.has(PermissionType.read);
      if (!hasAccess) {
        final status =
            await FlutterContacts.permissions.request(PermissionType.read);
        if (status != PermissionStatus.granted &&
            status != PermissionStatus.limited) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact access denied')),
            );
          }
          return;
        }
      }

      final contact = await FlutterContacts.native.showPicker(
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

    try {
      final addCustomer = ref.read(addCustomerProvider);
      final duplicate = await addCustomer(name, phone: phone);
      if (!mounted) return;

      if (duplicate != null) {
        await _showDuplicateCustomerDialog(duplicate, name);
        return;
      }

      refreshCustomerRelatedProviders(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added')),
      );
      _nameController.clear();
      _phoneController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add customer: $e')),
      );
    }
  }

  Future<void> _showDuplicateCustomerDialog(
    Customer existing,
    String attemptedName,
  ) async {
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
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (c.phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  formatPhoneForDisplay(c.phone),
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
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrdersScreen(initialCustomerId: c.id),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Create verbal order'),
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
                        const SnackBar(
                          content: Text('Could not open WhatsApp'),
                        ),
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
    final phoneCtrl = TextEditingController(text: formatPhoneForDisplay(c.phone));
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
    refreshCustomerRelatedProviders(ref);
    ref.invalidate(unpaidSalesWithOutstandingProvider);
    ref.invalidate(unpaidCustomersDebtProvider);

    if (dup != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('That phone is already used by "${dup.name}".')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Customer updated')));
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
    final failureReason = await deleteFn(c.id);
    if (!mounted) return;
    refreshCustomerRelatedProviders(ref);

    if (failureReason == 'orders') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete: this customer has orders. Fulfill or archive orders first.',
          ),
        ),
      );
      return;
    }

    if (failureReason == 'balance') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete: this customer still has an outstanding balance.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Customer removed')));
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final hasCustomers = customersAsync.maybeWhen(
      data: (customers) => customers.isNotEmpty,
      orElse: () => false,
    );

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
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: hasCustomers ? _showAddUnpaidSaleSheet : null,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add Sale (Unpaid)'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    if (!hasCustomers)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Add at least one customer to record unpaid sales.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const UnpaidCustomersScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.money_off_csred_outlined),
                      label: const Text('Unpaid Customers'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
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
            Consumer(
              builder: (context, ref, _) {
                final useCloud = ref.watch(useCloudDataProvider);
                if (useCloud) {
                  final unpaidAsync = ref.watch(unpaidCustomersDebtProvider);
                  return unpaidAsync.when(
                    data: (rows) => rows.isEmpty
                        ? const SizedBox.shrink()
                        : Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Unpaid: ${rows.map((e) => '${e.customerName} (KES ${e.outstanding.toStringAsFixed(0)})').join(', ')}',
                              ),
                            ),
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Text('Could not load unpaid sales: $e'),
                  );
                }

                final unpaidAsync = ref.watch(unpaidCustomersProvider);
                return unpaidAsync.when(
                  data: (list) => list.isEmpty
                      ? const SizedBox.shrink()
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Unpaid customers: ${list.map((e) => e.name).join(', ')}',
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text('Unpaid customers error: $e'),
                );
              },
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
                                    ? Consumer(
                                        builder: (context, ref, _) {
                                          final bal = ref.watch(
                                            customerBalanceProvider(c.id),
                                          );
                                          return bal.when(
                                            data: (value) => Text(
                                              '${formatPhoneForDisplay(c.phone)} • Balance: KES ${value.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: value > 0
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.error
                                                    : Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            loading: () =>
                                                Text(formatPhoneForDisplay(c.phone)),
                                            error: (e, _) =>
                                                Text(formatPhoneForDisplay(c.phone)),
                                          );
                                        },
                                      )
                                    : Consumer(
                                        builder: (context, ref, _) {
                                          final bal = ref.watch(
                                            customerBalanceProvider(c.id),
                                          );
                                          return bal.when(
                                            data: (value) => Text(
                                              'No phone • Balance: KES ${value.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: value > 0
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.error
                                                    : Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            loading: () =>
                                                const Text('No phone'),
                                            error: (e, _) =>
                                                const Text('No phone'),
                                          );
                                        },
                                      ),
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
