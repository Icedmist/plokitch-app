import 'package:flutter/material.dart';
import '../widgets/plokitch_bottom_nav.dart';

class MarketScreen extends StatefulWidget {
  final String role;

  const MarketScreen({super.key, this.role = 'foodie'});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final List<String> _categories = ['All', 'Hot Meals', 'Snacks', 'Desserts', 'Drinks'];
  int _selectedCategory = 0;

  final List<Map<String, dynamic>> _foods = const [
    {
      'id': 'FD-101',
      'name': 'Jollof Rice Feast',
      'kitchen': 'Mama Kike\'s Kitchen',
      'category': 'Hot Meals',
      'price': '₦3,500',
      'rating': '4.9',
      'image': 'https://images.unsplash.com/photo-1604908177522-7408d1e832f8?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'description': 'Classic jollof rice served with tender chicken and a side salad.',
      'location': 'Wuse 2, Gombe',
    },
    {
      'id': 'FD-102',
      'name': 'Masa & Miyan Taushe',
      'kitchen': 'Binta\'s Masa House',
      'category': 'Hot Meals',
      'price': '₦2,900',
      'rating': '4.8',
      'image': 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'description': 'Soft masa paired with spicy miyan taushe made from seasonal greens.',
      'location': 'Garki, Gombe',
    },
    {
      'id': 'FD-103',
      'name': 'Suya Platter',
      'kitchen': 'Hajiya\'s Suya Spot',
      'category': 'Snacks',
      'price': '₦1,700',
      'rating': '4.7',
      'image': 'https://images.unsplash.com/photo-1599785209707-5f4d8b8cd4b5?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'description': 'Spicy suya served hot with onions, tomatoes and traditional pepper mix.',
      'location': 'Kumbiya, Gombe',
    },
    {
      'id': 'FD-104',
      'name': 'Pounded Yam & Egusi',
      'kitchen': 'Chef Emeka\'s Spot',
      'category': 'Hot Meals',
      'price': '₦3,200',
      'rating': '4.8',
      'image': 'https://images.unsplash.com/photo-1551218808-94e220e084d2?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'description': 'Soft pounded yam with rich egusi soup and tender beef.',
      'location': 'Town, Gombe',
    },
    {
      'id': 'FD-105',
      'name': 'Kilishi Bites',
      'kitchen': 'Arewa Delicacies',
      'category': 'Snacks',
      'price': '₦1,100',
      'rating': '4.6',
      'image': 'https://images.unsplash.com/photo-1548946526-f69e2424cf45?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'description': 'Spicy dried beef strips with crunchy sesame seeds and zesty pepper.',
      'location': 'State Market',
    },
    {
      'id': 'FD-106',
      'name': 'Fura da Nono',
      'kitchen': 'Suya Bar',
      'category': 'Drinks',
      'price': '₦900',
      'rating': '4.5',
      'image': 'https://images.unsplash.com/photo-1528735605474-1f1c9ba931f5?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'description': 'Chilled millet balls in fermented milk, a Gombe favorite.',
      'location': 'GCC Road',
    },
  ];

  List<Map<String, dynamic>> get _filteredFoods {
    if (_selectedCategory == 0) return _foods;
    return _foods.where((food) => food['category'] == _categories[_selectedCategory]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        centerTitle: true,
      ),
      body: ListView(
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
          _buildFeaturedKitchenCard(context, {
            'name': 'Hajiya\'s Suya Spot',
            'rating': '4.9',
            'specialty': 'Spicy suya and snacks',
            'location': 'Kumbiya, Gombe',
            'image': 'https://images.unsplash.com/photo-1484723091739-30a097e8f929?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
          }, textTheme, colorScheme),
          const SizedBox(height: 12),
          _buildFeaturedKitchenCard(context, {
            'name': 'Mama Kike\'s Kitchen',
            'rating': '4.9',
            'specialty': 'Traditional jollof and rice meals',
            'location': 'Wuse 2, Gombe',
            'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
          }, textTheme, colorScheme),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: PlokitchBottomNav(
        role: widget.role,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            if (widget.role == 'rider') {
              Navigator.pushReplacementNamed(context, '/rider-dashboard');
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
          if (index == 1) return;
          if (index == 2) Navigator.pushReplacementNamed(context, '/order-history', arguments: {'role': widget.role});
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, Map<String, dynamic> food, ColorScheme colorScheme, TextTheme textTheme) {
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
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child: Image.network(
                food['image'],
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
                  Text(food['name'], style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
                  const SizedBox(height: 6),
                  Text(food['kitchen'], style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(food['rating'], style: textTheme.bodyLarge),
                        ],
                      ),
                      Text(food['price'], style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(food['category'])),
                      Chip(label: Text(food['location'])),
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
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/kitchen-profile', arguments: {'name': kitchen['name'], 'role': widget.role}),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
          image: DecorationImage(
            image: NetworkImage(kitchen['image']),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(kitchen['name'], style: textTheme.titleLarge?.copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              Text('${kitchen['rating']} · ${kitchen['location']}', style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
