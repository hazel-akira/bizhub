import '../database/app_database.dart';

class BusinessAssistantService {
  final AppDatabase db;

  BusinessAssistantService(this.db);

  Future<String> answer(String input) async {
    final q = input.trim().toLowerCase();
    if (q.isEmpty) return 'Ask me about sales, profit, or debts, and I will break it down clearly.';

    if (_matchAny(q, [
      'summary',
      'today performance',
      'today summary',
      'dashboard',
    ])) {
      return _todaySummary();
    }

    if (_matchAny(q, ['profit today', 'today profit', 'am i making profit'])) {
      return _profitToday();
    }

    if (_matchAny(q, [
      'revenue today',
      'today revenue',
      'sales today amount',
      'money today'
    ])) {
      return _revenueToday();
    }

    if (_matchAny(q, ['samosas sold today', 'sold today', 'today quantity'])) {
      return _samosasSoldToday();
    }

    if (_matchAny(q, ['who owes', 'unpaid customers', 'debtors'])) {
      return _whoOwes();
    }

    if (_matchAny(q, ['unpaid total', 'total debt', 'how much owed'])) {
      return _unpaidTotal();
    }

    if (_matchAny(q, [
      'best selling',
      'most sold',
      'top product',
      'this week best'
    ])) {
      return _bestSellingThisWeek();
    }

    return 'I can help with:\n'
        '- today summary\n'
        '- profit today\n'
        '- revenue today\n'
        '- samosas sold today\n'
        '- unpaid total\n'
        '- who owes\n'
        '- best selling this week';
  }

  bool _matchAny(String q, List<String> keys) {
    for (final k in keys) {
      if (q.contains(k)) return true;
    }
    return false;
  }

  Future<String> _todaySummary() async {
    final paidToday = await _paidSalesToday();
    if (paidToday.isEmpty) {
      return 'No sales recorded today yet.\n\nTip: Start with a quick sale and I will summarize performance here.';
    }

    final qty = paidToday.fold<int>(
      0,
      (sum, s) => sum + s.ndenguCount + s.meatCount,
    );
    final revenue = paidToday.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final profitRecord = await db.getProfitRecordForDate(DateTime.now());
    final costs = profitRecord?.totalCosts ?? 0.0;
    final profit = revenue - costs;

    return 'Here is your today snapshot:\n'
        '• Samosas sold: $qty\n'
        '• Revenue: ${_kes(revenue)}\n'
        '• Costs: ${_kes(costs)}\n'
        '• Net profit: ${_kes(profit)}\n\n'
        '${profit >= 0 ? 'Nice work - you are in profit today.' : 'You are currently in a loss position today.'}';
  }

  Future<String> _profitToday() async {
    final paidToday = await _paidSalesToday();
    if (paidToday.isEmpty) return 'No sales recorded today yet, so profit is 0 for now.';
    final revenue = paidToday.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final costs = (await db.getProfitRecordForDate(DateTime.now()))?.totalCosts ?? 0.0;
    final profit = revenue - costs;
    if (profit >= 0) {
      return 'Good news: today you are up ${_kes(profit)}.';
    }
    return 'Heads up: today you are down ${_kes(profit.abs())}.';
  }

  Future<String> _revenueToday() async {
    final paidToday = await _paidSalesToday();
    if (paidToday.isEmpty) return 'No paid sales yet, so revenue is 0.';
    final revenue = paidToday.fold<double>(0, (sum, s) => sum + s.totalAmount);
    return 'Today\'s revenue is ${_kes(revenue)}.';
  }

  Future<String> _samosasSoldToday() async {
    final paidToday = await _paidSalesToday();
    if (paidToday.isEmpty) return 'No paid sales recorded today yet.';
    final qty = paidToday.fold<int>(
      0,
      (sum, s) => sum + s.ndenguCount + s.meatCount,
    );
    return 'You have sold $qty samosas today.';
  }

  Future<String> _unpaidTotal() async {
    final debtByCustomer = await _unpaidByCustomer();
    final total = debtByCustomer.values.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0) return 'Great - there is no unpaid balance right now.';
    return 'Total unpaid balance is ${_kes(total)}.';
  }

  Future<String> _whoOwes() async {
    final debtByCustomer = await _unpaidByCustomer();
    if (debtByCustomer.isEmpty) return 'No unpaid customers right now. All accounts are clear.';
    final entries = debtByCustomer.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).map(
          (e) => '• ${e.key}: ${_kes(e.value)}',
        );
    return 'Customers with unpaid balances:\n${top.join('\n')}';
  }

  Future<String> _bestSellingThisWeek() async {
    final sales = await db.getSalesForWeek(DateTime.now());
    if (sales.isEmpty) return 'No paid sales this week yet.';
    var ndengu = 0;
    var meat = 0;
    for (final s in sales) {
      if (!s.isPaid) continue;
      ndengu += s.ndenguCount;
      meat += s.meatCount;
    }
    final best = ndengu >= meat ? 'Ndengu' : 'Meat';
    return 'Best selling item this week: $best.\n'
        '• Ndengu sold: $ndengu\n'
        '• Meat sold: $meat';
  }

  String _kes(double value) => 'KES ${value.toStringAsFixed(0)}';

  Future<List<Sale>> _paidSalesToday() async {
    final sales = await db.getSalesForDate(DateTime.now());
    return sales.where((s) => s.isPaid).toList();
  }

  Future<Map<String, double>> _unpaidByCustomer() async {
    final sales = await db.getAllSalesListItems();
    final payments = await db.getAllPayments();
    final paidBySaleId = <int, double>{};
    for (final p in payments) {
      paidBySaleId[p.saleId] = (paidBySaleId[p.saleId] ?? 0) + p.amount;
    }
    final byCustomer = <String, double>{};
    for (final item in sales) {
      if (item.sale.isPaid) continue;
      final paid = paidBySaleId[item.sale.id] ?? 0;
      final outstanding = item.sale.totalAmount - paid;
      if (outstanding <= 0) continue;
      byCustomer[item.customerName] =
          (byCustomer[item.customerName] ?? 0) + outstanding;
    }
    return byCustomer;
  }
}

