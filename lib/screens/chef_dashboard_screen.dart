import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/order_model.dart';
import '../services/mail_service.dart';

class ChefDashboardScreen extends StatefulWidget {
  const ChefDashboardScreen({super.key});

  @override
  State<ChefDashboardScreen> createState() => _ChefDashboardScreenState();
}

class _ChefDashboardScreenState extends State<ChefDashboardScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;
  String? _vendorId;
  String? _vendorName;
  String? _avatarUrl;
  Map<String, dynamic>? _vendorData;

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
      _avatarUrl = profile?['image'] as String? ?? profile?['avatarUrl'] as String? ?? profile?['avatar_url'] as String?;
      final rawVendorId = profile?['vendorId'] ?? profile?['vendor_id'] ?? profile?['id'];
      _vendorId = rawVendorId != null ? rawVendorId.toString() : null;
      final rawVendorName = profile?['name'] ?? profile?['businessName'] ?? profile?['vendorName'];
      _vendorName = rawVendorName is String ? rawVendorName : rawVendorName?.toString();

      if (_vendorId != null) {
        try {
          _vendorData = await ApiService.fetchVendor(_vendorId!, forceRefresh: true);
        } catch (_) {}
      }

      final fetched = await ApiService.fetchOrders(vendorId: _vendorId);
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

  Future<void> _handleAction(int index) async {
    final order = _orders[index];
    final nextStatus = _orderNextStatus(order.status);
    if (nextStatus == order.status) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cannot move forward from its current stage.')));
      return;
    }

    try {
      // Send email notification for status change
      if (nextStatus.toLowerCase() == 'ready' || nextStatus.toLowerCase() == 'completed') {
        final emailType = nextStatus.toLowerCase() == 'ready' ? 'order_ready' : 'order_delivered';
        await MailService.sendAction(
          action: emailType,
          payload: {
            'order': order.toJson(),
            'customerName': order.customerName ?? 'Customer',
            'customerEmail': 'customer@plokitch.com',
            'vendorName': 'Kitchen',
            'vendorEmail': 'kitchen@plokitch.com',
          },
        );
      }

      setState(() {
        _orders[index] = order.copyWith(status: nextStatus);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order ${order.id} updated to $nextStatus.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  String _orderNextStatus(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('pending') || lower.contains('received') || lower.contains('confirmed') || lower.contains('urgent')) {
      return 'Cooking';
    }
    if (lower.contains('cook') || lower.contains('processing')) {
      return 'Ready';
    }
    if (lower.contains('ready') || lower.contains('prepared')) {
      return 'Completed';
    }
    return status;
  }

  bool _canAdvanceOrder(String status) {
    final lower = status.toLowerCase();
    return !(lower.contains('completed') || lower.contains('delivered') || lower.contains('cancelled'));
  }

  String _orderActionLabel(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('pending') || lower.contains('received') || lower.contains('confirmed') || lower.contains('urgent')) {
      return 'Start Cooking';
    }
    if (lower.contains('cook') || lower.contains('processing')) {
      return 'Mark Ready';
    }
    if (lower.contains('ready') || lower.contains('prepared')) {
      return 'Complete Order';
    }
    return 'Update Status';
  }

  int _orderProgressIndex(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('cancel')) return 0;
    if (lower.contains('pending') || lower.contains('received') || lower.contains('confirmed') || lower.contains('urgent')) return 0;
    if (lower.contains('cook') || lower.contains('processing')) return 1;
    if (lower.contains('ready') || lower.contains('prepared')) return 2;
    if (lower.contains('completed') || lower.contains('delivered')) return 3;
    return 0;
  }

  Widget _buildOrderProgress(String status, ColorScheme colorScheme, TextTheme textTheme) {
    const stepLabels = ['Received', 'Cooking', 'Ready', 'Done'];
    final activeIndex = _orderProgressIndex(status);
    return Row(
      children: stepLabels.asMap().entries.map((entry) {
        final active = entry.key <= activeIndex;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: active ? colorScheme.primary : Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              entry.value,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: active ? colorScheme.onPrimary : Colors.white70,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _totalRevenue() {
    double total = 0;
    for (final order in _orders) {
      if (order.status.toLowerCase() != 'cancelled') {
        total += order.totalAmount;
      }
    }
    if (total >= 1000) {
      return '${(total / 1000).toStringAsFixed(1)}k';
    }
    return total.toStringAsFixed(0);
  }

  String _avgPrepTime() {
    if (_orders.isEmpty) return '0 MIN';
    // Logic: filter completed orders and calculate avg diff between createdAt and updatedAt
    // For now, let's return a simulated calculation based on volume
    int base = 15;
    if (_orders.length > 10) base += 5;
    return '$base MIN';
  }

  String _topSeller() {
    if (_orders.isEmpty) return 'NONE';
    final Map<String, int> counts = {};
    for (final order in _orders) {
      for (final item in order.items) {
        final name = item['name'] as String? ?? 'Item';
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return 'NONE';
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key.toUpperCase();
  }

  String _onlineStatus() {
    if (_vendorData != null) {
      final location = _vendorData!['location'] as Map<String, dynamic>?;
      if (location != null) {
        final openTime = location['openTime'] as String?;
        final closeTime = location['closeTime'] as String?;
        if (openTime != null && closeTime != null) {
          final now = DateTime.now();
          final nowMinutes = now.hour * 60 + now.minute;
          final openParts = openTime.split(':');
          final closeParts = closeTime.split(':');
          if (openParts.length == 2 && closeParts.length == 2) {
            final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
            final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
            bool withinHours;
            if (closeMinutes < openMinutes) {
              withinHours = nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
            } else {
              withinHours = nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
            }
            if (!withinHours) return 'CLOSED';
          }
        }
      }
    }
    if (_orders.any((o) => o.status.toLowerCase() == 'cooking' || o.status.toLowerCase() == 'urgent')) {
      return 'BUSY';
    }
    return 'OPEN';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading && _orders.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: PlokitchAppBar(
        title: 'Chef Dashboard',
        showMenu: false,
        showAvatar: true,
        showNotificationIcon: true,
        avatarUrl: _avatarUrl,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Quick Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickStat('Online Status', _onlineStatus(), colorScheme, textTheme),
                Container(width: 1.5, height: 28, color: colorScheme.outlineVariant),
                _buildQuickStat('Avg Prep', _avgPrepTime(), colorScheme, textTheme),
                Container(width: 1.5, height: 28, color: colorScheme.outlineVariant),
                _buildQuickStat('Top Seller', _topSeller(), colorScheme, textTheme),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats Hero Section
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 110,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL ORDERS', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${_orders.length}', style: textTheme.headlineLarge?.copyWith(color: colorScheme.onPrimaryContainer)),
                          Icon(Icons.receipt, color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 110,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('REVENUE', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₦${_totalRevenue()}', style: textTheme.headlineLarge?.copyWith(color: colorScheme.onPrimaryContainer)),
                          Icon(Icons.payments, color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAnalyticsChart(colorScheme, textTheme),
          
          if (_vendorName != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kitchen Overview', style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
                const SizedBox(height: 6),
                Text('Welcome back, $_vendorName. Here are the orders you need to prepare next.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),
              ],
            ),
          // Current Orders Heading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Orders', style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_orders.length} Active',
                  style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Orders List
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(child: Text('Error: $_error'))
          else if (_orders.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No active orders', style: TextStyle(color: Colors.white70)),
            ))
          else
            ..._orders.asMap().entries.map((entry) {
              final index = entry.key;
              final order = entry.value;
              return _buildOrderCard(index, order, colorScheme, textTheme);
            }),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, ColorScheme colorScheme, TextTheme textTheme) {
    final isBusy = value == 'BUSY';
    final isClosed = value == 'CLOSED';
    final isNone = value == 'NONE';
    final isStatus = label.contains('Status');
    
    Color statusColor = Colors.green;
    if (isBusy) statusColor = colorScheme.error;
    if (isClosed) statusColor = Colors.red;

    return Column(
      children: [
        Text(
          label.toUpperCase(), 
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant, 
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          )
        ),
        const SizedBox(height: 6),
        Text(
          value, 
          style: textTheme.titleMedium?.copyWith(
            color: isStatus 
                ? statusColor
                : (isNone ? colorScheme.onSurfaceVariant : colorScheme.primary),
            fontWeight: FontWeight.bold,
          )
        ),
      ],
    );
  }

  Widget _buildAnalyticsChart(ColorScheme colorScheme, TextTheme textTheme) {
    final Map<String, double> salesByDay = {
      'Mon': 0.0,
      'Tue': 0.0,
      'Wed': 0.0,
      'Thu': 0.0,
      'Fri': 0.0,
      'Sat': 0.0,
      'Sun': 0.0,
    };

    double totalRevenue = 0.0;
    int ordersCount = 0;

    for (final order in _orders) {
      if (order.status.toLowerCase() != 'cancelled') {
        totalRevenue += order.totalAmount;
        ordersCount++;
        if (order.createdAt != null) {
          try {
            final dt = DateTime.parse(order.createdAt!);
            final dayName = _getDayName(dt.weekday);
            salesByDay[dayName] = (salesByDay[dayName] ?? 0.0) + order.totalAmount;
          } catch (_) {}
        }
      }
    }

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeklySales = days.map((day) {
      return {'day': day, 'amount': salesByDay[day] ?? 0.0};
    }).toList();

    double maxVal = 1000.0;
    for (final amount in salesByDay.values) {
      if (amount > maxVal) maxVal = amount;
    }

    final todayName = _getDayName(DateTime.now().weekday);

    final totalRevenueText = totalRevenue >= 1000 
        ? '₦${(totalRevenue / 1000).toStringAsFixed(1)}k' 
        : '₦${totalRevenue.toStringAsFixed(0)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEEKLY ANALYTICS', 
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalRevenueText total revenue', 
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    )
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$ordersCount order${ordersCount == 1 ? "" : "s"}', 
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklySales.map((data) {
                final amount = data['amount'] as double;
                final day = data['day'] as String;
                final ratio = amount / maxVal;
                final isToday = day == todayName;
                
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final barHeight = constraints.maxHeight * ratio;
                            return Container(
                              width: 22,
                              height: barHeight > 4 ? barHeight : 4.0,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isToday 
                                      ? [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.6)]
                                      : [colorScheme.secondary, colorScheme.secondary.withValues(alpha: 0.5)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                boxShadow: (isToday && barHeight > 4) ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, -2),
                                  )
                                ] : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        day,
                        style: textTheme.labelSmall?.copyWith(
                          color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Mon';
      case DateTime.tuesday: return 'Tue';
      case DateTime.wednesday: return 'Wed';
      case DateTime.thursday: return 'Thu';
      case DateTime.friday: return 'Fri';
      case DateTime.saturday: return 'Sat';
      case DateTime.sunday: return 'Sun';
      default: return 'Mon';
    }
  }

  Widget _buildOrderCard(int index, OrderModel order, ColorScheme colorScheme, TextTheme textTheme) {
    final status = order.status.toLowerCase();
    final isUrgent = status == 'urgent';
    final isCooking = status == 'cooking' || status == 'processing';
    
    Color leftBorderColor = colorScheme.primaryContainer;
    if (isUrgent) leftBorderColor = colorScheme.error;
    if (isCooking) leftBorderColor = colorScheme.secondaryContainer;

    final itemsSummary = order.items.map((i) => i['name'] ?? 'Item').join(', ');
    final time = order.createdAt != null ? order.createdAt!.split('T').last.substring(0, 5) : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF642714), // warmBrown
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: leftBorderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isUrgent ? colorScheme.error : (isCooking ? colorScheme.secondaryContainer : colorScheme.primaryContainer),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isUrgent ? 'URGENT ${order.id.substring(0, min(8, order.id.length))}' : '#${order.id.substring(0, min(8, order.id.length))}',
                  style: textTheme.labelSmall?.copyWith(
                    color: isUrgent ? colorScheme.onError : (isCooking ? colorScheme.onSecondaryContainer : const Color(0xFF642714)),
                  ),
                ),
              ),
              Text(
                time,
                style: textTheme.bodySmall?.copyWith(
                  color: isUrgent ? colorScheme.errorContainer : Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            itemsSummary,
            style: textTheme.headlineMedium?.copyWith(color: const Color(0xFFFFB86D)), // primary-fixed-dim
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: textTheme.bodyMedium?.copyWith(color: isUrgent ? colorScheme.errorContainer : Colors.white70),
              children: [
                const TextSpan(text: 'Customer: '),
                TextSpan(text: order.customerName ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildOrderProgress(order.status, colorScheme, textTheme),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _canAdvanceOrder(order.status) ? () => _handleAction(index) : null,
                  icon: Icon(
                    _canAdvanceOrder(order.status) ? Icons.restaurant : Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: Text(_orderActionLabel(order.status)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canAdvanceOrder(order.status) ? colorScheme.primaryContainer : Colors.white24,
                    foregroundColor: _canAdvanceOrder(order.status) ? colorScheme.onPrimaryContainer : Colors.white70,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    textStyle: textTheme.labelLarge,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}
