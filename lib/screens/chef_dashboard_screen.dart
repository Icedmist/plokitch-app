import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/order_model.dart';

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
      final rawVendorId = profile?['vendorId'] ?? profile?['vendor_id'] ?? profile?['id'];
      _vendorId = rawVendorId != null ? rawVendorId.toString() : null;
      final rawVendorName = profile?['name'] ?? profile?['businessName'] ?? profile?['vendorName'];
      _vendorName = rawVendorName is String ? rawVendorName : rawVendorName?.toString();

      final fetched = await ApiService.fetchOrders();
      final filtered = (_vendorId != null || _vendorName != null)
          ? fetched.where((order) {
              if (_vendorId != null && order.vendorId == _vendorId) return true;
              return _vendorName != null && order.vendorName?.toLowerCase() == _vendorName?.toLowerCase();
            }).toList()
          : fetched;
      if (mounted) {
        setState(() {
          _orders = filtered;
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

  void _handleAction(int index) {
    final order = _orders[index];
    final nextStatus = _orderNextStatus(order.status);
    if (nextStatus == order.status) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cannot move forward from its current stage.')));
      return;
    }
    setState(() {
      _orders[index] = order.copyWith(status: nextStatus);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order ${order.id} updated to $nextStatus.')));
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: PlokitchAppBar(
        title: 'Chef Dashboard',
        showMenu: true,
        showAvatar: true,
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC1gXjr87jg3akcU1Mwi3bCdesg0x-bVOWPW52a-ynSkxaF24VNY08iKMVRnGbe63il2UEzHVrzg696zTn0xUyhwAhI4ED2MBsr-fB4Eq_pMGsLh1ERMuICPBNUEQsGAuc8bHuZzOotcr71bmiAkrIEh5QSO3w6Pn09XC0-PTaj94-XT2K8JOF6brkz0KYG8-dtVLmSrCLDM8BSWdts7C8ioBeisiM2uJa68vlufdXxeNinVhbY6Ju7P-08X_VjgINOwGUrfF8sNrYK',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Quick Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: const Border(bottom: BorderSide(color: Color(0xFFFF9B04), width: 4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickStat('Online Status', 'OPEN', textTheme),
                Container(width: 1, height: 32, color: Colors.white24),
                _buildQuickStat('Avg Prep', '22 MIN', textTheme),
                Container(width: 1, height: 32, color: Colors.white24),
                _buildQuickStat('Top Seller', 'MASA', textTheme),
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
                          Text('42', style: textTheme.headlineLarge?.copyWith(color: colorScheme.onPrimaryContainer)),
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
                          Text('₦85k', style: textTheme.headlineLarge?.copyWith(color: colorScheme.onPrimaryContainer)),
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
      bottomNavigationBar: PlokitchBottomNav(
        role: 'chef',
        currentIndex: 0, // Home/Dashboard
        onTap: (index) {
          if (index == 0) _loadOrders();
          if (index == 1) Navigator.pushReplacementNamed(context, '/kitchen');
          if (index == 2) Navigator.pushReplacementNamed(context, '/chef-orders');
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, TextTheme textTheme) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: textTheme.labelLarge?.copyWith(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: textTheme.headlineMedium?.copyWith(color: const Color(0xFFFF9B04))),
      ],
    );
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
