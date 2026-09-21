import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/etims_provider.dart';
import '../services/etims_settings_service.dart';

/// Store-owner KRA eTIMS tax compliance settings (matches backend-settings UI).
class EtimsSettingsCard extends ConsumerStatefulWidget {
  const EtimsSettingsCard({super.key});

  @override
  ConsumerState<EtimsSettingsCard> createState() => _EtimsSettingsCardState();
}

class _EtimsSettingsCardState extends ConsumerState<EtimsSettingsCard> {
  final _kraPin = TextEditingController();
  final _deviceToken = TextEditingController();
  bool _hydrated = false;
  bool _saving = false;
  bool _obscureToken = true;

  static const _accentGreen = Color(0xFF2E7D32);

  @override
  void dispose() {
    _kraPin.dispose();
    _deviceToken.dispose();
    super.dispose();
  }

  void _hydrate(EtimsSettings settings) {
    if (_hydrated) return;
    _hydrated = true;
    _kraPin.text = settings.kraPin;
    _deviceToken.text = settings.deviceToken;
  }

  Future<void> _toggle(bool enabled) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(etimsSettingsProvider.notifier).setEnabled(enabled);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Automated eTIMS reporting enabled'
                : 'Automated eTIMS reporting disabled',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not update eTIMS setting: $e')),
      );
    }
  }

  Future<void> _saveCredentials() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(etimsSettingsProvider.notifier).saveCredentials(
            kraPin: _kraPin.text,
            deviceToken: _deviceToken.text,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('eTIMS credentials saved')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save credentials: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final etimsAsync = ref.watch(etimsSettingsProvider);
    final theme = Theme.of(context);

    ref.listen(etimsSettingsProvider, (previous, next) {
      final settings = next.valueOrNull;
      if (settings != null) _hydrate(settings);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: etimsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            'Could not load eTIMS settings: $e',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (settings) {
            if (!_hydrated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _hydrate(settings);
              });
            }
            final enabled = settings.enabled;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KRA eTIMS Tax Compliance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Enable Automated eTIMS Reporting',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _OnOffBadge(enabled: enabled),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Automatically transmit invoices to KRA on '
                            'transaction checkout. All completed sales '
                            'invoices will loop through KRA\'s validation '
                            'server before printing.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch.adaptive(
                      value: enabled,
                      activeThumbColor: Colors.white,
                      activeTrackColor: _accentGreen,
                      onChanged: _toggle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionBox(
                  title: 'API Authentication Configuration',
                  child: Column(
                    children: [
                      TextField(
                        controller: _kraPin,
                        enabled: !_saving,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Trader KRA PIN',
                          hintText: 'A012345678Z',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _deviceToken,
                        enabled: !_saving,
                        obscureText: _obscureToken,
                        decoration: InputDecoration(
                          labelText: 'eTIMS VSCU Device Serial / Token',
                          hintText: 'KRA-VSCU-PROD-********',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: IconButton(
                            tooltip: _obscureToken ? 'Show' : 'Hide',
                            onPressed: () => setState(
                              () => _obscureToken = !_obscureToken,
                            ),
                            icon: Icon(
                              _obscureToken
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _saveCredentials,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? 'Saving…' : 'Save credentials',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionBox(
                  title: 'Server Synchronization Status',
                  child: _SyncStatusRow(
                    connected: enabled && settings.hasCredentials,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnOffBadge extends StatelessWidget {
  const _OnOffBadge({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFF2E7D32) : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        enabled ? 'ON' : 'OFF',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SectionBox extends StatelessWidget {
  const _SectionBox({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SyncStatusRow extends StatelessWidget {
  const _SyncStatusRow({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = connected ? const Color(0xFF2E7D32) : Colors.orange.shade800;
    final label = connected
        ? 'Connected (Sandbox Environment)'
        : 'Waiting for credentials';

    return Row(
      children: [
        Icon(Icons.cell_tower, size: 20, color: color),
        const SizedBox(width: 10),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
