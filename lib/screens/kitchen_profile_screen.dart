import 'package:flutter/material.dart';

class KitchenProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? kitchenData;
  final String role;

  const KitchenProfileScreen({super.key, this.kitchenData, this.role = 'foodie'});

  Map<String, dynamic> _resolveKitchen(BuildContext context) {
    final args = kitchenData ?? ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final name = args?['name'] as String? ?? 'Local Kitchen';

    final kitchens = {
      'Hajiya\'s Suya Spot': {
        'name': 'Hajiya\'s Suya Spot',
        'rating': '4.9',
        'location': 'Kumbiya, Gombe',
        'description': 'A local favorite for perfectly grilled suya, served with fresh onions and spicy pepper.',
        'image': 'https://images.unsplash.com/photo-1551218808-94e220e084d2?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        'dishes': [
          'Suya Platter',
          'Kilishi Bites',
          'Fura da Nono',
        ],
      },
      'Mama Kike\'s Kitchen': {
        'name': 'Mama Kike\'s Kitchen',
        'rating': '4.9',
        'location': 'Wuse 2, Gombe',
        'description': 'Known for slow-cooked jollof rice and family recipes from the northern region.',
        'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        'dishes': [
          'Jollof Rice Feast',
          'Tuwo Shinkafa & Miyan Kuka',
          'Masa & Miyan Taushe',
        ],
      },
      'Chef Emeka\'s Spot': {
        'name': 'Chef Emeka\'s Spot',
        'rating': '4.8',
        'location': 'Town, Gombe',
        'description': 'A chef-owned kitchen offering hearty yam meals and rich soups.',
        'image': 'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        'dishes': [
          'Pounded Yam & Egusi',
          'Yam Porridge',
          'Beef Pepper Soup',
        ],
      },
    };

    return kitchens[name] ?? kitchens.values.first;
  }

  @override
  Widget build(BuildContext context) {
    final kitchen = _resolveKitchen(context);
    final roleArg = kitchenData ?? ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final currentRole = role != 'foodie' ? role : (roleArg?['role'] as String? ?? 'foodie');

    return Scaffold(
      appBar: AppBar(title: Text(kitchen['name'])),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(kitchen['image'], height: 220, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 18),
          Text(kitchen['name'], style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${kitchen['rating']} ⭐ · ${kitchen['location']}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          Text(kitchen['description'], style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Text('Menu', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...List<Widget>.from(kitchen['dishes'].map<Widget>((dish) {
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(dish),
                subtitle: const Text('Tap to view food details'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/food-detail',
                    arguments: {
                      'foodItem': {
                        'name': dish,
                        'kitchen': kitchen['name'],
                        'price': '₦2,900',
                        'rating': kitchen['rating'],
                        'image': kitchen['image'],
                        'description': 'Delicious $dish prepared by ${kitchen['name']}.',
                        'location': kitchen['location'],
                      },
                      'role': currentRole,
                    },
                  );
                },
              ),
            );
          })),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (currentRole == 'rider') {
                Navigator.pushReplacementNamed(context, '/rider-dashboard');
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            child: const Text('Back to Market'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ],
      ),
    );
  }
}
