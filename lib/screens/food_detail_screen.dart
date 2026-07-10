import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_toast.dart';

class FoodDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? foodItem;
  final String role;

  const FoodDetailScreen({super.key, this.foodItem, this.role = 'foodie'});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  bool _addingToCart = false;
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final itemRaw = widget.foodItem ?? args?['foodItem'] as Map<String, dynamic>?;
    final kitchenName = args?['kitchen'] as String? ?? itemRaw?['kitchen'] as String? ?? 'Unknown Kitchen';
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

    final allImages = <String>[];
    if (itemRaw['imageUrls'] is List) {
      allImages.addAll(List<String>.from(itemRaw['imageUrls']));
    } else if (itemRaw['image_urls'] is List) {
      allImages.addAll(List<String>.from(itemRaw['image_urls']));
    } else if (itemRaw['images'] is List) {
      allImages.addAll(List<String>.from(itemRaw['images']));
    }
    if (allImages.isEmpty && imageUrl.isNotEmpty) {
      allImages.add(imageUrl);
    }

    return Scaffold(
      appBar: PlokitchAppBar(
        title: name,
        showMenu: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (allImages.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 240,
                child: allImages.length == 1
                    ? Image.network(
                        allImages.first,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 240,
                          width: double.infinity,
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          child: const Icon(Icons.broken_image, size: 64),
                        ),
                      )
                    : PageView.builder(
                        itemCount: allImages.length,
                        onPageChanged: (i) => setState(() => _currentImageIndex = i),
                        itemBuilder: (_, i) => Image.network(
                          allImages[i],
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 240,
                            width: double.infinity,
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            child: const Icon(Icons.broken_image, size: 64),
                          ),
                        ),
                      ),
              ),
            ),
            if (allImages.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(allImages.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentImageIndex == i ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == i
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
                ),
              ),
          ],
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
                onPressed: () {
                  if (vendorId == null || vendorId.isEmpty) {
                    PlokitchToast.show(context, 'Kitchen information is missing.', isError: true, icon: Icons.error_outline_rounded);
                    return;
                  }
                  Navigator.pushNamed(context, '/kitchen-profile', arguments: {'id': vendorId, 'name': kitchenName});
                },
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
          if (args?['role'] == 'chef') _buildChefControls(itemRaw, colorScheme, textTheme),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: Text(_addingToCart ? 'Adding…' : 'Add to Cart'),
            onPressed: _addingToCart
                ? null
                : () async {
                    if (vendorId == null || vendorId.isEmpty) {
                      PlokitchToast.show(context, 'Kitchen information is missing.', isError: true, icon: Icons.error_outline_rounded);
                      return;
                    }
                    if (itemRaw['vendorId'] == null) {
                      itemRaw['vendorId'] = vendorId;
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
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChefControls(Map<String, dynamic> item, ColorScheme colorScheme, TextTheme textTheme) {
    bool isAddOn = item['isAddOn'] == true || item['is_add_on'] == true;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dish Management', style: textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mark as Add-on'),
              Switch(
                value: isAddOn,
                onChanged: (v) {
                  // logic to update item via API
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add-ons are suggested to customers during checkout to increase your sales.',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
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
      PlokitchToast.show(
        context,
        'Your cart already contains items from another kitchen. Please checkout first.',
        isError: true,
        icon: Icons.error_outline_rounded,
      );
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
        'isAddOn': itemRaw['isAddOn'] == true || itemRaw['is_add_on'] == true,
      });
    }

    await CartService.saveCart(cart);
    if (!mounted) return;
    PlokitchToast.show(
      context,
      'Item added to cart.',
      icon: Icons.shopping_cart_checkout_rounded,
    );
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
