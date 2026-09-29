import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/assistant_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/voice_wake_provider.dart';
import '../widgets/access_denied_page.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantMessage {
  final String text;
  final bool isUser;

  const _AssistantMessage({required this.text, required this.isUser});
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_AssistantMessage> _messages = [
    const _AssistantMessage(
      text:
          'Hi! I am Akira Flow.\n'
          'While the app is open, just say:\n'
          '- Hi Akira Flow, add product A selling 300 buying 250 stock 50\n'
          '- Hi Akira Flow, add a sale of two nails 3 inches\n'
          'Or tap the mic here and speak without the wake phrase.',
      isUser: false,
    ),
  ];
  bool _loading = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _inputCtrl.text).trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add(_AssistantMessage(text: text, isUser: true));
      _loading = true;
    });
    _inputCtrl.clear();
    _scrollToEnd();

    try {
      final reply = await ref.read(askAssistantProvider)(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_AssistantMessage(text: reply.text, isUser: false));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _AssistantMessage(
            text: 'Sorry, I could not process that: $e',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canOpenAssistant) {
      return const AccessDeniedPage(title: 'Assistant');
    }

    final voice = ref.watch(voiceWakeProvider);
    final listening = voice.phase == VoiceWakePhase.listening ||
        voice.phase == VoiceWakePhase.armed;
    final busy = _loading || voice.phase == VoiceWakePhase.processing;

    ref.listen<VoiceWakeState>(voiceWakeProvider, (previous, next) {
      if (next.lastReply == null || next.lastReply == previous?.lastReply) {
        return;
      }
      if (next.phase == VoiceWakePhase.processing) return;
      final said = (previous?.partialHeard ?? '').trim();
      setState(() {
        if (said.isNotEmpty) {
          _messages.add(_AssistantMessage(text: said, isUser: true));
        }
        _messages.add(_AssistantMessage(text: next.lastReply!, isUser: false));
      });
      _scrollToEnd();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickChip('today summary'),
                _quickChip('who owes'),
                _quickChip('best selling this week'),
                _quickChip('add a product'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: listening
                            ? 'Listening...'
                            : 'Hi Akira Flow, add product A selling 300…',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    onPressed: busy
                        ? null
                        : () =>
                              ref.read(voiceWakeProvider.notifier).listenDirect(),
                    tooltip: listening
                        ? 'Listening'
                        : 'Speak without the wake phrase',
                    style: IconButton.styleFrom(
                      foregroundColor: listening ? Colors.red : null,
                    ),
                    icon: Icon(listening ? Icons.mic : Icons.mic_none),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: busy ? null : _send,
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: _loading ? null : () => _send(text),
    );
  }
}
