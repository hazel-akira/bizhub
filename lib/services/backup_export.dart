import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Share a CSV backup via the system share sheet.
class BackupExport {
  static String cell(Object? value) {
    final text = '${value ?? ''}';
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  static Future<void> shareCsv({
    required String filename,
    required String csv,
    String subject = 'Akira Flow backup',
  }) async {
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(text: csv, subject: subject),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv', name: filename)],
        subject: subject,
        text: subject,
      ),
    );
  }
}
