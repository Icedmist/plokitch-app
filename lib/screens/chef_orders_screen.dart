import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';

class _ChefOrder {
  final String id;
  final String customer;
  final String items;
  final String time;
  final String total;
  String status;

  _ChefOrder({
    required this.id,
    required this.customer,
    required this.items,
    required this.time,
    required this.total,
    required this.status,
  });
}

class ChefOrdersScreen extends StatefulWidget {
  const ChefOrdersScreen({super.key});

  @override
  State<ChefOrdersScreen> createState() => _ChefOrdersScreenState();
}

class _ChefOrdersScreenState extends State<ChefOrdersScreen> {
  final List<_ChefOrder> _orders = [
    _ChefOrder(
      id: '#PK-198',
      customer: 'Musa Ibrahim',
      items: 'Tuwon Shinkafa & Begedi',
      time: 'Yesterday, 1:02 PM',
      total: '₦4,700',
      status: 'Completed',
    ),
    _ChefOrder(
      id: '#PK-185',
      customer: 'Bello Garba',
      items: 'Pounded Yam & Egusi',
      time: 'Jul 5, 8:40 PM',
      total: '₦3,400',
      status: 'Cancelled',
    ),
    _ChefOrder(
      id: '#PK-167',
      customer: 'Rahama Sani',
      items: 'Jollof Rice Feast',
      time: 'Jul 4, 12:15 PM',
      total: '₦3,500',
      status: 'Delivered',
    ),
    _ChefOrder(
      id: '#PK-156',
      customer: 'Aisha Bello',
      items: 'Suya Platter',
      time: 'Jul 3, 7:25 PM',
      total: '₦1,700',
      status: 'Delivered',
    ),
  ];

  void _updateStatus(int index, String nextStatus) {
    setState(() {
      _orders[index].status = nextStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Chef Orders',
        showMenu: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _orders[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: order.status == 'Delivered'
                            ? Colors.green.withOpacity(0.15)
                            : order.status == 'Cancelled'
                                ? colorScheme.errorContainer.withOpacity(0.18)
                                : colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(order.status, style: textTheme.labelSmall?.copyWith(color: order.status == 'Delivered' ? Colors.green.shade700 : colorScheme.onSurface)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(order.customer, style: textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(order.items, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.time, style: textTheme.bodySmall?.copyWith(color: colorScheme.outline)),
                    Text(order.total, style: textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (order.status != 'Delivered' && order.status != 'Cancelled')
                      OutlinedButton(
                        onPressed: () => _updateStatus(index, 'Cooking'),
                        child: const Text('Mark Cooking'),
                      ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => _updateStatus(index, order.status == 'Cancelled' ? 'Delivered' : 'Cancelled'),
                      child: Text(order.status == 'Cancelled' ? 'Restore' : 'Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
