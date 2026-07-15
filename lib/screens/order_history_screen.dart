import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/order_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({bool forceRefresh = false}) async {
    setState(() {
      _loading = _orders.isEmpty;
      _error = null;
    });
    try {
      final profile = await AuthService.getProfile();
      final customerId = profile?['id'];

      final fetched = await ApiService.fetchOrders(customerId: customerId, forceRefresh: forceRefresh);
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

  Color _getStatusBgColor(String status, ColorScheme colorScheme) {
    final lower = status.toLowerCase();
    switch (lower) {
      case 'completed':
      case 'delivered':
        return Colors.green.withValues(alpha: 0.12);
      case 'preparing':
      case 'cooking':
      case 'processing':
        return Colors.blue.withValues(alpha: 0.12);
      case 'ready':
      case 'prepared':
        return Colors.teal.withValues(alpha: 0.12);
      case 'cancelled':
        return colorScheme.errorContainer.withValues(alpha: 0.15);
      case 'pending':
      case 'received':
      case 'confirmed':
      default:
        return Colors.amber.withValues(alpha: 0.15);
    }
  }

  Color _getStatusTextColor(String status, ColorScheme colorScheme) {
    final lower = status.toLowerCase();
    switch (lower) {
      case 'completed':
      case 'delivered':
        return Colors.green.shade800;
      case 'preparing':
      case 'cooking':
      case 'processing':
        return Colors.blue.shade800;
      case 'ready':
      case 'prepared':
        return Colors.teal.shade800;
      case 'cancelled':
        return colorScheme.error;
      case 'pending':
      case 'received':
      case 'confirmed':
      default:
        return Colors.amber.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Order History',
        showMenu: false,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadOrders(forceRefresh: true),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(child: Text('Error: $_error')),
                      ),
                    ],
                  )
                : _orders.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: const Center(child: Text('No order history found')),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final itemsSummary = order.items.map((i) => i['name'] ?? 'Item').join(', ');
                          final date = order.createdAt?.split('T').first ?? '--';

                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/tracking', arguments: order.id);
                            },
                            child: Container(
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
                                      Text(
                                        '#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                                        style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusBgColor(order.status, colorScheme),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          order.status,
                                          style: textTheme.labelSmall?.copyWith(
                                            color: _getStatusTextColor(order.status, colorScheme),
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
                                      Expanded(
                                        child: Text(
                                          order.vendorName ?? 'Local Kitchen',
                                          style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    itemsSummary,
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
                                          Text(date, style: textTheme.bodySmall?.copyWith(color: colorScheme.outline)),
                                        ],
                                      ),
                                      Text(
                                        '₦${order.totalAmount.toStringAsFixed(2)}',
                                        style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
