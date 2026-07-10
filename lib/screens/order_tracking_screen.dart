import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;

  const OrderTrackingScreen({super.key, this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  OrderModel? _order;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !_loading) _fetchOrder();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrder() async {
    if (widget.orderId == null) {
      setState(() {
        _loading = false;
        _error = 'No order ID provided';
      });
      return;
    }

    try {
      final order = await ApiService.fetchOrder(widget.orderId!);
      if (mounted) {
        setState(() {
          _order = order;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load order';
        });
      }
    }
  }

  /// Map Solvix/Plokitch status to a tracking step index (0-3).
  int _getTrackingStep() {
    final status = _order?.solvixStatus ?? _order?.status ?? 'pending';
    switch (status.toLowerCase()) {
      case 'pending':
      case 'confirmed':
        return 0;
      case 'preparing':
        return 1;
      case 'ready':
      case 'picking':
      case 'picked_up':
      case 'assigned':
        return 2;
      case 'in_transit':
      case 'delivering':
        return 2;
      case 'delivered':
      case 'completed':
        return 3;
      case 'cancelled':
        return -1; // cancelled
      default:
        return 0;
    }
  }

  String _formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Track Order',
        showMenu: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _fetchOrder();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildTrackingBody(colorScheme, textTheme),
    );
  }

  Widget _buildTrackingBody(ColorScheme colorScheme, TextTheme textTheme) {
    final order = _order!;
    final step = _getTrackingStep();
    final solvixRider = order.solvixRiderName;
    final deliveryAddr = order.deliveryAddress;
    final addrStr = deliveryAddr != null
        ? [deliveryAddr['street'], deliveryAddr['city'], deliveryAddr['state']].where((e) => e != null && e.toString().isNotEmpty).join(', ')
        : '';

    return Stack(
      children: [
        // Map Background (Placeholder)
        Positioned.fill(
          child: Image.network(
            'https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
            fit: BoxFit.cover,
          ),
        ),

        // Map Overlay Pin
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF35301D),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Text(
                  step >= 2 ? 'Rider En Route' : order.solvixStatus == 'assigned' ? 'Rider Assigned' : 'Preparing Order',
                  style: textTheme.labelLarge?.copyWith(color: colorScheme.primaryContainer),
                ),
              ),
              const SizedBox(height: 8),
              Icon(Icons.location_on, size: 48, color: colorScheme.primaryContainer),
            ],
          ),
        ),

        // Draggable Status Bottom Sheet
        DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF35301D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: textTheme.headlineSmall?.copyWith(color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.primaryContainer),
                        ),
                        child: Text(
                          order.solvixStatus?.toUpperCase() ?? order.status.toUpperCase(),
                          style: textTheme.labelLarge?.copyWith(color: colorScheme.primaryContainer),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Tracking Progress
                  _buildTrackingStep('Order Placed', step >= 0 ? 'Confirmed' : 'Pending', step >= 0, step == 0, colorScheme, textTheme),
                  _buildTrackingStep('Preparing', step >= 1 ? (step == 1 ? 'In Progress...' : 'Done') : 'Pending', step >= 1, step == 1, colorScheme, textTheme),
                  _buildTrackingStep('Rider Assigned', step >= 2 ? (solvixRider ?? 'Rider on the way') : 'Pending', step >= 2, step == 2, colorScheme, textTheme),
                  _buildTrackingStep('Delivered', step >= 3 ? 'Completed' : 'Pending', step >= 3, step == 3, colorScheme, textTheme, isLast: true),

                  if (step == -1) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Text('This order was cancelled', style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
                        ],
                      ),
                    ),
                  ],

                  const Divider(color: Colors.white24, height: 48),

                  // Order Summary
                  Text('Order Details', style: textTheme.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 16),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildOrderLine(
                      '${item['name']} (x${item['quantity']})',
                      _formatCurrency((item['price'] as num).toDouble() * (item['quantity'] as num).toInt()),
                      textTheme,
                    ),
                  )),
                  if (order.deliveryFee != null && order.deliveryFee != '0') ...[
                    const SizedBox(height: 8),
                    _buildOrderLine('Delivery Fee', _formatCurrency(double.tryParse(order.deliveryFee!) ?? 0), textTheme),
                  ],
                  const SizedBox(height: 16),
                  _buildOrderLine('Total Paid', _formatCurrency(order.totalAmount), textTheme, isTotal: true, colorScheme: colorScheme),

                  if (addrStr.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: colorScheme.primaryContainer, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(addrStr, style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                        ),
                      ],
                    ),
                  ],

                  const Divider(color: Colors.white24, height: 48),

                  // Rider Card
                  if (solvixRider != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: colorScheme.surface,
                            child: Icon(Icons.person, color: colorScheme.onSurface),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(solvixRider, style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                                Text(
                                  order.solvixStatus == 'in_transit' ? 'On the way' : 'Assigned',
                                  style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (step >= 1 && step < 3)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Text('Waiting for rider assignment...', style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrackingStep(String title, String subtitle, bool isCompleted, bool isCurrent, ColorScheme colorScheme, TextTheme textTheme, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? colorScheme.primaryContainer : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? colorScheme.primaryContainer : Colors.white24,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Color(0xFF663B00))
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted && !isCurrent ? colorScheme.primaryContainer : Colors.white24,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: isCompleted ? Colors.white : Colors.white54,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: isCurrent ? colorScheme.primaryContainer : Colors.white38,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderLine(String title, String value, TextTheme textTheme, {bool isTotal = false, ColorScheme? colorScheme}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: isTotal
              ? textTheme.titleMedium?.copyWith(color: Colors.white)
              : textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        Text(
          value,
          style: isTotal
              ? textTheme.titleLarge?.copyWith(color: colorScheme?.primaryContainer)
              : textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
