class VendorModel {
  final String id;
  final String businessName;
  final String? description;
  final Map<String, dynamic>? location;
  final String? imageUrl;
  final String? email;
  final String? phone;
  final String? userId;

  VendorModel({
    required this.id,
    required this.businessName,
    this.description,
    this.location,
    this.imageUrl,
    this.email,
    this.phone,
    this.userId,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : null;
    return VendorModel(
      id: json['id'] as String,
      businessName: json['businessName'] ?? json['business_name'] ?? '',
      description: json['description'] as String?,
      location: json['location'] != null ? Map<String, dynamic>.from(json['location'] as Map) : null,
      imageUrl: json['imageUrl'] ?? json['image_url'] as String?,
      email: (userMap?['email'] ?? json['email']) as String?,
      phone: (userMap?['phone'] ?? json['phone']) as String?,
      userId: userMap?['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessName': businessName,
        'description': description,
        'location': location,
        'imageUrl': imageUrl,
        'email': email,
        'phone': phone,
        'userId': userId,
      };

  String? get openTime => location?['openTime'] as String?;
  String? get closeTime => location?['closeTime'] as String?;

  bool get isOpenNow {
    final open = openTime;
    final close = closeTime;
    if (open == null || close == null) return false;

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    final openParts = open.split(':');
    final closeParts = close.split(':');
    if (openParts.length != 2 || closeParts.length != 2) return false;

    final openMinutes = int.tryParse(openParts[0])! * 60 + int.tryParse(openParts[1])!;
    final closeMinutes = int.tryParse(closeParts[0])! * 60 + int.tryParse(closeParts[1])!;

    if (closeMinutes < openMinutes) {
      return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
    }
    return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
  }
}
