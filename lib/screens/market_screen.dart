import 'package:flutter/material.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../services/api_service.dart';

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
  List<Map<String, dynamic>> _foods = [];
  List<Map<String, dynamic>> _vendors = [];

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
      final vendors = await ApiService.fetchVendors();
      // vendors are maps; each may include `menuItems`
      final foods = <Map<String, dynamic>>[];
      for (final v in vendors) {
        final vm = Map<String, dynamic>.from(v as Map);
        _vendors.add(vm);
        final items = (vm['menuItems'] as List<dynamic>?) ?? [];
        for (final item in items) {
          final m = Map<String, dynamic>.from(item as Map);
          m['kitchen'] = vm['businessName'] ?? vm['user']?['name'] ?? 'Kitchen';
          m['location'] = vm['location']?['address'] ?? vm['location']?['city'] ?? '';
          foods.add(m);
        }
      }

      setState(() {
        _foods = foods;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredFoods {
    if (_selectedCategory == 0) return _foods;
    final category = _categories[_selectedCategory];
    return _foods.where((f) => (f['category'] as String? ?? '').toLowerCase() == category.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final currentRole = args != null && args['role'] != null ? args['role'] as String : widget.role;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Browse Foods & Kitchens', style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
                    const SizedBox(height: 8),
                    Text(
                      'Select a category, explore kitchens, and review food details before you buy.',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = index == _selectedCategory;
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedCategory = index),
                            selectedColor: colorScheme.primary,
                            backgroundColor: colorScheme.surfaceVariant,
                            labelStyle: TextStyle(
                              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._filteredFoods.map((food) => _buildFoodCard(context, food, colorScheme, textTheme)).toList(),
                    const SizedBox(height: 20),
                    Text('Featured Kitchens', style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
                    const SizedBox(height: 12),
                    ..._vendors.take(2).map((v) => _buildFeaturedKitchenCard(context, v, textTheme, colorScheme)).toList(),
                    const SizedBox(height: 100),
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
          if (index == 1) return;
          if (index == 2) Navigator.pushReplacementNamed(context, '/order-history', arguments: {'role': currentRole});
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, Map<String, dynamic> food, ColorScheme colorScheme, TextTheme textTheme) {
    final displayPrice = (food['price'] is num) ? '₦${(food['price'] as num).toStringAsFixed(2)}' : (food['price']?.toString() ?? '₦0');
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/food-detail', arguments: {'foodItem': food, 'role': widget.role}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((food['image'] as String?) != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                child: Image.network(
                  food['image'] ?? '',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food['name'] ?? '', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
                  const SizedBox(height: 6),
                  Text(food['kitchen'] ?? '', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text((food['rating'] ?? '').toString(), style: textTheme.bodyLarge),
                        ],
                      ),
                      Text(displayPrice, style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(food['category'] ?? '')), 
                      Chip(label: Text(food['location'] ?? '')),
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

  Widget _buildFeaturedKitchenCard(BuildContext context, Map<String, dynamic> kitchen, TextTheme textTheme, ColorScheme colorScheme) {
    final image = kitchen['imageUrl'] ?? kitchen['image'] ?? '';
    final name = kitchen['businessName'] ?? kitchen['user']?['name'] ?? 'Kitchen';
    final rating = (kitchen['rating'] ?? '').toString();
    final specialty = kitchen['specialty'] ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: image.isNotEmpty ? Image.network(image, width: 64, height: 64, fit: BoxFit.cover) : null,
        title: Text(name, style: textTheme.titleMedium),
        subtitle: Text('$specialty · Rated $rating'),
        trailing: TextButton(onPressed: () => Navigator.pushNamed(context, '/kitchen-profile', arguments: {'id': kitchen['id']}), child: const Text('View')),
      ),
    );
  }

  // Removed duplicate featured kitchen card (kept ListTile version above)
}
