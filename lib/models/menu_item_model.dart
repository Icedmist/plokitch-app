class MenuItemModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? imageUrl;
  final List<String> images;
  final bool isAddOn;
  final bool isAvailable;

  MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imageUrl,
    this.images = const [],
    this.isAddOn = false,
    this.isAvailable = true,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    final List<String> images = [];
    if (json['imageUrls'] != null) {
      images.addAll(List<String>.from(json['imageUrls']));
    } else if (json['image_urls'] != null) {
      images.addAll(List<String>.from(json['image_urls']));
    }

    final bool available = json['isAvailable'] == true || json['available'] == true || json['is_available'] == true;

    return MenuItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] is String) ? double.parse(json['price']) : (json['price'] as num).toDouble(),
      category: json['category'] as String? ?? json['dishCategory'] as String?,
      imageUrl: json['imageUrl'] ?? json['image_url'] as String?,
      images: images,
      isAddOn: json['isAddOn'] == true || json['is_add_on'] == true,
      isAvailable: available,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'images': images,
        'isAddOn': isAddOn,
        'isAvailable': isAvailable,
      };
}
