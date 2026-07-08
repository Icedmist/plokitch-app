import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/menu_item_model.dart';

class KitchenManagementScreen extends StatefulWidget {
  const KitchenManagementScreen({super.key});

  @override
  State<KitchenManagementScreen> createState() => _KitchenManagementScreenState();
}

class _KitchenManagementScreenState extends State<KitchenManagementScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pingController;
  List<MenuItemModel> _menuItems = [];
  bool _loading = true;
  String? _error;
  String? _vendorId;

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadKitchenData();
  }

  Future<void> _loadKitchenData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await AuthService.getProfile();
      _vendorId = profile?['vendorId'] ?? profile?['vendor_id'] ?? profile?['id'];
      
      if (_vendorId != null) {
        final menu = await ApiService.fetchVendorMenu(_vendorId!);
        if (mounted) {
          setState(() {
            _menuItems = menu.cast<MenuItemModel>();
          });
        }
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
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(child: Text('Error: $_error'))
                else if (_menuItems.isEmpty)
                  const Center(child: Text('No menu items found'))
                else
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

  Widget _buildMenuItem(int index, MenuItemModel item, ColorScheme colorScheme, TextTheme textTheme) {
    // Backend doesn't have 'available' field in model yet, assuming true for now
    const isAvailable = true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF642714).withValues(alpha: isAvailable ? 1.0 : 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: item.imageUrl != null ? DecorationImage(
                image: NetworkImage(item.imageUrl!),
                fit: BoxFit.cover,
              ) : null,
              color: Colors.grey,
            ),
            child: item.imageUrl == null ? const Icon(Icons.fastfood, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: textTheme.bodyLarge?.copyWith(color: Colors.white)),
                Text('₦${item.price.toStringAsFixed(2)}', style: textTheme.bodySmall?.copyWith(color: const Color(0xFFFDDCCC))),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (value) {
              // Status update not implemented yet
            },
            activeColor: colorScheme.primaryContainer,
            activeTrackColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}
