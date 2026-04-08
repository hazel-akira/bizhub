import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../core/constants.dart';
import '../core/phone_utils.dart';

part 'app_database.g.dart';

class SaleListItem {
  final Sale sale;
  final String customerName;

  const SaleListItem({required this.sale, required this.customerName});
}

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id).nullable()();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
  IntColumn get ndenguCount => integer().withDefault(const Constant(0))();
  IntColumn get meatCount => integer().withDefault(const Constant(0))();
  RealColumn get totalAmount =>
      real().named('total_amount').withDefault(const Constant(0))();
  TextColumn get customerName =>
      text().named('customer_name').withDefault(const Constant(''))();
  BoolColumn get isPaid =>
      boolean().named('is_paid').withDefault(const Constant(false))();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get category =>
      text().withDefault(const Constant('daily'))(); // daily / weekly
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
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
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  IntColumn get ndenguCount => integer().withDefault(const Constant(0))();
  IntColumn get meatCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get orderDate => dateTime()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))(); // pending/completed
}

class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  RealColumn get amount => real()();
  TextColumn get method => text()(); // cash / mpesa
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

class ProductionBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get ndenguPrepared =>
      integer().named('ndengu_prepared').withDefault(const Constant(0))();
  IntColumn get meatPrepared =>
      integer().named('meat_prepared').withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

class ProfitRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();

  IntColumn get samosasPrepared =>
      integer().withDefault(const Constant(0))();
  RealColumn get pricePerSamosa =>
      real().named('price_per_samosa').withDefault(const Constant(40))();

  // Daily costs (plus derived "shared" costs derived from weekly/monthly inputs).
  RealColumn get meatCost =>
      real().named('meat_cost').withDefault(const Constant(0))();
  RealColumn get dhaniaCost =>
      real().named('dhania_cost').withDefault(const Constant(0))();

  RealColumn get flourWeeklyCost =>
      real().named('flour_weekly_cost').withDefault(const Constant(0))();
  RealColumn get onionsWeeklyCost =>
      real().named('onions_weekly_cost').withDefault(const Constant(0))();
  RealColumn get oilMonthlyCost =>
      real().named('oil_monthly_cost').withDefault(const Constant(0))();

  RealColumn get gasCost =>
      real().named('gas_cost').withDefault(const Constant(0))();
  RealColumn get transportCost =>
      real().named('transport_cost').withDefault(const Constant(0))();
  RealColumn get labourCost =>
      real().named('labour_cost').withDefault(const Constant(0))();

  RealColumn get revenue =>
      real().named('revenue').withDefault(const Constant(0))();
  RealColumn get totalCosts =>
      real().named('total_costs').withDefault(const Constant(0))();
  RealColumn get profit =>
      real().named('profit').withDefault(const Constant(0))();
}

class ProductionSummary {
  final int ndenguPrepared;
  final int meatPrepared;
  final int ndenguSold;
  final int meatSold;
  final int ndenguRemaining;
  final int meatRemaining;

  const ProductionSummary({
    required this.ndenguPrepared,
    required this.meatPrepared,
    required this.ndenguSold,
    required this.meatSold,
    required this.ndenguRemaining,
    required this.meatRemaining,
  });
}

