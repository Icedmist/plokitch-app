class OrderModel {
  final String id;
  final String customerId;
  final String vendorId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;

  OrderModel({required this.id, required this.customerId, required this.vendorId, required this.items, required this.totalAmount, required this.status});

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customerId'] ?? json['customer_id'] as String,
      vendorId: json['vendorId'] ?? json['vendor_id'] as String,
      items: items,
      totalAmount: (json['totalAmount'] is String) ? double.parse(json['totalAmount']) : (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'vendorId': vendorId,
        'items': items,
        'totalAmount': totalAmount,
        'status': status,
      };
}
