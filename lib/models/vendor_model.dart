class VendorModel {
  final String id;
  final String businessName;
  final String? description;
  final Map<String, dynamic>? location;
  final String? imageUrl;

  VendorModel({required this.id, required this.businessName, this.description, this.location, this.imageUrl});

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as String,
      businessName: json['businessName'] ?? json['business_name'] ?? '',
      description: json['description'] as String?,
      location: json['location'] != null ? Map<String, dynamic>.from(json['location'] as Map) : null,
      imageUrl: json['imageUrl'] ?? json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessName': businessName,
        'description': description,
        'location': location,
        'imageUrl': imageUrl,
      };
}
