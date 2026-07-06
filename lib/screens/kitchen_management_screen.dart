import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';

class KitchenManagementScreen extends StatefulWidget {
  const KitchenManagementScreen({super.key});

  @override
  State<KitchenManagementScreen> createState() => _KitchenManagementScreenState();
}

class _KitchenManagementScreenState extends State<KitchenManagementScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pingController;

  final List<Map<String, dynamic>> _menuItems = [
    {
      'name': 'Classic Masa (6pcs)',
      'price': '₦1,200',
      'available': true,
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDVN2CwshbbQfVJHccjrnMbdxLfPsr1LIyt725dmgzQOtqQPo6m11AaZuiRjyNuqSSa_t-D-OfV2O50JDC4he7a3yDpKtHXBstfYdsdkl-PnrxgPCIeVy21BDEBgvw1oTzIqJTmhgdSqC6-9nKAVMvHJ98JN3uIRnJ67WhyUsKD_13t8XJRQLCNT1f-QpAXwpm1jbrBQ8B5p76IwMgPoZ4pLTFZf6lz19M6NWb_Km5a1ngU_5PymmiDDCCt8z0ODNIhchpB2-OK1pyA',
    },
    {
      'name': 'Party Jollof & Chicken',
      'price': '₦2,500',
      'available': true,
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAX014lLz2WhK25mjpA6GhhujNyL5xnKGInUBu6vmdwagzzcorrS4oQZUB2yjTox3bQxJWWnHI_C7_v6x2HWE7DLXKQk9xrVJ8OI_MGDoVKmFEeCpzlvCVCXuij3GRAUmFWdD4LJn632srVvsQQLwCBNMezurSsMcXxmtRUDOWgviuEPpZx8mwpQ0spLiWtFJL1kHA2oIPv8w6AOo6dkJ9Oaonr2W7rutytfWPFuYh-9hpBnEQ-nFY3E83N2OYNZcsBJtzLV7GdeiNM',
    },
    {
      'name': 'Tuwon Shinkafa & Kuka',
      'price': '₦1,800',
      'available': false,
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBq5jdOS8SfeQaPQsrDxH8LZjUCfTE4VAePEJEH7zZ6uAKRJp3X3-h3syePxTgarBoDbBXQXT0UtI7XtYDYRnIef7tMIIyO8fDUJWM9NsKo2KDvyM0hFZOz2AeGUlY_CGElT75xzxK8TvebkUTLo8cC-p4jFrcUbyXl9jw59gk7mU9HER_FLdIHQK24mr_yawcYd-3bJyftURE9ifXSyKKBAI2LU-U2mY6_WOnUg0l8fi6Pee-3nXJuImQb5tnB3pzMSYzbP5XE2Pki',
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: PlokitchAppBar(
        title: 'Kitchen Mgmt',
        showMenu: true,
        showAvatar: true,
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuASvReuM8euOL57t6mWmPxr3h6y4r3a3b5b4xMw5h2z0pInZB-HUyzdsRtJEb8A3SEBcw8fhBdOREPoBD2SSqAXnODQM67EKQDmLvYi71hcF5ztS39bivwtYWRapwmesl0kUMmzRjGqSKu_ohCMiAx5pb2pMn-mCbIra-KcTCNkTlCKVgXLf4riBkPkwkuUTR9IQ_JO1LQTv9wZWoZci9x05jS2nximauJF5qYcgyZt9s7jZe2UEUWI3ouguSbNcEO-7yCXSHgil2ud',
      ),
      body: ListView(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.black,
            child: Row(
              children: [
                Icon(Icons.campaign, color: colorScheme.primaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'RAMADAN SPECIAL: UPDATE YOUR EVENING MENU BY 4PM DAILY!',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.close, color: Colors.white, size: 16),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kitchen Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kitchen Status', style: textTheme.headlineMedium?.copyWith(color: Colors.white)),
                          Text('Visible to customers', style: textTheme.bodySmall?.copyWith(color: const Color(0xFFFFB59F))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF74331F), // on-secondary-fixed-variant approx
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                FadeTransition(
                                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_pingController),
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 1.0, end: 2.5).animate(_pingController),
                                    child: Container(
                                      width: 12, height: 12,
                                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 12, height: 12,
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text('ONLINE', style: textTheme.labelLarge?.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Analytics Bento Summary
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 140,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF642714), // warmBrown
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.trending_up, color: colorScheme.primaryContainer, size: 32),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('42', style: textTheme.headlineLarge?.copyWith(color: colorScheme.primaryContainer)),
                                Text('ORDERS TODAY', style: textTheme.labelLarge?.copyWith(color: const Color(0xFFFDDCCC), fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 140,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF642714),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('RATING', style: textTheme.labelLarge?.copyWith(color: const Color(0xFFFDDCCC), fontSize: 10)),
                                        Text('4.9', style: textTheme.headlineMedium?.copyWith(color: colorScheme.primaryContainer)),
                                      ],
                                    ),
                                    Icon(Icons.star, color: colorScheme.primaryContainer),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('EARNED', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer, fontSize: 10)),
                                        Text('₦12.5k', style: textTheme.headlineMedium?.copyWith(color: colorScheme.onPrimaryContainer)),
                                      ],
                                    ),
                                    Icon(Icons.payments, color: colorScheme.onPrimaryContainer),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Current Menu Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Menu', style: textTheme.headlineMedium?.copyWith(color: colorScheme.secondary)),
                    Text('Manage All', style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary, 
                      decoration: TextDecoration.underline,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Menu List
                ..._menuItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildMenuItem(index, item, colorScheme, textTheme);
                }),
                
                const SizedBox(height: 24),
                // Kitchen Tasks Prompt
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/chef-dashboard');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.restaurant_menu, color: colorScheme.onPrimaryContainer),
                            const SizedBox(width: 12),
                            Text('New Orders (3)', style: textTheme.headlineMedium?.copyWith(color: colorScheme.onPrimaryContainer)),
                          ],
                        ),
                        Icon(Icons.chevron_right, color: colorScheme.onPrimaryContainer),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: PlokitchBottomNav(
        currentIndex: 1, // Menu active
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/chef-dashboard'); // Map/Home equivalent
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildMenuItem(int index, Map<String, dynamic> item, ColorScheme colorScheme, TextTheme textTheme) {
    final isAvailable = item['available'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF642714).withOpacity(isAvailable ? 1.0 : 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(item['image']),
                fit: BoxFit.cover,
                colorFilter: isAvailable ? null : const ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]), // Grayscale effect
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: textTheme.bodyLarge?.copyWith(color: Colors.white)),
                Text(item['price'], style: textTheme.bodySmall?.copyWith(color: const Color(0xFFFDDCCC))),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (value) {
              setState(() {
                _menuItems[index]['available'] = value;
              });
            },
            activeColor: colorScheme.primaryContainer,
            activeTrackColor: colorScheme.primaryContainer.withOpacity(0.5),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}
