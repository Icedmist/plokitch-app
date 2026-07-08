class OrderModel {
  final String id;
  final String? customerId;
  final String? customerName;
  final String? vendorId;
  final String? vendorName;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  OrderModel({
    required this.id,
    this.customerId,
    this.customerName,
    this.vendorId,
    this.vendorName,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  static String? _extractString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map && value.containsKey('name')) return value['name'] as String?;
    return value.toString();
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? []).map((e) {
      return Map<String, dynamic>.from(e as Map);
    }).toList();

    return OrderModel(
      id: _extractString(json['id']) ?? '',
      customerId: _extractString(json['customerId'] ?? json['customer_id']),
      customerName: _extractString(json['customer'] ?? json['customerName'] ?? json['customer_name']),
      vendorId: _extractString(json['vendorId'] ?? json['vendor_id']),
      vendorName: _extractString(json['vendor'] ?? json['vendorName'] ?? json['vendor_name']),
      items: items,
      totalAmount: (json['totalAmount'] is String)
          ? double.parse(json['totalAmount'] as String)
          : (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: _extractString(json['status']) ?? 'pending',
      createdAt: _extractString(json['createdAt'] ?? json['created_at']),
      updatedAt: _extractString(json['updatedAt'] ?? json['updated_at']),
    );
  }

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? vendorId,
    String? vendorName,
    List<Map<String, dynamic>>? items,
    double? totalAmount,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'items': items,
        'totalAmount': totalAmount,
        'status': status,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
