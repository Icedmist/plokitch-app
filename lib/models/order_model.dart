class OrderModel {
  final String id;
  final String? customerId;
  final String? customerName;
  final String? vendorId;
  final String? vendorName;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String? deliveryFee;
  final String status;
  final Map<String, dynamic>? deliveryAddress;
  final String? riderId;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  // Solvix Go delivery integration
  final String? solvixDeliveryId;
  final String? solvixStatus;
  final String? solvixRiderName;

  OrderModel({
    required this.id,
    this.customerId,
    this.customerName,
    this.vendorId,
    this.vendorName,
    required this.items,
    required this.totalAmount,
    this.deliveryFee,
    required this.status,
    this.deliveryAddress,
    this.riderId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.solvixDeliveryId,
    this.solvixStatus,
    this.solvixRiderName,
  });

  static String? _extractString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      if (value.containsKey('businessName')) return value['businessName'] as String?;
      if (value.containsKey('business_name')) return value['business_name'] as String?;
      if (value.containsKey('name')) return value['name'] as String?;
    }
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
      deliveryFee: _extractString(json['deliveryFee'] ?? json['delivery_fee']),
      status: _extractString(json['status']) ?? 'pending',
      deliveryAddress: json['deliveryAddress'] is Map
          ? Map<String, dynamic>.from(json['deliveryAddress'] as Map)
          : null,
      riderId: _extractString(json['riderId'] ?? json['rider_id']),
      notes: _extractString(json['notes']),
      createdAt: _extractString(json['createdAt'] ?? json['created_at']),
      updatedAt: _extractString(json['updatedAt'] ?? json['updated_at']),
      solvixDeliveryId: _extractString(json['solvixDeliveryId'] ?? json['solvix_delivery_id']),
      solvixStatus: _extractString(json['solvixStatus'] ?? json['solvix_status']),
      solvixRiderName: _extractString(json['solvixRiderName'] ?? json['solvix_rider_name']),
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
    String? deliveryFee,
    String? status,
    Map<String, dynamic>? deliveryAddress,
    String? riderId,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? solvixDeliveryId,
    String? solvixStatus,
    String? solvixRiderName,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      riderId: riderId ?? this.riderId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      solvixDeliveryId: solvixDeliveryId ?? this.solvixDeliveryId,
      solvixStatus: solvixStatus ?? this.solvixStatus,
      solvixRiderName: solvixRiderName ?? this.solvixRiderName,
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
        'deliveryFee': deliveryFee,
        'status': status,
        'deliveryAddress': deliveryAddress,
        'riderId': riderId,
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'solvixDeliveryId': solvixDeliveryId,
        'solvixStatus': solvixStatus,
        'solvixRiderName': solvixRiderName,
      };
}
