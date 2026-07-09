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
        title: 'Manage Kitchen',
        showMenu: true,
        showAvatar: true,
        avatarUrl: _vendorData?['imageUrl'] as String? ?? _vendorData?['image_url'] as String?,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildSimpleStat('Posted Dishes', '${_menuItems.length}', Icons.restaurant_menu, colorScheme, textTheme),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSimpleStat('Active Orders', '${_activeOrders.length}', Icons.shopping_bag, colorScheme, textTheme),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Menu', style: textTheme.headlineMedium?.copyWith(color: colorScheme.secondary)),
              ElevatedButton.icon(
                onPressed: () {}, // Add logic
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Dish'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
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
          
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: PlokitchBottomNav(
        role: 'chef',
        currentIndex: 1, 
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/chef-dashboard');
          if (index == 2) Navigator.pushReplacementNamed(context, '/chef-orders');
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, IconData icon, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF642714),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primaryContainer, size: 24),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: textTheme.headlineLarge?.copyWith(color: Colors.white)),
          ),
          Text(label, style: textTheme.labelSmall?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, MenuItemModel item, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl != null 
              ? Image.network(item.imageUrl!, width: 64, height: 64, fit: BoxFit.cover)
              : Container(width: 64, height: 64, color: Colors.grey.shade300, child: const Icon(Icons.fastfood, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('₦${item.price.toStringAsFixed(0)}', style: textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                if (item.isAddOn)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
                    child: Text('ADD-ON', style: textTheme.labelSmall?.copyWith(color: Colors.orange.shade900, fontSize: 8)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
