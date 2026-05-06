import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/phone_utils.dart';
import '../main.dart';
import '../providers/business_profile_provider.dart';
import '../providers/database_provider.dart';
import '../services/business_profile_service.dart';
import '../services/group_post_reminder_service.dart';
import '../services/sales_reminder_service.dart';
import '../services/user_role_service.dart';
import 'customer_home_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _businessNameCtrl = TextEditingController();
  final _whatsAppPhoneCtrl = TextEditingController();
  final _groupInviteUrlCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.businessOwner;
  BusinessType _selectedType = BusinessType.foodVendor;
  Set<String> _enabledModules = {};
  bool _loading = true;
  bool _enabled = true;
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  bool _groupPostEnabled = false;
  TimeOfDay _groupPostTime = const TimeOfDay(hour: 8, minute: 0);
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await BusinessProfileService.instance.getProfile();
      final role =
          await UserRoleService.instance.getRole() ?? UserRole.businessOwner;
      final s = await SalesReminderService.instance.getSettings();
      final gs = await GroupPostReminderService.instance.getSettings();
      if (!mounted) return;
      setState(() {
        _selectedRole = role;
        _businessNameCtrl.text = profile.name;
        _whatsAppPhoneCtrl.text = profile.whatsappPhone;
        _selectedType = profile.type;
        _enabledModules = {...profile.enabledModules};
        _enabled = s.enabled;
        _time = TimeOfDay(hour: s.hour, minute: s.minute);
        _groupPostEnabled = gs.enabled;
        _groupPostTime = TimeOfDay(hour: gs.hour, minute: gs.minute);
        _groupInviteUrlCtrl.text = gs.groupInviteUrl;
        _loadError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Fallback to safe defaults so settings page remains usable.
      setState(() {
        _businessNameCtrl.text = 'Akira Bites';
        _whatsAppPhoneCtrl.text = '';
        _selectedRole = UserRole.businessOwner;
        _selectedType = BusinessType.foodVendor;
        _enabledModules = BusinessProfileService.instance.modulesForType(
          BusinessType.foodVendor,
        );
        _enabled = true;
        _time = const TimeOfDay(hour: 19, minute: 0);
        _groupPostEnabled = false;
        _groupPostTime = const TimeOfDay(hour: 8, minute: 0);
        _groupInviteUrlCtrl.text = '';
        _loadError = 'Could not load settings from device storage.';
        _loading = false;
      });
    }
  }

  Future<void> _saveAndSync() async {
    final service = SalesReminderService.instance;
    final trimmedName = _businessNameCtrl.text.trim();
    final rawPhone = _whatsAppPhoneCtrl.text.trim();
    final normalizedPhone = rawPhone.isEmpty ? '' : normalizePhoneKey(rawPhone);

    await BusinessProfileService.instance.saveProfile(
      BusinessProfile(
        name: trimmedName.isEmpty ? 'Akira Bites' : trimmedName,
        whatsappPhone: normalizedPhone,
        type: _selectedType,
        enabledModules: _enabledModules,
      ),
    );
    await UserRoleService.instance.saveRole(_selectedRole);
    ref.invalidate(businessProfileProvider);

    await service.saveSettings(
      SalesReminderSettings(
        enabled: _enabled,
        hour: _time.hour,
        minute: _time.minute,
      ),
    );

    await GroupPostReminderService.instance.saveSettings(
      GroupPostReminderSettings(
        enabled: _groupPostEnabled,
        hour: _groupPostTime.hour,
        minute: _groupPostTime.minute,
        groupInviteUrl: _groupInviteUrlCtrl.text.trim(),
      ),
    );

    final db = ref.read(databaseProvider);
    final salesToday = await db.getSalesForDate(DateTime.now());
    await service.syncDailyReminder(hasSalesToday: salesToday.isNotEmpty);
    await GroupPostReminderService.instance.syncDailyReminder();
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _whatsAppPhoneCtrl.dispose();
    _groupInviteUrlCtrl.dispose();
    super.dispose();
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessNameCtrl,
                    enabled: !_loading,
                    decoration: const InputDecoration(
                      labelText: 'Business name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _whatsAppPhoneCtrl,
                    enabled: !_loading,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Business WhatsApp number',
                      hintText: 'e.g 0712345678 or 254712345678',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<UserRole>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Default app role',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.businessOwner,
                        child: Text('Business Owner'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.customer,
                        child: Text('Customer'),
                      ),
                    ],
                    onChanged: _loading
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _selectedRole = value);
                          },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<BusinessType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Business type',
                      border: OutlineInputBorder(),
                    ),
                    items: BusinessType.values
                        .map(
                          (type) => DropdownMenuItem<BusinessType>(
                            value: type,
                            child: Text(
                              BusinessProfileService.instance.labelForType(
                                type,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _loading
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedType = value;
                              _enabledModules = BusinessProfileService.instance
                                  .modulesForType(value);
                            });
                          },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Enabled Modules',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...BusinessModules.all.map((module) {
                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        BusinessProfileService.instance.labelForModule(module),
                      ),
                      value: _enabledModules.contains(module),
                      onChanged: _loading
                          ? null
                          : (value) {
                              setState(() {
                                if (value) {
                                  _enabledModules = {
                                    ..._enabledModules,
                                    module,
                                  };
                                } else {
                                  _enabledModules = {..._enabledModules}
                                    ..remove(module);
                                }
                              });
                            },
                    );
                  }),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (_loading) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],
                  if (_loadError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.errorContainer.withValues(alpha: 0.4),
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
                    'WhatsApp group daily reminder',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get a daily notification to open the app and copy an '
                    'AI-style message for your WhatsApp group (built from your sales data).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable daily group-post reminder'),
                    subtitle: const Text(
                      'Same time every day — open Assistant → Daily group post.',
                    ),
                    value: _groupPostEnabled,
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _groupPostEnabled = v),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reminder time'),
                    subtitle: Text(_groupPostTime.format(context)),
                    trailing: const Icon(Icons.schedule),
                    onTap: _groupPostEnabled && !_loading
                        ? () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _groupPostTime,
                            );
                            if (picked == null) return;
                            setState(() => _groupPostTime = picked);
                          }
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _groupInviteUrlCtrl,
                    enabled: !_loading,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp group invite link (optional)',
                      hintText: 'https://chat.whatsapp.com/...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Sales Reminder',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable daily reminder'),
                    subtitle: const Text(
                      'Notify me if no sales are recorded today.',
                    ),
                    value: _enabled,
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _enabled = v),
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
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Settings saved')),
                            );
                            final destination =
                                _selectedRole == UserRole.customer
                                ? const CustomerHomeScreen()
                                : const MainNavScreen();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => destination),
                              (route) => false,
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
