import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_button.dart';
import '../services/cart_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/mail_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Cart items will be sourced from backend when a persisted cart exists.
  final List<Map<String, dynamic>> _cartItems = [];
  bool _loading = false;
  String? _vendorImageUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _handleCheckout() async {
    if (_cartItems.isEmpty) {
      setState(() => _errorMessage = 'Your cart is empty. Please add items before checking out.');
      return;
    }
    
    String? vendorId = _cartItems.first['vendorId'] as String? ?? _cartItems.first['vendor']?['id'] as String?;
    if (vendorId == null || vendorId.isEmpty) {
      for (final it in _cartItems) {
        final found = it['vendorId'] as String? ?? (it['vendor'] is Map ? (it['vendor']['id'] as String?) : null);
        if (found != null && found.isNotEmpty) {
          for (final migrate in _cartItems) {
            migrate['vendorId'] = migrate['vendorId'] ?? (migrate['vendor'] is Map ? migrate['vendor']['id'] : null);
          }
          await CartService.saveCart(_cartItems);
          vendorId = found;
          break;
        }
      }
      if (vendorId == null || vendorId.isEmpty) {
        setState(() => _errorMessage = 'Kitchen information is missing. Please add items again to continue.');
        return;
      }
    }
    
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    
    try {
      final items = _cartItems
          .map((i) {
            final itemId = i['id']?.toString().trim() ?? '';
            final quantity = i['quantity'] is int
                ? i['quantity'] as int
                : int.tryParse(i['quantity']?.toString() ?? '') ?? 0;
            if (itemId.isEmpty || quantity <= 0) return null;
            return {
              'menuItemId': itemId,
              'quantity': quantity,
              'name': i['name']?.toString() ?? 'Menu item',
              'price': double.tryParse(i['price']?.toString() ?? '') ?? 0.0,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      if (items.isEmpty) {
        setState(() {
          _errorMessage = 'Your cart contains no valid items. Please review and add items again.';
          _loading = false;
        });
        return;
      }

      final profile = await AuthService.getProfile();
      final address = profile?['address'];
      String street = 'User delivery address';
      if (address is String) {
        street = address;
      } else if (address is Map) {
        street = address['street'] ?? street;
      }

      final payload = {
        'vendorId': vendorId.trim(),
        'customerId': profile?['id'],
        'items': items,
        'deliveryAddress': {
          'street': street,
          'city': 'Gombe',
          'state': 'Gombe State',
          'country': 'Nigeria',
        },
        'totalAmount': _subtotal + _deliveryFee,
        'deliveryFee': _deliveryFee,
      };

      final order = await ApiService.placeOrder(payload);
      if (!mounted) return;
      
      // Trigger Order Mail
      if (profile?['email'] != null) {
        await MailService.notifyOrderPlaced(
          order['id'].toString(), 
          profile!['email'].toString(),
          'kitchen@plokitch.com', // In real app, vendor email comes from vendor profile
        );
      }

      await CartService.clearCart();
      if (!mounted) return;
      
      setState(() {
        _cartItems.clear();
        _errorMessage = null;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed successfully! Order ID: ${order['id']}')),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/order-history');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyOrderError(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCart() async {
    final items = await CartService.loadCart();
    final vendorImageUrl = items.isNotEmpty
        ? (items.first['vendorImageUrl'] as String?) ?? (items.first['image'] as String?)
        : null;
    setState(() {
      _cartItems.addAll(items);
      _vendorImageUrl = vendorImageUrl;
    });
  }

  double get _subtotal {
    return _cartItems.fold(0.0, (sum, item) {
      final price = (item['price'] is num) ? (item['price'] as num).toDouble() : double.tryParse(item['price'].toString()) ?? 0.0;
      final quantity = item['quantity'] is int ? item['quantity'] as int : int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      return sum + price * quantity;
    });
  }
  
  final int _deliveryFee = 800;

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQuantity = _cartItems[index]['quantity'] + delta;
      if (newQuantity > 0) {
        _cartItems[index]['quantity'] = newQuantity;
        CartService.saveCart(_cartItems);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
      CartService.saveCart(_cartItems);
    });
  }

  String _friendlyOrderError(Object error) {
    final message = error.toString().toLowerCase();
    
    if (message.contains('internal server error') || message.contains('server_error') || message.contains('500')) {
      return 'Our kitchen team is experiencing technical difficulties. Please try again in a moment.';
    }
    if (message.contains('authentication') || message.contains('unauthorized') || message.contains('401')) {
      return 'Your session expired. Please sign in again to place your order.';
    }
    if (message.contains('not found') || message.contains('404')) {
      return 'One of your items is no longer available. Please review your cart and try again.';
    }
    if (message.contains('invalid') || message.contains('validation')) {
      return 'Some order details are incomplete. Please review and try again.';
    }
    if (message.contains('network') || message.contains('socket') || message.contains('connection')) {
      return 'Network connection lost. Please check your internet and try again.';
    }
    if (message.contains('timeout')) {
      return 'The request took too long. Please check your connection and try again.';
    }
    return 'Unable to place your order at this time. Please try again in a few moments.';
  }

  Widget _buildErrorCard(ColorScheme colorScheme, TextTheme textTheme, String message) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
            ),
          ),
          if (_errorMessage != null)
            GestureDetector(
              onTap: () => setState(() => _errorMessage = null),
              child: Icon(Icons.close, color: colorScheme.onErrorContainer, size: 20),
            ),
        ],
      ),
    );
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
        avatarUrl: _vendorImageUrl,
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Text('Your cart is empty', style: textTheme.headlineMedium),
            )
          : Column(
              children: [
                // Fixed Error Card at Top
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildErrorCard(colorScheme, textTheme, _errorMessage!),
                  ),
                
                // Scrollable Cart Content
                Expanded(
                  child: Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.only(bottom: 220),
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
                              'Recommended Add-ons',
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
                            color: Color(0xFF35301D),
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
                                _buildReceiptRow('Subtotal', '₦$_subtotal', textTheme),
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
                                  text: _loading ? 'Processing...' : 'Proceed to Payment',
                                  onPressed: _loading
                                      ? null
                                      : () {
                                          _handleCheckout();
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