@DriftDatabase(
  tables: [
    Sales,
    Expenses,
    UnpaidRecords,
    Customers,
    Orders,
    Payments,
    ProductionBatches,
    ProfitRecords,
  ],
)
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
  int get schemaVersion => 7;

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
          if (from < 4) {
            await customStatement(
              "ALTER TABLE sales ADD COLUMN customer_name TEXT NOT NULL DEFAULT ''",
            );
            await customStatement(
              "ALTER TABLE sales ADD COLUMN purchase_details TEXT NOT NULL DEFAULT ''",
            );
            await customStatement(
              "ALTER TABLE sales ADD COLUMN payment_method TEXT NOT NULL DEFAULT ''",
            );
            await customStatement(
              'ALTER TABLE sales ADD COLUMN is_paid INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (from < 5) {
            await migrator.createTable(payments);
            await customStatement(
                "ALTER TABLE customers ADD COLUMN created_at INTEGER NOT NULL DEFAULT 0");
            await customStatement(
                "ALTER TABLE orders ADD COLUMN status TEXT NOT NULL DEFAULT 'pending'");
            await customStatement(
                "ALTER TABLE sales ADD COLUMN order_id INTEGER REFERENCES orders(id)");
            await customStatement(
                "ALTER TABLE sales ADD COLUMN created_at INTEGER NOT NULL DEFAULT 0");
            await customStatement(
                "ALTER TABLE sales ADD COLUMN total_amount REAL NOT NULL DEFAULT 0");
            await customStatement(
                "UPDATE sales SET total_amount = total_revenue WHERE total_amount = 0");
            await customStatement(
                "ALTER TABLE expenses ADD COLUMN category TEXT NOT NULL DEFAULT 'daily'");
            await customStatement(
                "ALTER TABLE expenses ADD COLUMN created_at INTEGER NOT NULL DEFAULT 0");
            await customStatement(
                "UPDATE customers SET created_at = (strftime('%s','now') * 1000) WHERE created_at = 0");
            await customStatement(
                "UPDATE sales SET created_at = (strftime('%s','now') * 1000) WHERE created_at = 0");
            await customStatement(
                "UPDATE expenses SET created_at = (strftime('%s','now') * 1000) WHERE created_at = 0");
          }
          if (from < 6) {
            await migrator.createTable(productionBatches);
          }
          if (from < 7) {
            await migrator.createTable(profitRecords);
          }
        },
      );

  Future<List<Sale>> getSalesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(sales)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(start) & t.createdAt.isSmallerThanValue(end)))
        .get();
  }

  Future<List<Expense>> getExpensesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(expenses)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(start) & t.createdAt.isSmallerThanValue(end)))
        .get();
  }

  Future<List<Sale>> getAllSales() async {
    return (select(sales)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<List<SaleListItem>> getAllSalesListItems() async {
    final query = select(sales).join([
      leftOuterJoin(orders, orders.id.equalsExp(sales.orderId)),
      leftOuterJoin(customers, customers.id.equalsExp(orders.customerId)),
    ])
      ..orderBy([OrderingTerm.desc(sales.createdAt)]);

    final rows = await query.get();
    return rows.map((row) {
      final sale = row.readTable(sales);
      final customer = row.readTableOrNull(customers);
      final name = (customer?.name ?? sale.customerName).trim();
      return SaleListItem(
        sale: sale,
        customerName: name.isEmpty ? 'Walk-in Customer' : name,
      );
    }).toList();
  }

  Future<List<SaleListItem>> getSalesListItemsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final query = select(sales).join([
      leftOuterJoin(orders, orders.id.equalsExp(sales.orderId)),
      leftOuterJoin(customers, customers.id.equalsExp(orders.customerId)),
    ])
      ..where(
        sales.createdAt.isBiggerOrEqualValue(start) &
            sales.createdAt.isSmallerThanValue(end),
      )
      ..orderBy([OrderingTerm.desc(sales.createdAt)]);

    final rows = await query.get();
    return rows.map((row) {
      final sale = row.readTable(sales);
      final customer = row.readTableOrNull(customers);
      final name = (customer?.name ?? sale.customerName).trim();
      return SaleListItem(
        sale: sale,
        customerName: name.isEmpty ? 'Walk-in Customer' : name,
      );
    }).toList();
  }

  Future<int> addSaleEntry({
    required DateTime date,
    required double totalRevenue,
    required String customerName,
    required String purchaseDetails,
    required bool isPaid,
    String paymentMethod = '',
    int ndenguCount = 0,
    int meatCount = 0,
  }) async {
    return into(sales).insert(
      SalesCompanion.insert(
        createdAt: Value(date),
        ndenguCount: Value(ndenguCount),
        meatCount: Value(meatCount),
        totalAmount: Value(totalRevenue),
        customerName: Value(customerName),
        isPaid: Value(isPaid),
      ),
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    return (select(expenses)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<List<Sale>> getSalesForWeek(DateTime date) async {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));
    return (select(sales)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(start) & t.createdAt.isSmallerThanValue(end)))
        .get();
  }

  Future<List<Expense>> getExpensesForWeek(DateTime date) async {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));
    return (select(expenses)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(start) & t.createdAt.isSmallerThanValue(end)))
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

  Future<void> saveProfitRecord({
    required DateTime date,
    required int samosasPrepared,
    required double pricePerSamosa,
    required double meatCost,
    required double dhaniaCost,
    required double flourWeeklyCost,
    required double onionsWeeklyCost,
    required double oilMonthlyCost,
    required double gasCost,
    required double transportCost,
    required double labourCost,
    required double revenue,
    required double totalCosts,
    required double profit,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    await into(profitRecords).insert(
      ProfitRecordsCompanion.insert(
        date: day,
        samosasPrepared: Value(samosasPrepared),
        pricePerSamosa: Value(pricePerSamosa),
        meatCost: Value(meatCost),
        dhaniaCost: Value(dhaniaCost),
        flourWeeklyCost: Value(flourWeeklyCost),
        onionsWeeklyCost: Value(onionsWeeklyCost),
        oilMonthlyCost: Value(oilMonthlyCost),
        gasCost: Value(gasCost),
        transportCost: Value(transportCost),
        labourCost: Value(labourCost),
        revenue: Value(revenue),
        totalCosts: Value(totalCosts),
        profit: Value(profit),
      ),
    );
  }

  Future<List<ProfitRecord>> getAllProfitRecords() async {
    return (select(profitRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<ProfitRecord?> getProfitRecordForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(profitRecords)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<Customer>> getAllCustomers() async {
    return (select(customers)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<Customer?> getCustomer(int id) async {
    return (select(customers)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Returns the existing customer if [phone] (after normalization) already exists.
  /// Otherwise inserts and returns `null`. Empty phone never matches a duplicate.
  Future<Customer?> addCustomer(String name, {String phone = ''}) async {
    final trimmed = phone.trim();
    final normalized = normalizePhoneKey(trimmed);
    if (normalized.isNotEmpty) {
      final existing = await findCustomerByNormalizedPhone(trimmed);
      if (existing != null) {
        return existing;
      }
    }
    final storedPhone = normalized.isNotEmpty ? normalized : trimmed;
    await into(customers).insert(CustomersCompanion.insert(
      name: name,
      phone: Value(storedPhone),
      createdAt: Value(DateTime.now()),
    ));
    return null;
  }

  /// Same digits as [normalizePhoneKey] (e.g. 07… and 254… match).
  Future<Customer?> findCustomerByNormalizedPhone(String phone) async {
    final key = normalizePhoneKey(phone);
    if (key.isEmpty) return null;
    final all = await getAllCustomers();
    for (final c in all) {
      if (normalizePhoneKey(c.phone) == key) return c;
    }
    return null;
  }

  /// Returns another customer if the new phone belongs to someone else; otherwise updates and returns `null`.
  Future<Customer?> updateCustomer(int id, {required String name, String phone = ''}) async {
    final trimmed = phone.trim();
    final normalized = normalizePhoneKey(trimmed);
    if (normalized.isNotEmpty) {
      final existing = await findCustomerByNormalizedPhone(trimmed);
      if (existing != null && existing.id != id) {
        return existing;
      }
    }
    final storedPhone = normalized.isNotEmpty ? normalized : trimmed;
    await (update(customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        name: Value(name),
        phone: Value(storedPhone),
      ),
    );
    return null;
  }

  /// Returns `false` if this customer has any orders (FK safety).
  Future<bool> deleteCustomer(int id) async {
    final related = await (select(orders)..where((t) => t.customerId.equals(id))).get();
    if (related.isNotEmpty) return false;
    await (delete(customers)..where((t) => t.id.equals(id))).go();
    return true;
  }

  Future<List<Order>> getPendingOrders() async {
    return (select(orders)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.orderDate)]))
        .get();
  }

  Future<List<(Order, String)>> getPendingOrdersWithNames() async {
    final query = select(orders).join([
      leftOuterJoin(customers, customers.id.equalsExp(orders.customerId)),
    ])
      ..where(orders.status.equals('pending'))
      ..orderBy([OrderingTerm.desc(orders.orderDate)]);

    final rows = await query.get();
    return rows.map((row) {
      final order = row.readTable(orders);
      final customer = row.readTableOrNull(customers);
      return (order, customer?.name ?? 'Unknown');
    }).toList();
  }

  Future<void> createOrder(int customerId, int ndenguCount, int meatCount) async {
    await into(orders).insert(OrdersCompanion.insert(
      customerId: customerId,
      ndenguCount: Value(ndenguCount),
      meatCount: Value(meatCount),
      orderDate: DateTime.now(),
      status: const Value('pending'),
    ));
  }

  Future<void> fulfillOrder(int orderId) async {
    final order = await (select(orders)..where((t) => t.id.equals(orderId)))
        .getSingle();
    final customer = await getCustomer(order.customerId);
    final customerName = customer?.name ?? 'Unknown';
    final totalAmount =
        (order.ndenguCount * SamosaPrices.ndenguPrice) +
            (order.meatCount * SamosaPrices.meatPrice);

    await (update(orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        status: const Value('completed'),
      ),
    );

    await into(sales).insert(SalesCompanion.insert(
      orderId: Value(order.id),
      createdAt: Value(DateTime.now()),
      ndenguCount: Value(order.ndenguCount),
      meatCount: Value(order.meatCount),
      totalAmount: Value(totalAmount),
      customerName: Value(customerName),
      isPaid: const Value(false),
    ));
  }

  Future<void> addPayment({
    required int saleId,
    required double amount,
    required String method,
  }) async {
    await into(payments).insert(
      PaymentsCompanion.insert(
        saleId: saleId,
        amount: amount,
        method: method,
        createdAt: Value(DateTime.now()),
      ),
    );
    await _refreshSalePaidStatus(saleId);
  }

  Future<List<Payment>> getAllPayments() async {
    return (select(payments)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<double> totalPaymentsForSale(int saleId) async {
    final rows =
        await (select(payments)..where((t) => t.saleId.equals(saleId))).get();
    return rows.fold<double>(0.0, (sum, p) => sum + p.amount);
  }

  Future<void> _refreshSalePaidStatus(int saleId) async {
    final sale =
        await (select(sales)..where((t) => t.id.equals(saleId))).getSingleOrNull();
    if (sale == null) return;
    final paidTotal = await totalPaymentsForSale(saleId);
    await (update(sales)..where((t) => t.id.equals(saleId))).write(
      SalesCompanion(isPaid: Value(paidTotal >= sale.totalAmount)),
    );
  }

  Future<double> getCustomerBalance(int customerId) async {
    final customer = await getCustomer(customerId);
    if (customer == null) return 0;

    final customerName = customer.name;
    final customerOrders =
        await (select(orders)..where((o) => o.customerId.equals(customerId))).get();
    final orderIds = customerOrders.map((e) => e.id).toList();

    // Include both:
    // - Sales linked to Orders via `orderId`
    // - Sales created directly from Customers (verbal/unpaid sales) where `orderId` is null
    //   but `customerName` matches.
    final salesQuery = select(sales);
    if (orderIds.isEmpty) {
      salesQuery.where((s) => s.orderId.isNull() & s.customerName.equals(customerName));
    } else {
      salesQuery.where((s) =>
          s.orderId.isIn(orderIds) |
          (s.orderId.isNull() & s.customerName.equals(customerName)));
    }

    final customerSales = await salesQuery.get();
    if (customerSales.isEmpty) return 0;

    final totalSales =
        customerSales.fold<double>(0, (sum, s) => sum + s.totalAmount);

    final saleIds = customerSales.map((s) => s.id).toSet().toList();
    final paymentRows =
        await (select(payments)..where((p) => p.saleId.isIn(saleIds))).get();
    final totalPayments =
        paymentRows.fold<double>(0, (sum, p) => sum + p.amount);

    return totalSales - totalPayments;
  }

  Future<List<Customer>> getUnpaidCustomers() async {
    final all = await getAllCustomers();
    final result = <Customer>[];
    for (final c in all) {
      final balance = await getCustomerBalance(c.id);
      if (balance > 0) result.add(c);
    }
    return result;
  }

  Future<int> unpaidOrdersCountToday() async {
    final start = DateTime.now();
    final dayStart = DateTime(start.year, start.month, start.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final todays = await (select(orders)
          ..where((o) =>
              o.orderDate.isBiggerOrEqualValue(dayStart) &
              o.orderDate.isSmallerThanValue(dayEnd) &
              o.status.equals('pending')))
        .get();
    return todays.length;
  }

  Future<ProductionBatche?> getBatchForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(productionBatches)
          ..where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  Future<void> saveDailyProduction({
    required DateTime date,
    required int ndenguPreparedQty,
    required int meatPreparedQty,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final existing = await getBatchForDate(day);
    if (existing == null) {
      await into(productionBatches).insert(
        ProductionBatchesCompanion.insert(
          date: day,
          ndenguPrepared: Value(ndenguPreparedQty),
          meatPrepared: Value(meatPreparedQty),
          createdAt: Value(DateTime.now()),
        ),
      );
      return;
    }
    await (update(productionBatches)..where((t) => t.id.equals(existing.id))).write(
      ProductionBatchesCompanion(
        ndenguPrepared: Value(ndenguPreparedQty),
        meatPrepared: Value(meatPreparedQty),
      ),
    );
  }

  Future<ProductionSummary> getProductionSummary(DateTime date) async {
    final batch = await getBatchForDate(date);
    final sales = await getSalesForDate(date);
    final ndenguSold = sales.fold<int>(0, (sum, s) => sum + s.ndenguCount);
    final meatSold = sales.fold<int>(0, (sum, s) => sum + s.meatCount);
    final ndenguPrepared = batch?.ndenguPrepared ?? 0;
    final meatPrepared = batch?.meatPrepared ?? 0;
    return ProductionSummary(
      ndenguPrepared: ndenguPrepared,
      meatPrepared: meatPrepared,
      ndenguSold: ndenguSold,
      meatSold: meatSold,
      ndenguRemaining: ndenguPrepared - ndenguSold,
      meatRemaining: meatPrepared - meatSold,
    );
  }
}
