class ApiRepairTicket {
  const ApiRepairTicket({
    required this.id,
    required this.ticketNumber,
    required this.customerName,
    required this.phoneModel,
    required this.issueDescription,
    required this.laborCost,
    required this.status,
    this.customerPhone,
    this.sparePartsUsed,
    this.statusLabel,
    this.createdAt,
  });

  final int id;
  final String ticketNumber;
  final String customerName;
  final String? customerPhone;
  final String phoneModel;
  final String issueDescription;
  final String? sparePartsUsed;
  final double laborCost;
  final String status;
  final String? statusLabel;
  final DateTime? createdAt;

  factory ApiRepairTicket.fromJson(Map<String, dynamic> json) {
    return ApiRepairTicket(
      id: json['id'] as int,
      ticketNumber: json['ticket_number'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String?,
      phoneModel: json['phone_model'] as String? ?? '',
      issueDescription: json['issue_description'] as String? ?? '',
      sparePartsUsed: json['spare_parts_used'] as String?,
      laborCost: _toDouble(json['labor_cost']),
      status: json['status'] as String? ?? 'pending',
      statusLabel: json['status_label'] as String?,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
