class PendingOrderView {
  const PendingOrderView({
    required this.id,
    required this.customerName,
    required this.ndenguCount,
    required this.meatCount,
    required this.orderDate,
  });

  final int id;
  final String customerName;
  final int ndenguCount;
  final int meatCount;
  final DateTime orderDate;

  factory PendingOrderView.fromJson(Map<String, dynamic> json) {
    return PendingOrderView(
      id: json['id'] as int,
      customerName: json['customer_name'] as String? ?? 'Unknown',
      ndenguCount: json['ndengu_count'] as int? ?? 0,
      meatCount: json['meat_count'] as int? ?? 0,
      orderDate: DateTime.tryParse(json['order_date'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
