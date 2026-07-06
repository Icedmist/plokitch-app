import 'package:flutter/material.dart';
import '../widgets/plokitch_bottom_nav.dart';

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  bool _isSheetExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Map Pins (Simulated)
          Positioned(
            top: 200,
            left: 100,
            child: _buildMapPin('Masa', colorScheme, textTheme),
          ),
          Positioned(
            top: 350,
            right: 80,
            child: _buildMapPin('Suya', colorScheme, textTheme, isSelected: true),
          ),
          Positioned(
            top: 150,
            right: 150,
            child: _buildMapPin('Jollof', colorScheme, textTheme),
          ),
          
          // 3. Floating Search & Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.menu, color: colorScheme.primary),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for Tuwo, Masa...',
                          hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: Icon(Icons.shopping_cart, color: colorScheme.primary),
                          onPressed: () {
                            Navigator.pushNamed(context, '/cart');
                          },
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Floating Action Buttons (My Location, Layers)
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.45,
            child: Column(
              children: [
                _buildFloatingIcon(Icons.layers, colorScheme),
                const SizedBox(height: 12),
                _buildFloatingIcon(Icons.my_location, colorScheme),
              ],
            ),
          ),
          
          // 4. Draggable Bottom Sheet (Bento Grid)
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() {
                _isSheetExpanded = notification.extent > 0.45;
              });
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.15,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [0.4, 0.85],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5)),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nearby Kitchens',
                        style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      
                      // Bento Grid Layout
                      _buildBentoGrid(colorScheme, textTheme),
                      
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: PlokitchBottomNav(
        currentIndex: 0, // Home
        onTap: (index) {
          if (index == 1) {
            // Market/Kitchen Management depending on role
            Navigator.pushReplacementNamed(context, '/kitchen');
          }
          if (index == 2) Navigator.pushReplacementNamed(context, '/tracking');
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildMapPin(String label, ColorScheme colorScheme, TextTheme textTheme, {bool isSelected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? colorScheme.primaryContainer.withOpacity(0.4) : Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.star, size: 12, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 4),
              ],
              Text(
                isSelected ? '< $label >' : label,
                style: textTheme.labelLarge?.copyWith(
                  color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingIcon(IconData icon, ColorScheme colorScheme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: colorScheme.onSurfaceVariant),
        onPressed: () {},
      ),
    );
  }

  Widget _buildBentoGrid(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        // Full Width Hero Card
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/cart'),
          child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF642714), // warmBrown
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1555939594-58d7cb561ad1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'), // Suya image
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('TOP RATED', style: textTheme.labelSmall?.copyWith(color: colorScheme.onPrimaryContainer)),
                ),
                const SizedBox(height: 8),
                Text('< Hajiya\'s Suya Spot >', style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('4.9 (120 reviews) • 1.2km', style: textTheme.bodySmall?.copyWith(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Two smaller cards in a row
        Row(
          children: [
            Expanded(
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                          image: DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1604328698692-f76ea9498e76?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Binta\'s Masa', style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('15 mins away', style: textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/cart'),
                child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                          image: DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1574484284002-952d92456975?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mama Jollof', style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('25 mins away', style: textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        // Promo Banner
        if (_isSheetExpanded)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.local_fire_department, color: colorScheme.primaryContainer, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Free Delivery Today!', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                      Text('On all orders above ₦5000', style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
