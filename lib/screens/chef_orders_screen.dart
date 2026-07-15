import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../widgets/plokitch_toast.dart';
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
  int _selectedTab = 0; // 0 for Active, 1 for History
  final Set<String> _updatingOrderIds = {};

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
    final order = _orders[index];
    if (_updatingOrderIds.contains(order.id)) return;

    setState(() {
      _updatingOrderIds.add(order.id);
    });

    try {
      final updated = await ApiService.updateOrderStatus(order.id, nextStatus);
      if (mounted) {
        setState(() {
          _orders[index] = updated.copyWith(
            customerName: updated.customerName ?? order.customerName,
            vendorName: updated.vendorName ?? order.vendorName,
          );
        });
        PlokitchToast.show(context, 'Order updated to $nextStatus.');
      }
    } catch (e) {
      if (mounted) {
        PlokitchToast.show(context, 'Failed to update: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingOrderIds.remove(order.id);
        });
      }
    }
  }

  String _orderNextStatus(String status) {
    final lower = status.toLowerCase();
    if (lower == 'pending' || lower == 'received' || lower == 'confirmed' || lower == 'urgent') {
      return 'preparing';
    }
    if (lower == 'preparing' || lower == 'cook' || lower == 'processing') {
      return 'ready';
    }
    if (lower == 'ready' || lower == 'prepared') {
      return 'completed';
    }
    return status;
  }

  bool _canAdvanceOrder(String status) {
    final lower = status.toLowerCase();
    return !(lower == 'completed' || lower == 'delivered' || lower == 'cancelled');
  }

  String _orderActionLabel(String status) {
    final lower = status.toLowerCase();
    if (lower == 'pending' || lower == 'received' || lower == 'confirmed' || lower == 'urgent') {
      return 'Start Cooking';
    }
    if (lower == 'preparing' || lower == 'cook' || lower == 'processing') {
      return 'Mark Ready';
    }
    if (lower == 'ready' || lower == 'prepared') {
      return 'Complete Order';
    }
    return 'Update Status';
  }

  int _orderProgressIndex(String status) {
    final lower = status.toLowerCase();
    if (lower == 'cancelled') return 0;
    if (lower == 'pending' || lower == 'received' || lower == 'confirmed' || lower == 'urgent') return 0;
    if (lower == 'preparing' || lower == 'cook' || lower == 'processing') return 1;
    if (lower == 'ready' || lower == 'prepared') return 2;
    if (lower == 'completed' || lower == 'delivered') return 3;
    return 0;
  }

  Widget _buildOrderProgress(String status, ColorScheme colorScheme, TextTheme textTheme) {
    const stepLabels = ['Received', 'Cooking', 'Ready', 'Done'];
    final activeIndex = _orderProgressIndex(status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              final isPassed = index < activeIndex;
              final isCurrent = index == activeIndex;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCurrent ? colorScheme.primary : (isPassed ? colorScheme.primary.withValues(alpha: 0.2) : colorScheme.surfaceContainerHigh),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isCurrent || isPassed) ? colorScheme.primary : colorScheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isPassed
                            ? Icon(Icons.check, size: 14, color: colorScheme.primary)
                            : (isCurrent
                                ? Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.onPrimary, shape: BoxShape.circle))
                                : Text('${index + 1}', style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 10))),
                      ),
                    ),
                    if (index < 3)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index < activeIndex
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              final isCurrent = index == activeIndex;
              return Expanded(
                child: Text(
                  stepLabels[index],
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(0, 'Active', colorScheme, textTheme),
          ),
          Expanded(
            child: _buildTabButton(1, 'History', colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, ColorScheme colorScheme, TextTheme textTheme) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: textTheme.titleSmall?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(int index, OrderModel order, ColorScheme colorScheme, TextTheme textTheme) {
    final status = order.status.toLowerCase();
    final isUrgent = status == 'urgent';
    final isCooking = status == 'cooking' || status == 'processing' || status == 'preparing';
    
    Color statusColor = colorScheme.primary;
    if (isUrgent) statusColor = colorScheme.error;
    if (isCooking) statusColor = colorScheme.secondary;

    final itemsSummary = order.items.map((i) => '${i['quantity'] ?? 1}x ${i['name'] ?? 'Item'}').join(', ');
    final time = order.createdAt != null ? order.createdAt!.split('T').last.substring(0, 5) : '--:--';
    final isUpdating = _updatingOrderIds.contains(order.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isUrgent ? colorScheme.error : (isCooking ? colorScheme.secondary : colorScheme.primary)).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isUrgent ? colorScheme.error : (isCooking ? colorScheme.secondary : colorScheme.primary)).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  isUrgent ? 'URGENT · #${order.id.substring(0, min(6, order.id.length))}' : '#${order.id.substring(0, min(6, order.id.length))}',
                  style: textTheme.labelSmall?.copyWith(
                    color: isUrgent ? colorScheme.error : (isCooking ? colorScheme.secondary : colorScheme.primary),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            itemsSummary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  children: [
                    const TextSpan(text: 'Customer: '),
                    TextSpan(
                      text: order.customerName ?? 'Guest',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildOrderProgress(order.status, colorScheme, textTheme),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_canAdvanceOrder(order.status)) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: !isUpdating
                        ? () => _updateStatus(index, _orderNextStatus(order.status))
                        : null,
                    icon: isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            _canAdvanceOrder(order.status) ? Icons.restaurant_rounded : Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                    label: Text(isUpdating ? 'Updating...' : _orderActionLabel(order.status)),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: !isUpdating
                      ? () => _updateStatus(index, 'cancelled')
                      : null,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: order.status.toLowerCase() == 'completed' || order.status.toLowerCase() == 'delivered'
                          ? Colors.green.withValues(alpha: 0.08)
                          : colorScheme.errorContainer.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: order.status.toLowerCase() == 'completed' || order.status.toLowerCase() == 'delivered'
                            ? Colors.green.withValues(alpha: 0.2)
                            : colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          order.status.toLowerCase() == 'completed' || order.status.toLowerCase() == 'delivered'
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined,
                          color: order.status.toLowerCase() == 'completed' || order.status.toLowerCase() == 'delivered'
                              ? Colors.green
                              : colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            color: order.status.toLowerCase() == 'completed' || order.status.toLowerCase() == 'delivered'
                                ? Colors.green
                                : colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (order.status.toLowerCase() == 'cancelled') ...[
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: !isUpdating
                                ? () => _updateStatus(index, 'received')
                                : null,
                            child: const Text('Restore'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filteredOrders = _orders
        .asMap()
        .entries
        .where((entry) {
          final isActive = _canAdvanceOrder(entry.value.status);
          return _selectedTab == 0 ? isActive : !isActive;
        })
        .toList();

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Kitchen Orders',
        showMenu: false,
        automaticallyImplyLeading: false,
      ),
      body: _loading && _orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: Column(
                    children: [
                      _buildTabSelector(colorScheme, textTheme),
                      Expanded(
                        child: filteredOrders.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: Center(
                                      child: Text(
                                        _selectedTab == 0 ? 'No active orders' : 'No order history',
                                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final entry = filteredOrders[index];
                                  return _buildOrderCard(entry.key, entry.value, colorScheme, textTheme);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
