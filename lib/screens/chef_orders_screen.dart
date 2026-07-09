import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/order_model.dart';

class ChefOrdersScreen extends StatefulWidget {
  const ChefOrdersScreen({super.key});

  @override
  State<ChefOrdersScreen> createState() => _ChefOrdersScreenState();
}

class _ChefOrdersScreenState extends State<ChefOrdersScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await AuthService.getProfile();
      final vendorId = profile?['vendorId'] ?? profile?['vendor_id'] ?? profile?['id'];
      
      final fetched = await ApiService.fetchOrders(vendorId: vendorId?.toString());
      if (mounted) {
        setState(() {
          _orders = fetched;
        });
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

  Future<void> _updateStatus(int index, String nextStatus) async {
    // In a real app, update via API
    // await ApiService.updateOrderStatus(_orders[index].id, nextStatus);
    setState(() {
      _orders[index] = _orders[index].copyWith(status: nextStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Kitchen Orders',
        showMenu: false,
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null 
              ? Center(child: Text('Error: $_error'))
              : _orders.isEmpty 
                  ? const Center(child: Text('No orders found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final itemsSummary = order.items.map((i) => i['name'] ?? 'Item').join(', ');
                        final time = order.createdAt?.split('T').first ?? '--';

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
                                  Text('#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: order.status.toLowerCase() == 'delivered'
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : order.status.toLowerCase() == 'cancelled'
                                              ? colorScheme.errorContainer.withValues(alpha: 0.18)
                                              : colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(order.status, style: textTheme.labelSmall?.copyWith(color: order.status.toLowerCase() == 'delivered' ? Colors.green.shade700 : colorScheme.onSurface)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(order.customerName ?? 'Guest', style: textTheme.titleLarge),
                              const SizedBox(height: 6),
                              Text(itemsSummary, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(time, style: textTheme.bodySmall?.copyWith(color: colorScheme.outline)),
                                  Text('₦${order.totalAmount.toStringAsFixed(0)}', style: textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  if (order.status.toLowerCase() != 'delivered' && order.status.toLowerCase() != 'cancelled')
                                    OutlinedButton(
                                      onPressed: () => _updateStatus(index, 'Cooking'),
                                      child: const Text('Mark Cooking'),
                                    ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () => _updateStatus(index, order.status.toLowerCase() == 'cancelled' ? 'Delivered' : 'Cancelled'),
                                    child: Text(order.status.toLowerCase() == 'cancelled' ? 'Restore' : 'Cancel'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: PlokitchBottomNav(
        role: 'chef',
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/chef-dashboard');
          if (index == 1) Navigator.pushReplacementNamed(context, '/kitchen');
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }
}
