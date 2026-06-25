class ApiExpense {
  const ApiExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.expenseDate,
    this.description,
  });

  final int id;
  final String title;
  final double amount;
  final DateTime expenseDate;
  final String? description;

  factory ApiExpense.fromJson(Map<String, dynamic> json) {
    return ApiExpense(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      amount: _toDouble(json['amount']),
      expenseDate: DateTime.tryParse(
            json['expense_date'] as String? ?? '',
          ) ??
          DateTime.now(),
      description: json['description'] as String?,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
