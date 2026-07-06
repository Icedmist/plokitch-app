import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';

class ChefDashboardScreen extends StatefulWidget {
  const ChefDashboardScreen({super.key});

  @override
  State<ChefDashboardScreen> createState() => _ChefDashboardScreenState();
}

class _ChefDashboardScreenState extends State<ChefDashboardScreen> {
  final List<Map<String, dynamic>> _orders = [
    {
      'id': '#PK-204',
      'time': '12:45 PM',
      'name': 'Masa & Miyan Taushe',
      'customer': 'Amina Yusuf',
      'status': 'new', // new, cooking
    },
    {
      'id': '#PK-198',
      'time': '12:30 PM',
      'name': 'Tuwon Shinkafa & Begedi',
      'customer': 'Musa Ibrahim',
      'status': 'cooking',
    },
    {
      'id': '#PK-210',
      'time': '1:02 PM',
      'name': 'Jollof Rice Feast (x2)',
      'customer': 'Chioma Obi',
      'status': 'new',
    },
    {
      'id': '#PK-185',
      'time': '15m late',
      'name': 'Pounded Yam & Egusi',
      'customer': 'Bello Garba',
      'status': 'urgent',
    },
  ];

  void _handleAction(int index) {
    setState(() {
      if (_orders[index]['status'] == 'new' || _orders[index]['status'] == 'urgent') {
        _orders[index]['status'] = 'cooking';
      } else if (_orders[index]['status'] == 'cooking') {
        _orders.removeAt(index);
      }
    });
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
          if (index == 0) Navigator.pushReplacementNamed(context, '/chef-dashboard');
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

  Widget _buildOrderCard(int index, Map<String, dynamic> order, ColorScheme colorScheme, TextTheme textTheme) {
    final status = order['status'];
    final isUrgent = status == 'urgent';
    final isCooking = status == 'cooking';
    
    Color leftBorderColor = colorScheme.primaryContainer;
    if (isUrgent) leftBorderColor = colorScheme.error;
    if (isCooking) leftBorderColor = colorScheme.secondaryContainer;

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
                  isUrgent ? 'URGENT ${order['id']}' : order['id'],
                  style: textTheme.labelSmall?.copyWith(
                    color: isUrgent ? colorScheme.onError : (isCooking ? colorScheme.onSecondaryContainer : const Color(0xFF642714)),
                  ),
                ),
              ),
              Text(
                order['time'],
                style: textTheme.bodySmall?.copyWith(
                  color: isUrgent ? colorScheme.errorContainer : Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order['name'],
            style: textTheme.headlineMedium?.copyWith(color: const Color(0xFFFFB86D)), // primary-fixed-dim
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: textTheme.bodyMedium?.copyWith(color: isUrgent ? colorScheme.errorContainer : Colors.white70),
              children: [
                const TextSpan(text: 'Customer: '),
                TextSpan(text: order['customer'], style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleAction(index),
                  icon: Icon(isCooking ? Icons.check_circle : Icons.restaurant, size: 18),
                  label: Text(isCooking ? 'MARK AS READY' : 'START COOKING'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCooking ? colorScheme.tertiaryContainer : colorScheme.primaryContainer,
                    foregroundColor: isCooking ? colorScheme.onTertiaryContainer : colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    textStyle: textTheme.labelLarge,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!isUrgent)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(isCooking ? Icons.timer : Icons.more_vert, color: colorScheme.surfaceContainerHigh),
                    onPressed: () {},
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
