import 'package:flutter/material.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../services/api_service.dart';
import '../models/vendor_model.dart';
import '../models/menu_item_model.dart';

class MarketScreen extends StatefulWidget {
  final String role;

  const MarketScreen({super.key, this.role = 'customer'});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final List<String> _categories = ['All', 'Mains', 'Sides', 'Desserts', 'Drinks'];
  int _selectedCategory = 0;

  bool _loading = true;
  String? _error;
  List<MenuItemModel> _foods = [];
  List<VendorModel> _vendors = [];
  final Map<String, String> _foodIdToVendorName = {};

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fetched = await ApiService.fetchVendors();
      final foods = <MenuItemModel>[];
      final vendorList = fetched is List ? fetched : List.from(fetched as Iterable);
      
      _vendors.clear();
      _foodIdToVendorName.clear();

      for (final v in vendorList) {
        final vm = v as VendorModel;
        _vendors.add(vm);
        try {
          final menuRaw = await ApiService.fetchVendorMenu(vm.id);
          final menuList = menuRaw is List ? menuRaw : List.from(menuRaw as Iterable);
          for (final mi in menuList) {
            final item = mi as MenuItemModel;
            foods.add(item);
            _foodIdToVendorName[item.id] = vm.businessName;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _foods = foods;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<MenuItemModel> get _filteredFoods {
    if (_selectedCategory == 0) return _foods;
    final category = _categories[_selectedCategory];
    return _foods.where((f) => (f.toJson()['category'] as String? ?? '').toLowerCase() == category.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final currentRole = args != null && args['role'] != null ? args['role'] as String : widget.role;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('Marketplace', style: TextStyle(color: colorScheme.onSurface)),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  ),
                  actions: [
                    IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () => Navigator.pushNamed(context, '/cart')),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Explore local flavors', style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline)),
                        const SizedBox(height: 20),
                        _buildCategoryFilter(colorScheme),
                        const SizedBox(height: 24),
                        if (_error != null) Center(child: Text('Error: $_error')) else ...[
                          Text('Featured Kitchens', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildKitchenSection(context),
                          const SizedBox(height: 32),
                          Text('Popular Dishes', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildFoodGridCard(context, _filteredFoods[index], colorScheme, textTheme),
                      childCount: _filteredFoods.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
      bottomNavigationBar: PlokitchBottomNav(
        role: currentRole,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            if (currentRole == 'rider') {
              Navigator.pushReplacementNamed(context, '/rider-dashboard');
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
          if (index == 2) Navigator.pushReplacementNamed(context, '/order-history', arguments: {'role': currentRole});
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildCategoryFilter(ColorScheme colorScheme) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return ChoiceChip(
            label: Text(_categories[index]),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedCategory = index),
            selectedColor: colorScheme.primary,
            labelStyle: TextStyle(color: isSelected ? Colors.white : colorScheme.onSurface),
          );
        },
      ),
    );
  }

  Widget _buildKitchenSection(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _vendors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final vendor = _vendors[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/kitchen-profile', arguments: {'id': vendor.id}),
            child: Container(
              width: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: vendor.imageUrl != null ? DecorationImage(image: NetworkImage(vendor.imageUrl!), fit: BoxFit.cover) : null,
                color: Colors.grey.shade200,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)]),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(vendor.description ?? 'Local Kitchen', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodGridCard(BuildContext context, MenuItemModel food, ColorScheme colorScheme, TextTheme textTheme) {
    final kitchenName = _foodIdToVendorName[food.id] ?? 'Kitchen';
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/food-detail', arguments: {
        'foodItem': food.toJson(),
        'kitchen': kitchenName,
      }),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: food.imageUrl != null 
                  ? Image.network(food.imageUrl!, width: double.infinity, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade300, child: const Icon(Icons.fastfood, size: 40, color: Colors.white)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(kitchenName, style: textTheme.bodySmall?.copyWith(color: colorScheme.primary), maxLines: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₦${food.price.toStringAsFixed(0)}', style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  // Removed duplicate featured kitchen card (kept ListTile version above)
}
