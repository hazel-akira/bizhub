import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/assistant_provider.dart';
import '../services/business_profile_service.dart';
import '../services/group_post_reminder_service.dart';

class DailyGroupPostScreen extends ConsumerStatefulWidget {
  const DailyGroupPostScreen({super.key});

  @override
  ConsumerState<DailyGroupPostScreen> createState() => _DailyGroupPostScreenState();
}

class _DailyGroupPostScreenState extends ConsumerState<DailyGroupPostScreen> {
  String _message = '';
  bool _loading = true;
  String? _error;
  String _groupUrl = '';

  @override
  void initState() {
    super.initState();
    _loadGroupUrl();
    _generate();
  }

  Future<void> _loadGroupUrl() async {
    final s = await GroupPostReminderService.instance.getSettings();
    if (!mounted) return;
    setState(() => _groupUrl = s.groupInviteUrl);
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await BusinessProfileService.instance.getProfile();
      final name =
          profile.name.trim().isEmpty ? 'Akira Bites' : profile.name.trim();
      final service = ref.read(businessAssistantServiceProvider);
      final text = await service.generateDailyWhatsappGroupMessage(name);
      if (!mounted) return;
      setState(() {
        _message = text;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _copy() async {
    if (_message.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _message));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard — paste in WhatsApp')),
    );
  }

  Future<void> _share() async {
    if (_message.isEmpty) return;
    await Share.share(_message, subject: 'Daily WhatsApp group post');
  }

  Future<void> _openGroup() async {
    final raw = _groupUrl.trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add your group invite link in Settings → WhatsApp group reminder.',
          ),
        ),
      );
      return;
    }
    var uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      uri = Uri.tryParse('https://$raw');
    }
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily group post'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            tooltip: 'Refresh message',
            onPressed: _loading ? null : _generate,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Augmentative post',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This text is built from your live sales and profit data, '
                    'then formatted for WhatsApp (*bold* works when you paste).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading || _message.isEmpty ? null : _copy,
            icon: const Icon(Icons.copy),
            label: const Text('Copy for WhatsApp'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading || _message.isEmpty ? null : _share,
            icon: const Icon(Icons.share),
            label: const Text('Share…'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openGroup,
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Open WhatsApp group'),
          ),
        ],
      ),
    );
  }
}
