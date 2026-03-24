import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../providers/sales_provider.dart';
import '../providers/dashboard_provider.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _ndenguController = TextEditingController(text: '0');
  final _meatController = TextEditingController(text: '0');

  @override
  void dispose() {
    _ndenguController.dispose();
    _meatController.dispose();
    super.dispose();
  }

  double get _totalRevenue {
    final ndengu = int.tryParse(_ndenguController.text) ?? 0;
    final meat = int.tryParse(_meatController.text) ?? 0;
    return (ndengu * SamosaPrices.ndenguPrice) +
        (meat * SamosaPrices.meatPrice);
  }

  Future<void> _recordSale() async {
    final ndengu = int.tryParse(_ndenguController.text) ?? 0;
    final meat = int.tryParse(_meatController.text) ?? 0;
    if (ndengu == 0 && meat == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one samosa count')),
      );
      return;
    }
    final addSale = ref.read(addSaleProvider);
    await addSale(DateTime.now(), ndengu, meat);
    ref.invalidate(todaySalesProvider);
    ref.invalidate(allSalesProvider);
    ref.invalidate(todayStatsProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sale recorded!')));
      _ndenguController.text = '0';
      _meatController.text = '0';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Sales'),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ndengu Samosas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ndenguController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: '× KES ${SamosaPrices.ndenguPrice.toInt()}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Meat Samosas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _meatController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: '× KES ${SamosaPrices.meatPrice.toInt()}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Revenue',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'KES ${_totalRevenue.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _recordSale,
              icon: const Icon(Icons.check_circle),
              label: const Text('Record Sale'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
