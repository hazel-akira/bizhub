import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get ndenguCount => integer().withDefault(const Constant(0))();
  IntColumn get meatCount => integer().withDefault(const Constant(0))();
  RealColumn get totalRevenue => real().withDefault(const Constant(0))();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
}

class UnpaidRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get customerName => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().named('notes').withDefault(const Constant(''))();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
}

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  IntColumn get ndenguCount => integer().withDefault(const Constant(0))();
  IntColumn get meatCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get orderDate => dateTime()();
  BoolColumn get isFulfilled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get fulfilledDate =>
      dateTime().named('fulfilled_date').nullable()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Sales, Expenses, UnpaidRecords, Customers, Orders])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(driftDatabase(
          name: 'samosa_tracker',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(unpaidRecords);
          }
          if (from < 3) {
            await migrator.createTable(customers);
            await migrator.createTable(orders);
          }
        },
      );

  Future<List<Sale>> getSalesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(sales)
          ..where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end)))
        .get();
  }

  Future<List<Expense>> getExpensesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(expenses)
          ..where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end)))
        .get();
  }

  Future<List<Sale>> getAllSales() async {
    return (select(sales)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  Future<List<Expense>> getAllExpenses() async {
    return (select(expenses)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  Future<List<Sale>> getSalesForWeek(DateTime date) async {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));
    return (select(sales)
          ..where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end)))
        .get();
  }

  Future<List<Expense>> getExpensesForWeek(DateTime date) async {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));
    return (select(expenses)
          ..where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end)))
        .get();
  }

  Future<List<UnpaidRecord>> getUnpaidRecords() async {
    return (select(unpaidRecords)
          ..where((t) => t.isPaid.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<void> markUnpaidAsPaid(int id) async {
    await (update(unpaidRecords)..where((t) => t.id.equals(id)))
        .write(const UnpaidRecordsCompanion(isPaid: Value(true)));
  }

  Future<void> addUnpaidRecord(String customerName, double amount, {String notes = ''}) async {
    await into(unpaidRecords).insert(UnpaidRecordsCompanion.insert(
      customerName: customerName,
      amount: amount,
      date: DateTime.now(),
      notes: Value(notes),
    ));
  }

  Future<List<Customer>> getAllCustomers() async {
    return (select(customers)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<Customer?> getCustomer(int id) async {
    return (select(customers)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> addCustomer(String name, {String phone = ''}) async {
    await into(customers).insert(CustomersCompanion.insert(
      name: name,
      phone: Value(phone),
    ));
  }

  Future<List<Order>> getPendingOrders() async {
    return (select(orders)
          ..where((t) => t.isFulfilled.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.orderDate)]))
        .get();
  }

  Future<List<(Order, String)>> getPendingOrdersWithNames() async {
    final ordersList = await getPendingOrders();
    final result = <(Order, String)>[];
    for (final o in ordersList) {
      final c = await getCustomer(o.customerId);
      result.add((o, c?.name ?? 'Unknown'));
    }
    return result;
  }

  Future<void> createOrder(int customerId, int ndenguCount, int meatCount) async {
    await into(orders).insert(OrdersCompanion.insert(
      customerId: customerId,
      ndenguCount: Value(ndenguCount),
      meatCount: Value(meatCount),
      orderDate: DateTime.now(),
    ));
  }

  Future<void> fulfillOrder(int orderId, bool paid) async {
    final order = await (select(orders)..where((t) => t.id.equals(orderId)))
        .getSingle();
    final customer = await getCustomer(order.customerId);
    final customerName = customer?.name ?? 'Unknown';

    final totalAmount =
        (order.ndenguCount * 30.0) + (order.meatCount * 50.0);

    await (update(orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        isFulfilled: const Value(true),
        fulfilledDate: Value(DateTime.now()),
        isPaid: Value(paid),
      ),
    );

    if (paid) {
      await into(sales).insert(SalesCompanion.insert(
        date: DateTime.now(),
        ndenguCount: Value(order.ndenguCount),
        meatCount: Value(order.meatCount),
        totalRevenue: Value(totalAmount),
      ));
    } else {
      await addUnpaidRecord(
        customerName,
        totalAmount,
        notes: '${order.ndenguCount} ndengu, ${order.meatCount} meat',
      );
    }
  }
}
