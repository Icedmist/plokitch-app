import 'package:flutter/material.dart';

class FoodDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? foodItem;
  final String role;

  const FoodDetailScreen({super.key, this.foodItem, this.role = 'foodie'});

  @override
  Widget build(BuildContext context) {
    final item = foodItem ?? ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final map = item ?? {
      'name': 'Unknown Food',
      'kitchen': 'Unknown Kitchen',
      'price': '₦0',
      'rating': '0.0',
      'image': 'https://images.unsplash.com/photo-1498603283035-8dc0f94d7ea4?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'description': 'No description available.',
      'location': 'Unknown',
    };
    final currentRole = role != 'foodie' ? role : (item?['role'] as String? ?? 'foodie');
    return Scaffold(
      appBar: AppBar(
        title: Text(map['name']),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(map['image'], height: 240, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(map['name'], style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(map['kitchen'], style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(map['price'], style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(map['rating'], style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(map['description'], style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          const Text('Kitchen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(map['kitchen'], style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text('${map['location']} · Rated ${map['rating']}', style: Theme.of(context).textTheme.bodySmall),
              trailing: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/kitchen-profile', arguments: {'name': map['kitchen'], 'role': currentRole}),
                child: const Text('View Profile'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('More Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.food_bank, 'Category', item?['category'] ?? 'Food'),
          _buildDetailRow(Icons.location_on, 'Location', item?['location'] ?? 'Gombe'),
          _buildDetailRow(Icons.timer, 'Preparation', '10 - 15 mins'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Buy Now'),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
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
