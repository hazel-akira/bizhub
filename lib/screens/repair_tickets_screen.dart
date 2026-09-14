import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/layout.dart';
import '../models/api_repair_ticket.dart';
import '../models/product_department.dart';
import '../providers/api_data_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/business_api_provider.dart';
import '../widgets/access_denied_page.dart';
import '../widgets/centered_dialog.dart';
import '../providers/business_theme_provider.dart';

class RepairTicketsScreen extends ConsumerStatefulWidget {
  const RepairTicketsScreen({super.key});

  @override
  ConsumerState<RepairTicketsScreen> createState() =>
      _RepairTicketsScreenState();
}

class _RepairTicketsScreenState extends ConsumerState<RepairTicketsScreen> {
  String? _statusFilter;

  Future<void> _createTicket() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final issueCtrl = TextEditingController();
    final partsCtrl = TextEditingController();
    final laborCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    final palette = ref.read(businessThemePaletteProvider);

    final saved = await showCenteredDialog<bool>(
      context,
      palette: palette,
      builder: (ctx, colors) => CenteredDialogFrame(
        palette: colors,
        title: 'New repair job',
        subtitle: 'Fundi wa simu — customer, phone, and labour',
        body: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Customer name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Customer phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone model',
                  hintText: 'Tecno Spark 10',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: issueCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Issue description',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: partsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Spare parts used',
                  hintText: 'Screen, charging port',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: laborCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Labour cost (KES)'),
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
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save job'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    try {
      await ref.read(createRepairTicketProvider)(
        customerName: nameCtrl.text.trim(),
        customerPhone: phoneCtrl.text.trim(),
        phoneModel: modelCtrl.text.trim(),
        issueDescription: issueCtrl.text.trim(),
        sparePartsUsed: partsCtrl.text.trim(),
        laborCost: double.tryParse(laborCtrl.text.trim()) ?? 0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repair ticket saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(ApiRepairTicket ticket, String status) async {
    try {
      await ref.read(updateRepairTicketProvider)(
        ticketId: ticket.id,
        status: status,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canOpenRepairs) {
      return const AccessDeniedPage(title: 'Repairs');
    }

    final useCloud = ref.watch(useCloudDataProvider);
    final ticketsAsync = ref.watch(apiRepairTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fundi wa simu'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (useCloud && access.canSell)
            IconButton(
              tooltip: 'New repair job',
              icon: const Icon(Icons.add),
              onPressed: _createTicket,
            ),
        ],
      ),
      body: !useCloud
          ? const Center(child: Text('Sign in to track phone repair jobs.'))
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(apiRepairTicketsProvider),
              child: ticketsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: $e'),
                    ),
                  ],
                ),
                data: (tickets) {
                  final visible = tickets
                      .where(
                        (t) =>
                            _statusFilter == null || t.status == _statusFilter,
                      )
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _statusFilter == null,
                            onSelected: (_) =>
                                setState(() => _statusFilter = null),
                          ),
                          ...RepairTicketStatus.values.map(
                            (id) => ChoiceChip(
                              label: Text(RepairTicketStatus.label(id)),
                              selected: _statusFilter == id,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = id),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (visible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(
                            child: Text('No repair jobs yet.'),
                          ),
                        )
                      else
                        ...visible.map((ticket) {
                          final next = ticket.status == RepairTicketStatus.pending
                              ? RepairTicketStatus.fixed
                              : ticket.status == RepairTicketStatus.fixed
                                  ? RepairTicketStatus.collected
                                  : null;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              isThreeLine: true,
                              title: Text(
                                '${ticket.ticketNumber} • ${ticket.phoneModel}',
                              ),
                              subtitle: Text(
                                [
                                  ticket.customerName,
                                  ticket.issueDescription,
                                  if ((ticket.sparePartsUsed ?? '').isNotEmpty)
                                    'Parts: ${ticket.sparePartsUsed}',
                                  'Labour KES ${ticket.laborCost.toStringAsFixed(0)}'
                                      ' • ${ticket.statusLabel ?? RepairTicketStatus.label(ticket.status)}',
                                  if (ticket.createdAt != null)
                                    AppLayout.stamp(ticket.createdAt!),
                                ].join('\n'),
                              ),
                              trailing: next == null || !access.canSell
                                  ? null
                                  : TextButton(
                                      onPressed: () =>
                                          _updateStatus(ticket, next),
                                      child: Text(
                                        next == RepairTicketStatus.fixed
                                            ? 'Mark fixed'
                                            : 'Collected',
                                      ),
                                    ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
