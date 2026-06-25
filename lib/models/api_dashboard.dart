class ApiDashboard {
  const ApiDashboard({
    required this.todaySales,
    required this.todayExpenses,
    required this.todayProfit,
    required this.productsCount,
    required this.salesCount,
    this.todayUnitsSold = 0,
    this.topProductToday,
    this.lowStockCount = 0,
  });

  final double todaySales;
  final double todayExpenses;
  final double todayProfit;
  final int productsCount;
  final int salesCount;
  final int todayUnitsSold;
  final String? topProductToday;
  final int lowStockCount;

  factory ApiDashboard.fromJson(Map<String, dynamic> json) {
    return ApiDashboard(
      todaySales: _toDouble(json['today_sales']),
      todayExpenses: _toDouble(json['today_expenses']),
      todayProfit: _toDouble(json['today_profit']),
      productsCount: json['products_count'] as int? ?? 0,
      salesCount: json['sales_count'] as int? ?? 0,
      todayUnitsSold: json['today_units_sold'] as int? ?? 0,
      topProductToday: json['top_product_today'] as String?,
      lowStockCount: json['low_stock_count'] as int? ?? 0,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
