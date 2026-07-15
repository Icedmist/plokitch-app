import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_toast.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/order_model.dart';

enum RiderStatus { offline, online, delivering }

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen>
    with SingleTickerProviderStateMixin {
  RiderStatus _status = RiderStatus.online;
  bool _hasActiveDelivery = false;
  OrderModel? _activeJob;
  late AnimationController _pingController;
  
  List<OrderModel> _availableOrders = [];
  bool _loading = true;
  String? _error;
  String? _avatarUrl;

  // Stats
  final Map<String, String> _todayStats = {
    'deliveries': '0',
    'earned': '₦0',
    'rating': '5.0',
    'hours': '0h',
  };

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadAvailableOrders();
  }

  Future<void> _loadAvailableOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await AuthService.getProfile();
      _avatarUrl = profile?['image'] as String? ?? profile?['avatarUrl'] as String? ?? profile?['avatar_url'] as String?;

      final fetched = await ApiService.fetchOrders(forceRefresh: true);
      
      final currentRiderId = profile?['id']?.toString();
      final currentRiderName = profile?['name']?.toString();

      final activeJobs = fetched.where((o) =>
          o.status.toLowerCase() == 'delivering' &&
          (o.riderId == currentRiderId || o.solvixRiderName == currentRiderName)).toList();

      if (mounted) {
        setState(() {
          _activeJob = activeJobs.isNotEmpty ? activeJobs.first : null;
          _hasActiveDelivery = _activeJob != null;
          _availableOrders = fetched.where((o) =>
              o.status.toLowerCase() == 'ready' &&
              o.riderId == null &&
              o.solvixDeliveryId == null).toList();
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

  @override
  void dispose() {
    _pingController.dispose();
    super.dispose();
  }

  Future<void> _acceptJob(OrderModel job) async {
    setState(() {
      _loading = true;
    });
    try {
      final profile = await AuthService.getProfile();
      final currentRiderId = profile?['id']?.toString() ?? 'mock-rider-id';
      final currentRiderName = profile?['name']?.toString() ?? 'Mock Rider';

      final updated = await ApiService.updateOrderStatus(
        job.id,
        'delivering',
        additionalFields: {
          'riderId': currentRiderId,
          'solvixRiderName': currentRiderName,
        },
      );

      if (mounted) {
        setState(() {
          _activeJob = updated.copyWith(
            customerName: updated.customerName ?? job.customerName,
            vendorName: updated.vendorName ?? job.vendorName,
          );
          _hasActiveDelivery = true;
        });
        PlokitchToast.show(context, 'Delivery accepted! Head to ${job.vendorName ?? 'Kitchen'}.');
        _loadAvailableOrders();
      }
    } catch (e) {
      if (mounted) {
        PlokitchToast.show(context, 'Failed to accept job: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _completeDelivery() async {
    if (_activeJob == null) return;
    setState(() {
      _loading = true;
    });
    try {
      await ApiService.updateOrderStatus(_activeJob!.id, 'delivered');
      if (mounted) {
        setState(() {
          _activeJob = null;
          _hasActiveDelivery = false;
        });
        PlokitchToast.show(context, 'Order marked as delivered successfully!');
        _loadAvailableOrders();
      }
    } catch (e) {
      if (mounted) {
        PlokitchToast.show(context, 'Failed to complete delivery: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMarkDeliveredConfirmationDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: colorScheme.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mark Delivered?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to mark this order as delivered? This will complete the delivery process.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _completeDelivery();
                        },
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchDeliveryDetails(String vendorId, String customerId) async {
    final results = await Future.wait([
      Supabase.instance.client
          .from('vendor')
          .select('location, user:user_id(phone)')
          .eq('id', vendorId)
          .maybeSingle(),
      Supabase.instance.client
          .from('user')
          .select('phone, email')
          .eq('id', customerId)
          .maybeSingle(),
    ]);
    return {
      'vendor': results[0],
      'customer': results[1],
    };
  }

  void _showDeliveryDetailsBottomSheet(BuildContext context) {
    final order = _activeJob!;
    final vendorId = order.vendorId;
    final customerId = order.customerId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: (vendorId != null && customerId != null)
              ? _fetchDeliveryDetails(vendorId, customerId)
              : Future.value({}),
          builder: (context, snapshot) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(),
                  ],
                ),
              );
            }

            final deliveryAddr = order.deliveryAddress;
            final customerAddrStr = deliveryAddr != null
                ? [deliveryAddr['street'], deliveryAddr['city'], deliveryAddr['state']]
                    .where((e) => e != null && e.toString().isNotEmpty)
                    .join(', ')
                : 'No address provided';

            final itemsSummary = order.items.map((i) => '${i['quantity'] ?? 1}x ${i['name'] ?? 'Item'}').join('\n');

            String vendorAddress = 'Fetching kitchen address...';
            String? vendorPhone;
            String? customerPhone;

            if (snapshot.hasData) {
              final vendorData = snapshot.data!['vendor'];
              if (vendorData != null) {
                if (vendorData['location'] != null) {
                  final loc = Map<String, dynamic>.from(vendorData['location'] as Map);
                  final addr = loc['address']?.toString() ?? '';
                  final street = loc['street']?.toString() ?? '';
                  final city = loc['city']?.toString() ?? '';
                  final state = loc['state']?.toString() ?? '';
                  final addressParts = [
                    if (addr.isNotEmpty) addr else if (street.isNotEmpty) street,
                    if (city.isNotEmpty) city,
                    if (state.isNotEmpty) state
                  ];
                  vendorAddress = addressParts.isNotEmpty ? addressParts.join(', ') : 'No address provided';
                } else {
                  vendorAddress = 'No address provided';
                }
                if (vendorData['user'] != null) {
                  final userMap = Map<String, dynamic>.from(vendorData['user'] as Map);
                  vendorPhone = userMap['phone']?.toString();
                }
              } else {
                vendorAddress = 'No address provided';
              }

              final customerData = snapshot.data!['customer'];
              if (customerData != null) {
                customerPhone = customerData['phone']?.toString();
              }
            }

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Details',
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order #${order.id}',
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Pick Up From (Vendor)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.storefront_rounded, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PICK UP FROM',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.vendorName ?? 'Kitchen',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vendorAddress,
                              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                            if (vendorPhone != null && vendorPhone.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  FilledButton.icon(
                                    onPressed: () async {
                                      final Uri url = Uri.parse('tel:$vendorPhone');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      }
                                    },
                                    icon: const Icon(Icons.phone_rounded, size: 16),
                                    label: Text(vendorPhone),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Deliver To (Customer)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.secondary.withValues(alpha: 0.1),
                        child: Icon(Icons.person_pin_circle_rounded, color: colorScheme.secondary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DELIVER TO',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.customerName ?? 'Guest',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              customerAddrStr,
                              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                            if (customerPhone != null && customerPhone.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  FilledButton.icon(
                                    onPressed: () async {
                                      final Uri url = Uri.parse('tel:$customerPhone');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      }
                                    },
                                    icon: const Icon(Icons.phone_rounded, size: 16),
                                    label: Text(customerPhone),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.secondary,
                                      foregroundColor: colorScheme.onSecondary,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Items summary
                  Text(
                    'ITEMS',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    itemsSummary,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/tracking', arguments: order.id);
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('Open Map'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showMarkDeliveredConfirmationDialog();
                          },
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Mark Delivered'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(color: colorScheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOnline = _status != RiderStatus.offline;
    
    final deliveryAddr = _activeJob?.deliveryAddress;
    final addrStr = deliveryAddr != null
        ? [deliveryAddr['street'], deliveryAddr['city'], deliveryAddr['state']]
            .where((e) => e != null && e.toString().isNotEmpty)
            .join(', ')
        : '';

    return Scaffold(
      appBar: PlokitchAppBar(
        title: 'Rider Hub',
        showMenu: false,
        showAvatar: true,
        avatarUrl: _avatarUrl,
        showNotificationIcon: true,
        onNotificationPressed: () => Navigator.pushNamed(context, '/notifications'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Toggle Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF1A3A1A) : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOnline ? Colors.green.withValues(alpha: 0.4) : colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'You\'re Online' : 'You\'re Offline',
                      style: textTheme.headlineSmall?.copyWith(
                        color: isOnline ? Colors.white : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isOnline ? 'Accepting delivery requests' : 'Go online to earn',
                      style: textTheme.bodySmall?.copyWith(
                        color: isOnline ? Colors.white70 : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isOnline)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          FadeTransition(
                            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_pingController),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 1.0, end: 2.8).animate(_pingController),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    const SizedBox(width: 12),
                    Switch(
                      value: isOnline,
                      onChanged: (value) {
                        setState(() {
                          _status = value ? RiderStatus.online : RiderStatus.offline;
                        });
                      },
                      activeColor: Colors.green,
                      activeTrackColor: Colors.green.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Today's Stats
          Row(
            children: [
              _buildStatCard('Deliveries', _todayStats['deliveries']!, Icons.local_shipping, colorScheme, textTheme),
              const SizedBox(width: 12),
              _buildStatCard('Earned', _todayStats['earned']!, Icons.payments, colorScheme, textTheme),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Rating', _todayStats['rating']!, Icons.star, colorScheme, textTheme),
              const SizedBox(width: 12),
              _buildStatCard('Online', _todayStats['hours']!, Icons.timer, colorScheme, textTheme),
            ],
          ),
          const SizedBox(height: 24),

          // Active Delivery Banner
          if (_hasActiveDelivery && _activeJob != null) ...[
            GestureDetector(
              onTap: () => _showDeliveryDetailsBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.two_wheeler, color: colorScheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'ACTIVE DELIVERY (Tap for Details)',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'From: ${_activeJob!.vendorName ?? "Kitchen"}',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'To: ${_activeJob!.customerName ?? "Guest"}',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (addrStr.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        addrStr,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/tracking', arguments: _activeJob!.id),
                            icon: const Icon(Icons.map, size: 18),
                            label: const Text('Open Map'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.onPrimaryContainer,
                              foregroundColor: colorScheme.primaryContainer,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showMarkDeliveredConfirmationDialog,
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Mark Delivered'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onPrimaryContainer,
                              side: BorderSide(color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Available Jobs
          if (isOnline && !_hasActiveDelivery) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available Jobs', style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary)),
                if (_loading)
                  const CircularProgressIndicator()
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_availableOrders.length} near you',
                      style: textTheme.labelSmall?.copyWith(color: Colors.green.shade700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Center(child: Text('Error: $_error'))
            else if (_availableOrders.isEmpty && !_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No jobs available right now'),
              ))
            else
              ..._availableOrders.map((job) => _buildJobCard(job, colorScheme, textTheme)),
          ],

          if (!isOnline) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(Icons.power_settings_new, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('You\'re offline', style: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(
                    'Toggle the switch above to start accepting deliveries.',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, ColorScheme colorScheme, TextTheme textTheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colorScheme.primaryContainer, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
                Text(label, style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(OrderModel job, ColorScheme colorScheme, TextTheme textTheme) {
    final itemsSummary = job.items.map((i) => i['name'] ?? 'Item').join(', ');
    final fee = '₦800'; // Default fee as it's not in OrderModel yet

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Text('#${job.id.substring(0, 8)}', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  fee,
                  style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.storefront, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(job.vendorName ?? 'Local Kitchen', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface)),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            height: 16,
            width: 1,
            color: colorScheme.outlineVariant,
          ),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: colorScheme.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Delivery Location', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(itemsSummary, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.timer, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(job.status, style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _acceptJob(job),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: Text('Accept', style: textTheme.labelLarge),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
