import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/business_api_provider.dart';

/// Wraps a screen that only works with local SQLite (offline / not signed in).
class OfflineOnlyGuard extends ConsumerWidget {
  const OfflineOnlyGuard({
    super.key,
    required this.title,
    required this.featureName,
    required this.child,
    this.alternativeHint,
  });

  final String title;
  final String featureName;
  final Widget child;
  final String? alternativeHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(useCloudDataProvider)) {
      return child;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_done, size: 56, color: Colors.green[600]),
              const SizedBox(height: 16),
              Text(
                '$featureName is offline-only',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You are signed in — data is saved to the cloud. '
                'This screen has not been migrated to cloud sync yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              if (alternativeHint != null) ...[
                const SizedBox(height: 12),
                Text(
                  alternativeHint!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
