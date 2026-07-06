import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';

class _OrderHistoryItem {
  final String id;
  final String restaurantName;
  final String items;
  final String total;
  final String date;
  final String status;

  const _OrderHistoryItem({
    required this.id,
    required this.restaurantName,
    required this.items,
    required this.total,
    required this.date,
    required this.status,
  });
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final List<_OrderHistoryItem> _orders = const [
    _OrderHistoryItem(
      id: '#PK-8249',
      restaurantName: 'Mama Kike\'s Kitchen',
      items: 'Jollof Rice Feast (x2), Suya Platter',
      total: '₦17,000',
      date: 'Today, 12:30 PM',
      status: 'Delivered',
    ),
    _OrderHistoryItem(
      id: '#PK-8201',
      restaurantName: 'Chef Emeka\'s Spot',
      items: 'Pounded Yam & Egusi, Pepper Soup',
      total: '₦9,800',
      date: 'Yesterday, 7:15 PM',
      status: 'Delivered',
    ),
    _OrderHistoryItem(
      id: '#PK-8150',
      restaurantName: 'Arewa Delicacies',
      items: 'Tuwon Shinkafa & Miyan Kuka (x3)',
      total: '₦6,200',
      date: 'Jul 4, 1:02 PM',
      status: 'Delivered',
    ),
    _OrderHistoryItem(
      id: '#PK-8099',
      restaurantName: 'Lagos Street Kitchen',
      items: 'Agege Bread & Akara (x4)',
      total: '₦3,500',
      date: 'Jul 2, 8:45 AM',
      status: 'Delivered',
    ),
    _OrderHistoryItem(
      id: '#PK-7940',
      restaurantName: 'Mama Kike\'s Kitchen',
      items: 'Classic Masa (6pcs), Kilishi',
      total: '₦5,200',
      date: 'Jun 28, 6:30 PM',
      status: 'Cancelled',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Order History',
        showMenu: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final isDelivered = order.status == 'Delivered';
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.id, style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDelivered
                            ? Colors.green.withValues(alpha: 0.15)
                            : colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.status,
                        style: textTheme.labelSmall?.copyWith(
                          color: isDelivered ? Colors.green.shade700 : colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.storefront, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(order.restaurantName, style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order.items,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(order.date, style: textTheme.bodySmall?.copyWith(color: colorScheme.outline)),
                      ],
                    ),
                    Text(
                      order.total,
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (isDelivered) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/home');
                      },
                      icon: Icon(Icons.replay, size: 16, color: colorScheme.primary),
                      label: Text('Reorder', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: PlokitchBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/home');
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }
}
