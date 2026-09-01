import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profit_tracker_provider.dart';
import '../providers/business_profile_provider.dart';
import '../providers/business_api_provider.dart';
import '../widgets/food_only_screen.dart';

class ProfitTrackerScreen extends ConsumerStatefulWidget {
  const ProfitTrackerScreen({super.key});

  @override
  ConsumerState<ProfitTrackerScreen> createState() =>
      _ProfitTrackerScreenState();
}

class _ProfitTrackerScreenState extends ConsumerState<ProfitTrackerScreen> {
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController(text: '40');

  final _meatCostController = TextEditingController();
  final _dhaniaCostController = TextEditingController();

  final _flourWeeklyController = TextEditingController();
  final _onionsWeeklyController = TextEditingController();
  final _oilMonthlyController = TextEditingController();

  final _gasController = TextEditingController();
  final _transportController = TextEditingController();
  final _labourController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _qtyController,
      _priceController,
      _meatCostController,
      _dhaniaCostController,
      _flourWeeklyController,
      _onionsWeeklyController,
      _oilMonthlyController,
      _gasController,
      _transportController,
      _labourController,
    ]) {
      c.addListener(_recalcAndRefresh);
    }
  }

  void _recalcAndRefresh() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _qtyController,
      _priceController,
      _meatCostController,
      _dhaniaCostController,
      _flourWeeklyController,
      _onionsWeeklyController,
      _oilMonthlyController,
      _gasController,
      _transportController,
      _labourController,
    ]) {
      c.removeListener(_recalcAndRefresh);
      c.dispose();
    }
    super.dispose();
  }

  double _d(String s) => double.tryParse(s.trim()) ?? 0;
  int _i(String s) => int.tryParse(s.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(businessTypeConfigProvider);
    if (!config.isFoodBusiness) {
      return const FoodOnlyScreen(
        title: 'Profit tracker',
        child: SizedBox.shrink(),
      );
    }

    final qty = _i(_qtyController.text);
    final pricePerSamosa = _d(_priceController.text);

    final meatCost = _d(_meatCostController.text);
    final dhaniaCost = _d(_dhaniaCostController.text);

    final flourDaily = _d(_flourWeeklyController.text) / 7;
    final onionsDaily = _d(_onionsWeeklyController.text) / 7;
    final oilDaily = _d(_oilMonthlyController.text) / 30;

    final gasCost = _d(_gasController.text);
    final transportCost = _d(_transportController.text);
    final labourCost = _d(_labourController.text);

    final revenue = (qty * pricePerSamosa);
    final totalCosts = flourDaily +
        onionsDaily +
        oilDaily +
        meatCost +
        dhaniaCost +
        gasCost +
        transportCost +
        labourCost;
    final profit = revenue - totalCosts;

    final isProfit = profit >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;

    final useCloud = ref.watch(useCloudDataProvider);
    final recordsAsync = useCloud ? null : ref.watch(profitRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profitRecordsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Today Inputs',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _qtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: false,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Total samosas prepared',
                          hintText: 'e.g. 60',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price per samosa (KES)',
                          hintText: 'Default 40',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Shared Costs',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _flourWeeklyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Flour cost (weekly total)',
                          hintText: 'KES per week',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _onionsWeeklyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Onions cost (weekly total)',
                          hintText: 'KES per week',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _oilMonthlyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Oil cost (monthly total)',
                          hintText: 'KES per month',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Daily Costs',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _meatCostController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Meat cost (daily)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dhaniaCostController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Dhania cost (daily)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _gasController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Gas/Charcoal (daily)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _transportController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Transport (daily)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _labourController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Labour (KES) - your time/effort',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculated',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _CalcRow(
                        label: 'Total Revenue',
                        value: revenue,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _CalcRow(
                        label: 'Total Costs',
                        value: totalCosts,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _CalcRow(
                        label: 'Net Profit',
                        value: profit,
                        color: profitColor,
                        valueStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: profitColor,
                            ),
                      ),
                      const SizedBox(height: 14),
                      if (useCloud)
                        Text(
                          'Signed in — profit is tracked on the Dashboard from sales and expenses. '
                          'Saving detailed cost breakdowns here is offline-only.',
                          style: TextStyle(color: Colors.grey[700]),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                final qtyOk = qty > 0;
                                if (!qtyOk) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Enter prepared quantity (> 0)'),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _isSaving = true);
                                try {
                                  await ref.read(addProfitRecordProvider)(
                                    samosasPrepared: qty,
                                    pricePerSamosa: pricePerSamosa,
                                    meatCost: meatCost,
                                    dhaniaCost: dhaniaCost,
                                    flourWeeklyCost:
                                        _d(_flourWeeklyController.text),
                                    onionsWeeklyCost:
                                        _d(_onionsWeeklyController.text),
                                    oilMonthlyCost:
                                        _d(_oilMonthlyController.text),
                                    gasCost: gasCost,
                                    transportCost: transportCost,
                                    labourCost: labourCost,
                                    revenue: revenue,
                                    totalCosts: totalCosts,
                                    profit: profit,
                                  );
                                  if (!context.mounted) return;
                                  ref.invalidate(profitRecordsProvider);
                                  ref.invalidate(todayProfitRecordProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Saved record')),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSaving = false);
                                  }
                                }
                              },
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save Record'),
                      ),
                    ],
                  ),
                ),
              ),
              if (!useCloud) ...[
              const SizedBox(height: 16),
              Text(
                'Previous Profit Records',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              recordsAsync!.when(
                data: (records) {
                  if (records.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No records yet.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = records[i];
                      final isProfit = r.profit >= 0;
                      final c = isProfit ? Colors.green : Colors.red;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(r.date),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              _MiniRow(
                                label: 'Revenue',
                                value: r.revenue,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 6),
                              _MiniRow(
                                label: 'Costs',
                                value: r.totalCosts,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 6),
                              _MiniRow(
                                label: 'Profit',
                                value: r.profit,
                                color: c,
                                valueStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: c,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _CalcRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final TextStyle? valueStyle;

  const _CalcRow({
    required this.label,
    required this.value,
    required this.color,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          'KES ${value.toStringAsFixed(0)}',
          style: valueStyle ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
        ),
      ],
    );
  }
}

class _MiniRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final TextStyle? valueStyle;

  const _MiniRow({
    required this.label,
    required this.value,
    required this.color,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          'KES ${value.toStringAsFixed(0)}',
          style: valueStyle ??
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
        ),
      ],
    );
  }
}

