import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/voice_wake_provider.dart';

class VoiceWakeBar extends ConsumerWidget {
  const VoiceWakeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceWakeProvider);
    if (!state.allowed || !state.enabled) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final (icon, label, color) = switch (state.phase) {
      VoiceWakePhase.processing => (
          Icons.hourglass_top,
          'Working on it…',
          theme.colorScheme.primary,
        ),
      VoiceWakePhase.armed || VoiceWakePhase.listening => (
          Icons.mic,
          state.partialHeard.isEmpty
              ? 'Go ahead — add a product or a sale'
              : state.partialHeard,
          Colors.red.shade700,
        ),
      VoiceWakePhase.sleeping => (
          Icons.graphic_eq,
          state.partialHeard.isNotEmpty
              ? state.partialHeard
              : 'Say “Hi Akira Flow…”',
          theme.colorScheme.primary,
        ),
      _ => (
          Icons.mic_none,
          state.error ?? 'Hands-free voice is off',
          theme.colorScheme.outline,
        ),
    };

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
