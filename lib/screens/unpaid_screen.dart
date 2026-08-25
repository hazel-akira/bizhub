import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/whatsapp_helper.dart';
import '../database/app_database.dart';
import '../providers/unpaid_provider.dart';
import '../widgets/sales/mpesa_checkout_flow.dart';

class UnpaidScreen extends ConsumerStatefulWidget {
  const UnpaidScreen({super.key});

  @override
  ConsumerState<UnpaidScreen> createState() => _UnpaidScreenState();
}

class _UnpaidScreenState extends ConsumerState<UnpaidScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addRecord() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    final notes = _notesController.text.trim();
    if (name.isEmpty || amount <= 0) return;

    final addUnpaid = ref.read(addUnpaidProvider);
    await addUnpaid(name, amount, notes: notes);
    ref.invalidate(unpaidRecordsProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Record added')));
      _nameController.clear();
      _amountController.clear();
      _notesController.clear();
    }
  }

  Future<void> _collectMpesa(UnpaidRecord record) async {
    final result = await MpesaCheckoutFlow.collect(
      context: context,
      ref: ref,
      amount: record.amount,
      reference: 'unpaid_${record.id}',
    );
    if (result == null || !mounted) return;

    final markPaid = ref.read(markPaidProvider);
    await markPaid(record.id);
    ref.invalidate(unpaidRecordsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.mpesaReceiptNumber == null
                ? 'M-Pesa payment received. Marked as paid.'
                : 'M-Pesa ${result.mpesaReceiptNumber}. Marked as paid.',
          ),
        ),
      );
    }
  }

  Future<void> _markAsPaid(UnpaidRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as paid?'),
        content: Text(
          '${record.customerName} - KES ${record.amount.toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark paid'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final markPaid = ref.read(markPaidProvider);
      await markPaid(record.id);
      ref.invalidate(unpaidRecordsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Marked as paid')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unpaidAsync = ref.watch(unpaidRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haven\'t Paid'),
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
                      Text(
                        'Add unpaid record',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Person who hasn\'t paid',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount (KES)',
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Enter valid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes (optional)',
                          hintText: 'e.g. Phone number, items',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addRecord,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Record'),
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
              'People who haven\'t paid',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            unpaidAsync.when(
              data: (records) => records.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No unpaid records',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  : Column(
                      children: records
                          .map(
                            (r) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  r.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (r.notes.isNotEmpty) Text(r.notes),
                                    Text(
                                      _formatDate(r.date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'KES ${r.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chat),
                                      onPressed: () {
                                        final msg =
                                            'Hi ${r.customerName}, reminder: you owe KES ${r.amount.toStringAsFixed(0)}'
                                            '${r.notes.isNotEmpty ? ' (${r.notes})' : ''}. Please pay when you can.';
                                        shareToWhatsApp(msg);
                                      },
                                      tooltip: 'Remind on WhatsApp',
                                      style: IconButton.styleFrom(
                                        foregroundColor: Colors.green,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.phone_android),
                                      onPressed: () => _collectMpesa(r),
                                      tooltip: 'Collect via M-Pesa',
                                      style: IconButton.styleFrom(
                                        foregroundColor: Colors.teal,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                      onPressed: () => _markAsPaid(r),
                                      tooltip: 'Mark as paid (cash)',
                                    ),
                                  ],
                                ),
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

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
