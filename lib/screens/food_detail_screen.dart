import 'package:flutter/material.dart';
import '../services/cart_service.dart';

class FoodDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? foodItem;
  final String role;

  const FoodDetailScreen({super.key, this.foodItem, this.role = 'foodie'});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  bool _addingToCart = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final itemRaw = widget.foodItem ?? args?['foodItem'] as Map<String, dynamic>?;
    final kitchenName = args?['kitchen'] as String? ?? 'Unknown Kitchen';
    final vendorId = args?['vendorId'] as String? ?? itemRaw?['vendorId'] as String?;

    if (itemRaw == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(child: Text('Food item not found')),
      );
    }

    final name = itemRaw['name'] as String? ?? 'Unknown Food';
    final priceNum = itemRaw['price'] is String ? double.tryParse(itemRaw['price']) : (itemRaw['price'] as num?)?.toDouble();
    final price = '₦${(priceNum ?? 0).toStringAsFixed(2)}';
    final imageUrl = itemRaw['imageUrl'] ?? itemRaw['image_url'] ?? '';
    final description = itemRaw['description'] as String? ?? 'No description available.';
    final category = itemRaw['category'] as String? ?? 'Food';
    final location = itemRaw['location'] as String? ?? 'Gombe';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 240,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Icon(Icons.broken_image, size: 64),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(kitchenName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          const Text('Kitchen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(kitchenName, style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(location),
              trailing: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/kitchen-profile', arguments: {'id': vendorId ?? '', 'name': kitchenName}),
                child: const Text('View Profile'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('More Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.food_bank, 'Category', category),
          _buildDetailRow(Icons.location_on, 'Location', location),
          _buildDetailRow(Icons.timer, 'Preparation', '10 - 25 mins'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: Text(_addingToCart ? 'Adding…' : 'Add to Cart'),
            onPressed: _addingToCart
                ? null
                : () async {
                    if (vendorId == null || vendorId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kitchen information is missing.')));
                      return;
                    }
                    setState(() => _addingToCart = true);
                    await _addToCart(
                      itemRaw,
                      vendorId,
                      kitchenName,
                      imageUrl,
                      description,
                      priceNum ?? 0,
                    );
                    if (mounted) setState(() => _addingToCart = false);
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _addToCart(
    Map<String, dynamic> itemRaw,
    String vendorId,
    String kitchenName,
    String imageUrl,
    String description,
    double price,
  ) async {
    final cart = await CartService.loadCart();
    if (cart.isNotEmpty && cart.first['vendorId'] != vendorId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Your cart already contains items from another kitchen. Please checkout first.'),
      ));
      return;
    }

    final itemId = itemRaw['id']?.toString() ?? '';
    final existingIndex = cart.indexWhere((item) => item['id'] == itemId && item['vendorId'] == vendorId);
    if (existingIndex >= 0) {
      cart[existingIndex]['quantity'] = (cart[existingIndex]['quantity'] as int? ?? 1) + 1;
    } else {
      cart.add({
        'id': itemId,
        'name': itemRaw['name']?.toString() ?? 'Food item',
        'description': description,
        'image': imageUrl,
        'price': price,
        'quantity': 1,
        'vendorId': vendorId,
        'vendorName': kitchenName,
      });
    }

    await CartService.saveCart(cart);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added to cart.')));
    Navigator.pushNamed(context, '/cart');
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
