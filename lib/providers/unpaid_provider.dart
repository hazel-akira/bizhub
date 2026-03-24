import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

final unpaidRecordsProvider = FutureProvider<List<UnpaidRecord>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getUnpaidRecords();
});

final addUnpaidProvider =
    Provider<Future<void> Function(String name, double amount, {String notes})>(
      (ref) {
        final db = ref.watch(databaseProvider);
        return (name, amount, {notes = ''}) async {
          await db.addUnpaidRecord(name, amount, notes: notes);
        };
      },
    );

final markPaidProvider = Provider<Future<void> Function(int id)>((ref) {
  final db = ref.watch(databaseProvider);
  return (id) async => db.markUnpaidAsPaid(id);
});
