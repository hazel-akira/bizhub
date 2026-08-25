import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../services/sales_reminder_service.dart';
import '../widgets/mpesa_settings_card.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loading = true;
  bool _enabled = true;
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await SalesReminderService.instance.getSettings();
      if (!mounted) return;
      setState(() {
        _enabled = s.enabled;
        _time = TimeOfDay(hour: s.hour, minute: s.minute);
        _loadError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Fallback to safe defaults so settings page remains usable.
      setState(() {
        _enabled = true;
        _time = const TimeOfDay(hour: 19, minute: 0);
        _loadError = 'Could not load settings from device storage.';
        _loading = false;
      });
    }
  }

  Future<void> _saveAndSync() async {
    final service = SalesReminderService.instance;
    await service.saveSettings(
      SalesReminderSettings(
        enabled: _enabled,
        hour: _time.hour,
        minute: _time.minute,
      ),
    );

    final db = ref.read(databaseProvider);
    final salesToday = await db.getSalesForDate(DateTime.now());
    await service.syncDailyReminder(hasSalesToday: salesToday.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AccountCard(
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
          const SizedBox(height: 16),
          const MpesaSettingsCard(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loading) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],
                  if (_loadError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _loadError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Sales Reminder',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable daily reminder'),
                    subtitle: const Text(
                      'Notify me if no sales are recorded today.',
                    ),
                    value: _enabled,
                    onChanged: _loading ? null : (v) => setState(() => _enabled = v),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reminder time'),
                    subtitle: Text(_time.format(context)),
                    trailing: const Icon(Icons.schedule),
                    onTap: _enabled && !_loading
                        ? () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _time,
                            );
                            if (picked == null) return;
                            setState(() => _time = picked);
                          }
                        : null,
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _loading
                        ? null
                        : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await _saveAndSync();
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Settings saved')),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Settings'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(user?.name ?? '—'),
              subtitle: Text(user?.email ?? 'Not signed in'),
            ),
            if (user?.businessName != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.store_outlined),
                title: Text(user!.businessName!),
                subtitle: Text(user.role ?? 'owner'),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: user == null ? null : onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

