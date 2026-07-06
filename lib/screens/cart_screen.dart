import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_button.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Sample data
  final List<Map<String, dynamic>> _cartItems = [
    {
      'id': '1',
      'name': 'Jollof Rice Feast',
      'description': 'With grilled chicken & plantain',
      'price': 4500,
      'quantity': 2,
      'image': 'https://images.unsplash.com/photo-1574484284002-952d92456975?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': '2',
      'name': 'Suya Platter',
      'description': 'Spicy grilled beef with onions',
      'price': 7200,
      'quantity': 1,
      'image': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': '3',
      'name': 'Masa Delight',
      'description': 'Traditional rice cakes with honey',
      'price': 2800,
      'quantity': 3,
      'image': 'https://images.unsplash.com/photo-1604328698692-f76ea9498e76?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    },
  ];

  int get _subtotal {
    return _cartItems.fold(0, (sum, item) => sum + ((item['price'] as int) * (item['quantity'] as int)));
  }
  
  final int _deliveryFee = 800;

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQuantity = _cartItems[index]['quantity'] + delta;
      if (newQuantity > 0) {
        _cartItems[index]['quantity'] = newQuantity;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: PlokitchAppBar(
        title: 'Cart',
        showMenu: false,
        showAvatar: true,
        avatarUrl: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Text('Your cart is empty', style: textTheme.headlineMedium),
            )
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 220), // Space for checkout sheet
                  children: [
                    const SizedBox(height: 16),
                    ..._cartItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildCartItem(context, index, item, colorScheme, textTheme);
                    }),
                    
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Add More?',
                        style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecommendations(colorScheme, textTheme),
                  ],
                ),
                
                // Checkout Bottom Sheet
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF35301D), // inverseSurface
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildReceiptRow('Subtotal', '₦${_subtotal}', textTheme),
                          const SizedBox(height: 8),
                          _buildReceiptRow('Delivery', '₦$_deliveryFee', textTheme),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: textTheme.headlineMedium?.copyWith(color: Colors.white)),
                              Text('₦${_subtotal + _deliveryFee}', style: textTheme.headlineMedium?.copyWith(color: colorScheme.primaryContainer)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          PlokitchButton(
                            text: 'Proceed to Payment',
                            onPressed: () {
                              Navigator.pushNamed(context, '/payment');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItem(BuildContext context, int index, Map<String, dynamic> item, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF642714), // warmBrown
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(item['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'],
                        style: textTheme.titleMedium?.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeItem(index),
                      child: Icon(Icons.close, color: colorScheme.errorContainer, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'],
                  style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₦${item['price']}',
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.primaryContainer),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                            onPressed: () => _updateQuantity(index, -1),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          Text(
                            '${item['quantity']}',
                            style: textTheme.titleSmall?.copyWith(color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white, size: 16),
                            onPressed: () => _updateQuantity(index, 1),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(ColorScheme colorScheme, TextTheme textTheme) {
    final recommendations = [
      {'name': 'Zobo Drink', 'price': 800, 'image': 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80'},
      {'name': 'Plantain', 'price': 1200, 'image': 'https://images.unsplash.com/photo-1604328698692-f76ea9498e76?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80'}, // fallback image
      {'name': 'Extra Beef', 'price': 1500, 'image': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80'},
    ];

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    image: DecorationImage(
                      image: NetworkImage(rec['image'] as String),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec['name'] as String,
                        style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₦${rec['price']}', style: textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                          Icon(Icons.add_circle, color: colorScheme.primaryContainer, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyLarge?.copyWith(color: Colors.white70)),
        Text(value, style: textTheme.titleMedium?.copyWith(color: Colors.white)),
      ],
    );
  }
}
