import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // 0: Placed, 1: Cooking, 2: Picked Up, 3: Arriving
  final int _currentStatus = 1; 

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Track Order',
        showMenu: false,
      ),
      body: Stack(
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
                    color: const Color(0xFF35301D), // inverseSurface
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    'Rider En Route — 12 mins',
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
                  color: Color(0xFF35301D), // inverseSurface
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
                        Text('Order #PK-8249', style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.primaryContainer),
                          ),
                          child: Text(
                            '12:45 PM',
                            style: textTheme.labelLarge?.copyWith(color: colorScheme.primaryContainer),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Tracking Progress
                    _buildTrackingStep('Order Placed', '12:30 PM', true, false, colorScheme, textTheme),
                    _buildTrackingStep('Chef Cooking', 'In Progress...', true, true, colorScheme, textTheme),
                    _buildTrackingStep('Rider Picked Up', 'Pending', false, false, colorScheme, textTheme),
                    _buildTrackingStep('Arriving Soon', 'Pending', false, false, colorScheme, textTheme, isLast: true),
                    
                    const Divider(color: Colors.white24, height: 48),
                    
                    // Order Summary
                    Text('Order Details', style: textTheme.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 16),
                    _buildOrderLine('Jollof Rice Feast (x2)', '₦9,000', textTheme),
                    const SizedBox(height: 8),
                    _buildOrderLine('Suya Platter (x1)', '₦7,200', textTheme),
                    const SizedBox(height: 8),
                    _buildOrderLine('Delivery Fee', '₦800', textTheme),
                    const SizedBox(height: 16),
                    _buildOrderLine('Total Paid', '₦17,000', textTheme, isTotal: true, colorScheme: colorScheme),
                    
                    const Divider(color: Colors.white24, height: 48),
                    
                    // Rider Card
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
                            backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80'),
                            backgroundColor: colorScheme.surface,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Musa Ibrahim', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: colorScheme.primaryContainer, size: 16),
                                    const SizedBox(width: 4),
                                    Text('4.9 Rating', style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                                    const SizedBox(width: 8),
                                    Text('•', style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                                    const SizedBox(width: 8),
                                    Text('K-JE 324', style: textTheme.labelLarge?.copyWith(color: Colors.white)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.call, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: PlokitchBottomNav(
        currentIndex: 2, // Orders
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/home');
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
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
                  ? const Icon(Icons.check, size: 16, color: Color(0xFF663B00)) // onPrimaryContainer
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
