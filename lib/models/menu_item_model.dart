class MenuItemModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final List<String> images;
  final bool isAddOn;

  MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.images = const [],
    this.isAddOn = false,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    final List<String> images = [];
    if (json['images'] != null) {
      images.addAll(List<String>.from(json['images']));
    }

    return MenuItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] is String) ? double.parse(json['price']) : (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] ?? json['image_url'] as String?,
      images: images,
      isAddOn: json['isAddOn'] == true || json['is_add_on'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'images': images,
        'isAddOn': isAddOn,
      };
}
