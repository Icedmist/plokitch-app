import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';

class KitchenManagementScreen extends StatefulWidget {
  const KitchenManagementScreen({super.key});

  @override
  State<KitchenManagementScreen> createState() => _KitchenManagementScreenState();
}

class _KitchenManagementScreenState extends State<KitchenManagementScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pingController;
  List<MenuItemModel> _menuItems = [];
  bool _loading = true;
  String? _error;
  String? _vendorId;
  Map<String, dynamic>? _vendorData;
  List<OrderModel> _activeOrders = [];

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadKitchenData();
  }

  Future<void> _loadKitchenData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await AuthService.getProfile();
      _vendorId = profile?['vendorId'] ?? profile?['vendor_id'] ?? profile?['id'];
      
      if (_vendorId != null) {
        final fetchedVendor = await ApiService.fetchVendor(_vendorId!);
        final menu = await ApiService.fetchVendorMenu(_vendorId!);
        final orders = await ApiService.fetchOrders(vendorId: _vendorId!);
        if (mounted) {
          setState(() {
            _vendorData = fetchedVendor;
            _menuItems = menu.cast<MenuItemModel>();
            _activeOrders = orders.where((o) => !['delivered', 'cancelled', 'completed'].contains(o.status.toLowerCase())).toList();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _pingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading && _vendorData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: PlokitchAppBar(
        title: 'Kitchen Mgmt',
        showMenu: true,
        showAvatar: true,
        avatarUrl: _vendorData?['imageUrl'] as String? ?? _vendorData?['image_url'] as String?,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        children: [
          // Broadcast Message Section
          if (_vendorData?['broadcastMessage'] != null && (_vendorData?['broadcastMessage'] as String).isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black87,
              child: Row(
                children: [
                  Icon(Icons.campaign, color: colorScheme.primaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _vendorData?['broadcastMessage'] as String? ?? '',
                      style: textTheme.bodySmall?.copyWith(color: Colors.white, letterSpacing: 0.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kitchen Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kitchen Status', style: textTheme.headlineMedium?.copyWith(color: Colors.white)),
                          Text('Visible to customers', style: textTheme.bodySmall?.copyWith(color: const Color(0xFFFFB59F))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF74331F), // on-secondary-fixed-variant approx
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                FadeTransition(
                                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_pingController),
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 1.0, end: 2.5).animate(_pingController),
                                    child: Container(
                                      width: 12, height: 12,
                                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 12, height: 12,
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text('ONLINE', style: textTheme.labelLarge?.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Current Menu Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Menu', style: textTheme.headlineMedium?.copyWith(color: colorScheme.secondary)),
                    GestureDetector(
                      onTap: () {}, // Add functionality later
                      child: Text('Add Dish', style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary, 
                        decoration: TextDecoration.underline,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Menu List
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(child: Text('Error: $_error'))
                else if (_menuItems.isEmpty)
                  const Center(child: Text('No menu items found'))
                else
                  ..._menuItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildMenuItem(index, item, colorScheme, textTheme);
                  }),
                
                const SizedBox(height: 24),
                // Kitchen Tasks Prompt
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/chef-dashboard');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.restaurant_menu, color: colorScheme.onPrimaryContainer),
                            const SizedBox(width: 12),
                            Text('Active Orders (${_activeOrders.length})', style: textTheme.headlineMedium?.copyWith(color: colorScheme.onPrimaryContainer)),
                          ],
                        ),
                        Icon(Icons.chevron_right, color: colorScheme.onPrimaryContainer),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, MenuItemModel item, ColorScheme colorScheme, TextTheme textTheme) {
    // Backend doesn't have 'available' field in model yet, assuming true for now
    const isAvailable = true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF642714),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: item.imageUrl != null ? DecorationImage(
                image: NetworkImage(item.imageUrl!),
                fit: BoxFit.cover,
              ) : null,
              color: Colors.grey,
            ),
            child: item.imageUrl == null ? const Icon(Icons.fastfood, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: textTheme.bodyLarge?.copyWith(color: Colors.white)),
                Text('₦${item.price.toStringAsFixed(2)}', style: textTheme.bodySmall?.copyWith(color: const Color(0xFFFDDCCC))),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (value) {
              // Status update not implemented yet
            },
          ),
        ],
      ),
    );
  }
}
