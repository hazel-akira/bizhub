import '../models/api_sale.dart';
import 'business_api_service.dart';

class CloudBusinessAssistantService {
  CloudBusinessAssistantService(this._api);

  final BusinessApiService _api;

  Future<String> answer(String input) async {
    final q = input.trim().toLowerCase();
    if (q.isEmpty) {
      return 'Ask me about sales, profit, or debts, and I will break it down clearly.';
    }

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
      'money today',
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
      'this week best',
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
    final dash = await _api.getDashboard();
    if (dash.salesCount == 0) {
      return 'No sales recorded today yet.\n\nTip: Start with a quick sale and I will summarize performance here.';
    }

    return 'Here is your today snapshot:\n'
        '• Units sold: ${dash.todayUnitsSold}\n'
        '• Revenue: ${_kes(dash.todaySales)}\n'
        '• Expenses: ${_kes(dash.todayExpenses)}\n'
        '• Net profit: ${_kes(dash.todayProfit)}\n\n'
        '${dash.todayProfit >= 0 ? 'Nice work - you are in profit today.' : 'You are currently in a loss position today.'}';
  }

  Future<String> _profitToday() async {
    final dash = await _api.getDashboard();
    if (dash.salesCount == 0) {
      return 'No sales recorded today yet, so profit is 0 for now.';
    }
    if (dash.todayProfit >= 0) {
      return 'Good news: today you are up ${_kes(dash.todayProfit)}.';
    }
    return 'Heads up: today you are down ${_kes(dash.todayProfit.abs())}.';
  }

  Future<String> _revenueToday() async {
    final dash = await _api.getDashboard();
    if (dash.salesCount == 0) return 'No paid sales yet, so revenue is 0.';
    return 'Today\'s revenue is ${_kes(dash.todaySales)}.';
  }

  Future<String> _samosasSoldToday() async {
    final dash = await _api.getDashboard();
    if (dash.todayUnitsSold == 0) {
      return 'No sales recorded today yet.';
    }
    return 'You have sold ${dash.todayUnitsSold} units today.';
  }

  Future<String> _unpaidTotal() async {
    final dash = await _api.getDashboard();
    if (dash.pendingCredit <= 0) {
      return 'Great - there is no unpaid balance right now.';
    }
    return 'Total unpaid balance is ${_kes(dash.pendingCredit)}.';
  }

  Future<String> _whoOwes() async {
    final unpaid = await _api.getUnpaidSales();
    if (unpaid.isEmpty) {
      return 'No unpaid customers right now. All accounts are clear.';
    }

    final byCustomer = <String, double>{};
    for (final sale in unpaid) {
      final name = sale.customerName ?? 'Customer ${sale.customerId}';
      byCustomer[name] = (byCustomer[name] ?? 0) + sale.outstanding;
    }

    final entries = byCustomer.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).map((e) => '• ${e.key}: ${_kes(e.value)}');
    return 'Customers with unpaid balances:\n${top.join('\n')}';
  }

  Future<String> _bestSellingThisWeek() async {
    final sales = await _api.getSales();
    final weekSales = _salesThisWeek(sales);
    if (weekSales.isEmpty) return 'No sales this week yet.';

    final counts = <String, int>{};
    for (final sale in weekSales) {
      for (final item in sale.items) {
        counts[item.productName] =
            (counts[item.productName] ?? 0) + item.quantity;
      }
    }

    if (counts.isEmpty) return 'No product sales this week yet.';
    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return 'Best selling item this week: ${best.key} (${best.value} sold).';
  }

  List<ApiSale> _salesThisWeek(List<ApiSale> sales) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(start.year, start.month, start.day);

    return sales.where((s) {
      return !s.saleDate.isBefore(weekStart);
    }).toList();
  }

  String _kes(double value) => 'KES ${value.toStringAsFixed(0)}';
}
