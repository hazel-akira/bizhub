import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/mpesa_provider.dart';
import '../services/api_client.dart';

class MpesaSettingsCard extends ConsumerStatefulWidget {
  const MpesaSettingsCard({super.key});

  @override
  ConsumerState<MpesaSettingsCard> createState() => _MpesaSettingsCardState();
}

class _MpesaSettingsCardState extends ConsumerState<MpesaSettingsCard> {
  final _shortcode = TextEditingController();
  final _consumerKey = TextEditingController();
  final _consumerSecret = TextEditingController();
  final _passkey = TextEditingController();
  String _accountType = 'paybill';
  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _shortcode.dispose();
    _consumerKey.dispose();
    _consumerSecret.dispose();
    _passkey.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final api = ref.read(mpesaApiProvider);
    if (api == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save M-Pesa credentials.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await api.saveConfig(
        shortcode: _shortcode.text.trim(),
        accountType: _accountType,
        consumerKey: _consumerKey.text,
        consumerSecret: _consumerSecret.text,
        passkey: _passkey.text,
      );
      _consumerKey.clear();
      _consumerSecret.clear();
      _passkey.clear();
      ref.invalidate(mpesaConfigProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('M-Pesa credentials saved')),
      );
    } on ApiException catch (e) {
      if (mounted) {
        final detail = e.errors?.values.firstOrNull;
        final extra = detail is List && detail.isNotEmpty ? ': ${detail.first}' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.message}$extra')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(mpesaConfigProvider);
    final theme = Theme.of(context);

    ref.listen(mpesaConfigProvider, (previous, next) {
      final config = next.valueOrNull;
      if (config == null || _hydrated) return;
      _hydrated = true;
      _shortcode.text = config.shortcode ?? '';
      if (_accountType != config.accountType) {
        setState(() => _accountType = config.accountType);
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: configAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load M-Pesa settings: $e'),
          data: (config) {
            if (config == null) {
              return Text(
                'Sign in to add Lipa Na M-Pesa Till or Paybill credentials.',
                style: theme.textTheme.bodyMedium,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lipa Na M-Pesa',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Each business uses its own Till or Paybill. Credentials are encrypted on the server. For Daraja sandbox STK, use account type Paybill, shortcode 174379, and the Lipa Na M-Pesa Online passkey — not the C2B/B2C shortcode.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Chip(
                  avatar: Icon(
                    config.configured ? Icons.check_circle : Icons.info_outline,
                    size: 18,
                  ),
                  label: Text(
                    config.configured
                        ? 'Configured (${config.accountTypeLabel ?? config.accountType})'
                        : 'Not configured',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_accountType),
                  initialValue: _accountType,
                  decoration: const InputDecoration(
                    labelText: 'Account type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'paybill', child: Text('Paybill')),
                    DropdownMenuItem(value: 'till', child: Text('Till number')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _accountType = value);
                        },
                ),
                if (_shortcode.text.trim() == '174379') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Sandbox shortcode 174379 requires Paybill (saved automatically).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _shortcode,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Shortcode (Till or Paybill)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (value.trim() == '174379' && _accountType != 'paybill') {
                      setState(() => _accountType = 'paybill');
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _consumerKey,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: 'Consumer key',
                    hintText: config.configured ? '••••••••' : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _consumerSecret,
                  enabled: !_saving,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Consumer secret',
                    hintText: config.configured ? '••••••••' : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passkey,
                  enabled: !_saving,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Passkey',
                    hintText: config.configured ? '••••••••' : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving…' : 'Save M-Pesa credentials'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
