import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

final todayExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getExpensesForDate(DateTime.now());
});

final allExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllExpenses();
});

final addExpenseProvider = Provider<Future<void> Function(String, double)>((ref) {
  final db = ref.watch(databaseProvider);
  return (name, amount) async {
    await db.into(db.expenses).insert(ExpensesCompanion.insert(
      name: name,
      amount: amount,
      date: DateTime.now(),
    ));
  };
});
