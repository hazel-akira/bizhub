import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/production_provider.dart';
import '../providers/business_profile_provider.dart';
import '../widgets/food_only_screen.dart';

class ProductionScreen extends ConsumerStatefulWidget {
  const ProductionScreen({super.key});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends ConsumerState<ProductionScreen> {
  final _ndenguCtrl = TextEditingController();
  final _meatCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _loadedDate;

  @override
  void dispose() {
    _ndenguCtrl.dispose();
    _meatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ndengu = int.tryParse(_ndenguCtrl.text.trim()) ?? 0;
    final meat = int.tryParse(_meatCtrl.text.trim()) ?? 0;
    final selectedDate = ref.read(selectedProductionDateProvider);
    await ref.read(saveProductionBatchProvider)(
          date: selectedDate,
          ndenguPrepared: ndengu,
          meatPrepared: meat,
        );
    ref.invalidate(productionBatchProvider);
    ref.invalidate(productionSummaryProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Production batch saved')),
    );
  }

  Future<void> _pickDate() async {
    final current = ref.read(selectedProductionDateProvider);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: current,
    );
    if (picked == null) return;
    ref.read(selectedProductionDateProvider.notifier).state =
        DateTime(picked.year, picked.month, picked.day);
    _loadedDate = null;
    _ndenguCtrl.clear();
    _meatCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(businessTypeConfigProvider);
    if (!config.isFoodBusiness) {
      return const FoodOnlyScreen(
        title: 'Production',
        child: SizedBox.shrink(),
      );
    }

    final selectedDate = ref.watch(selectedProductionDateProvider);
    final batchAsync = ref.watch(productionBatchProvider);
    final summaryAsync = ref.watch(productionSummaryProvider);
    final dateLabel =
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Selected date'),
                subtitle: Text(dateLabel),
                trailing: OutlinedButton(
                  onPressed: _pickDate,
                  child: const Text('Change'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            batchAsync.when(
              data: (batch) {
                final isNewDate = _loadedDate == null ||
                    _loadedDate!.year != selectedDate.year ||
                    _loadedDate!.month != selectedDate.month ||
                    _loadedDate!.day != selectedDate.day;
                if (isNewDate) {
                  if (batch != null) {
                    _ndenguCtrl.text = batch.ndenguPrepared.toString();
                    _meatCtrl.text = batch.meatPrepared.toString();
                  } else {
                    _ndenguCtrl.text = '0';
                    _meatCtrl.text = '0';
                  }
                  _loadedDate = selectedDate;
                } else if (batch != null &&
                    _ndenguCtrl.text.isEmpty &&
                    _meatCtrl.text.isEmpty) {
                  _ndenguCtrl.text = batch.ndenguPrepared.toString();
                  _meatCtrl.text = batch.meatPrepared.toString();
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _ndenguCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Ndengu prepared',
                            ),
                            validator: (v) =>
                                (int.tryParse(v ?? '') == null) ? 'Enter a number' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _meatCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Meat prepared',
                            ),
                            validator: (v) =>
                                (int.tryParse(v ?? '') == null) ? 'Enter a number' : null,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Batch for Date'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              data: (summary) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prepared: Ndengu ${summary.ndenguPrepared}, Meat ${summary.meatPrepared}'),
                      const SizedBox(height: 6),
                      Text('Sold: Ndengu ${summary.ndenguSold}, Meat ${summary.meatSold}'),
                      const SizedBox(height: 6),
                      Text(
                        'Remaining: Ndengu ${summary.ndenguRemaining}, Meat ${summary.meatRemaining}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
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
