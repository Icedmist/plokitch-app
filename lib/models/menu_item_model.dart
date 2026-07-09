class MenuItemModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAddOn;

  MenuItemModel({required this.id, required this.name, this.description, required this.price, this.imageUrl, this.isAddOn = false});

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] is String) ? double.parse(json['price']) : (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] ?? json['image_url'] as String?,
      isAddOn: json['isAddOn'] == true || json['is_add_on'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'isAddOn': isAddOn,
      };
}
