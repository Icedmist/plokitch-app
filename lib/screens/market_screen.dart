import 'package:flutter/material.dart';
import '../theme/plokitch_theme.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
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
  final List<VendorModel> _vendors = [];
  final Map<String, String> _foodIdToVendorName = {};
  final Map<String, String> _foodIdToVendorId = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVendors();
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    try {
      final cart = await CartService.loadCart();
      int count = 0;
      for (final item in cart) {
        count += item['quantity'] as int? ?? 1;
      }
      if (mounted) {
        setState(() {
          _cartItemCount = count;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fetched = await ApiService.fetchVendors();
      final foods = <MenuItemModel>[];
      final vendorList = fetched.cast<VendorModel>();
      
      _vendors.clear();
      _foodIdToVendorName.clear();
      _foodIdToVendorId.clear();

      for (final vm in vendorList) {
        _vendors.add(vm);
        try {
          final menuList = (await ApiService.fetchVendorMenu(vm.id)).cast<MenuItemModel>();
          for (final item in menuList) {
            foods.add(item);
            _foodIdToVendorName[item.id] = vm.businessName;
            _foodIdToVendorId[item.id] = vm.id;
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
    List<MenuItemModel> filtered = _foods;
    
    if (_selectedCategory != 0) {
      final category = _categories[_selectedCategory];
      filtered = filtered.where((f) => (f.toJson()['category'] as String? ?? '').toLowerCase() == category.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((f) {
        final nameMatch = f.name.toLowerCase().contains(query);
        final descriptionMatch = (f.description ?? '').toLowerCase().contains(query);
        final kitchenName = _foodIdToVendorName[f.id]?.toLowerCase() ?? '';
        return nameMatch || descriptionMatch || kitchenName.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final currentRole = args != null && args['role'] != null ? args['role'] as String : widget.role;
    final isChef = currentRole == 'chef';
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark 
        ? colorScheme.surfaceContainerHigh 
        : PlokitchTheme.surfaceContainerHigh;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar
                          if (isChef)
                            TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: 'Search your kitchen items...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty 
                                    ? IconButton(icon: const Icon(Icons.close), onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      })
                                    : null,
                                filled: true,
                                fillColor: containerColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (v) => setState(() => _searchQuery = v),
                                    decoration: InputDecoration(
                                      hintText: 'Search for food or kitchens...',
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: _searchQuery.isNotEmpty 
                                          ? IconButton(icon: const Icon(Icons.close), onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            })
                                          : null,
                                      filled: true,
                                      fillColor: containerColor,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                 GestureDetector(
                                   onTap: () async {
                                     await Navigator.pushNamed(context, '/cart');
                                     _loadCartCount();
                                   },
                                   child: Container(
                                     width: 56,
                                     height: 56,
                                     decoration: BoxDecoration(
                                       color: containerColor,
                                       borderRadius: BorderRadius.circular(28),
                                     ),
                                     alignment: Alignment.center,
                                     child: Badge(
                                       label: Text('$_cartItemCount'),
                                       isLabelVisible: _cartItemCount > 0,
                                       backgroundColor: colorScheme.primaryContainer,
                                       textColor: colorScheme.onPrimaryContainer,
                                       child: Icon(
                                         Icons.shopping_cart_outlined,
                                         color: colorScheme.primary,
                                         size: 24,
                                       ),
                                     ),
                                   ),
                                 ),
                              ],
                            ),
                        const SizedBox(height: 20),
                        Text(isChef ? 'Manage your posted dishes' : 'Explore local flavors', style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline)),
                        const SizedBox(height: 20),
                        _buildCategoryFilter(colorScheme),
                        const SizedBox(height: 24),
                        if (_error != null) Center(child: Text('Error: $_error')) else ...[
                          if (!isChef) ...[
                            Text('Featured Kitchens', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _buildKitchenSection(context),
                            const SizedBox(height: 32),
                          ],
                          Text(isChef ? 'Your Dishes' : 'Popular Dishes', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_filteredFoods.isEmpty)
                   SliverToBoxAdapter(
                     child: Center(
                       child: Padding(
                         padding: const EdgeInsets.all(32.0),
                         child: Column(
                           children: [
                             Icon(Icons.search_off, size: 64, color: colorScheme.outline),
                             const SizedBox(height: 16),
                             Text('No items found matching "$_searchQuery"', style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline)),
                           ],
                         ),
                       ),
                     ),
                   )
                else
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
                        (context, index) => _buildFoodGridCard(context, _filteredFoods[index], colorScheme, textTheme, isChef),
                        childCount: _filteredFoods.length,
                      ),
                    ),
                  ),
                 const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
    );
  }

  Widget _buildCategoryFilter(ColorScheme colorScheme) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
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
        separatorBuilder: (context, _) => const SizedBox(width: 12),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(vendor.businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: vendor.isOpenNow ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vendor.isOpenNow ? 'Open' : 'Closed',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildFoodGridCard(BuildContext context, MenuItemModel food, ColorScheme colorScheme, TextTheme textTheme, bool isChef) {
    final kitchenName = _foodIdToVendorName[food.id] ?? 'Kitchen';
    final vendorId = _foodIdToVendorId[food.id];
    final foodArgs = <String, dynamic>{
      'foodItem': food.toJson(),
      'kitchen': kitchenName,
    };
    if (vendorId != null) {
      foodArgs['vendorId'] = vendorId;
    }
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/food-detail', arguments: foodArgs);
        _loadCartCount();
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: food.imageUrl != null 
                      ? Image.network(food.imageUrl!, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade300, child: const Icon(Icons.fastfood, size: 40, color: Colors.white)),
                  ),
                  if (isChef)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          _buildActionCircle(Icons.edit, Colors.blue, () {
                            // Edit dish logic
                          }),
                          const SizedBox(width: 4),
                          _buildActionCircle(Icons.delete, Colors.red, () {
                            // Delete dish logic
                          }),
                        ],
                      ),
                    ),
                  if (food.isAddOn)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                        child: const Text('ADD-ON', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (!isChef)
                    Text(kitchenName, style: textTheme.bodySmall?.copyWith(color: colorScheme.primary), maxLines: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₦${food.price.toStringAsFixed(0)}', style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      if (!isChef)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      if (isChef)
                        Row(
                          children: [
                            const Text('Add-on', style: TextStyle(fontSize: 10)),
                            Transform.scale(
                              scale: 0.6,
                              child: Switch(
                                value: food.isAddOn,
                                onChanged: (v) {
                                  // Toggle add-on status via API
                                },
                              ),
                            ),
                          ],
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

  Widget _buildActionCircle(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.9), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}
