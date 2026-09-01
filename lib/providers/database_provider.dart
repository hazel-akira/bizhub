import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'business_api_provider.dart';

AppDatabase? _localDatabase;

/// Local Drift database — only available when not signed in to the cloud API.
final databaseProvider = Provider<AppDatabase>((ref) {
  if (ref.watch(useCloudDataProvider)) {
    throw UnsupportedError(
      'Local SQLite is disabled while signed in to the cloud.',
    );
  }
  return _localDatabase ??= AppDatabase();
});
