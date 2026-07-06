import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';

enum RiderStatus { offline, online, delivering }

class _DeliveryJob {
  final String id;
  final String customerName;
  final String pickupLocation;
  final String dropoffLocation;
  final String items;
  final String fee;
  final String distance;
  final String eta;

  const _DeliveryJob({
    required this.id,
    required this.customerName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.items,
    required this.fee,
    required this.distance,
    required this.eta,
  });
}

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen>
    with SingleTickerProviderStateMixin {
  RiderStatus _status = RiderStatus.online;
  bool _hasActiveDelivery = false;
  late AnimationController _pingController;

  final List<_DeliveryJob> _availableJobs = const [
    _DeliveryJob(
      id: '#PK-8250',
      customerName: 'Amina Yusuf',
      pickupLocation: 'Mama Kike\'s Kitchen, Wuse 2',
      dropoffLocation: '15 Aminu Kano Way, Wuse 2',
      items: 'Jollof Rice Feast (x2)',
      fee: '₦800',
      distance: '2.4 km',
      eta: '12 mins',
    ),
    _DeliveryJob(
      id: '#PK-8248',
      customerName: 'Musa Ibrahim',
      pickupLocation: 'Arewa Delicacies, Garki',
      dropoffLocation: '4 Gwandu St, Area 1',
      items: 'Tuwo Shinkafa & Kuka (x3)',
      fee: '₦1,200',
      distance: '5.1 km',
      eta: '24 mins',
    ),
  ];

  // Stats
  final Map<String, String> _todayStats = {
    'deliveries': '7',
    'earned': '₦6,800',
    'rating': '4.9',
    'hours': '3h 20m',
  };

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pingController.dispose();
    super.dispose();
  }

  void _acceptJob(_DeliveryJob job) {
    setState(() {
      _hasActiveDelivery = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delivery ${job.id} accepted! Head to ${job.pickupLocation}.'),
        backgroundColor: const Color(0xFF663B00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _completeDelivery() {
    setState(() {
      _hasActiveDelivery = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOnline = _status != RiderStatus.offline;

    return Scaffold(
      appBar: PlokitchAppBar(
        title: 'Rider Hub',
        showMenu: true,
        showAvatar: true,
        showNotificationIcon: true,
        onNotificationPressed: () => Navigator.pushNamed(context, '/notifications'),
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
          if (_hasActiveDelivery) ...[
            Container(
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
                        'ACTIVE DELIVERY',
                        style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _availableJobs[0].customerName,
                    style: textTheme.headlineMedium?.copyWith(color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _availableJobs[0].dropoffLocation,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/tracking'),
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
                          onPressed: _completeDelivery,
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
            const SizedBox(height: 24),
          ],

          // Available Jobs
          if (isOnline && !_hasActiveDelivery) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available Jobs', style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_availableJobs.length} near you',
                    style: textTheme.labelSmall?.copyWith(color: Colors.green.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._availableJobs.map((job) => _buildJobCard(job, colorScheme, textTheme)),
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
      bottomNavigationBar: PlokitchBottomNav(
        role: 'rider',
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/rider-dashboard');
          if (index == 1) Navigator.pushReplacementNamed(context, '/market', arguments: {'role': 'rider'});
          if (index == 2) Navigator.pushReplacementNamed(context, '/order-history', arguments: {'role': 'rider'});
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
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

  Widget _buildJobCard(_DeliveryJob job, ColorScheme colorScheme, TextTheme textTheme) {
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
              Text(job.id, style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  job.fee,
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
                child: Text(job.pickupLocation, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface)),
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
                child: Text(job.dropoffLocation, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(job.items, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          const Divider(height: 20),
          Row(
            children: [
              Icon(Icons.straighten, size: 14, color: colorScheme.outline),
              const SizedBox(width: 4),
              Text(job.distance, style: textTheme.bodySmall?.copyWith(color: colorScheme.outline)),
              const SizedBox(width: 12),
              Icon(Icons.timer, size: 14, color: colorScheme.outline),
              const SizedBox(width: 4),
              Text(job.eta, style: textTheme.bodySmall?.copyWith(color: colorScheme.outline)),
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
