import 'package:flutter/material.dart';
import '../widgets/plokitch_bottom_nav.dart';

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  bool _isSheetExpanded = false;
  String _locationLabel = 'Gombe, Gombe State';

  // Gombe State city center approx coords: 10.2896° N, 11.1679° E
  // We use a static satellite-style map of Gombe as background.
  static const _gombeMapUrl =
      'https://images.unsplash.com/photo-1524661135-423995f22d0b'
      '?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80';

  @override
  void initState() {
    super.initState();
  }

  void _refreshLocation() {
    setState(() {
      _locationLabel = 'Gombe, Gombe State';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. Gombe State Map Background ──────────────────────────────
          Positioned.fill(
            child: Image.network(
              _gombeMapUrl,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: colorScheme.surfaceContainerLow,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),

          // Gombe overlay tint
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),

          // ── 2. Map Pins ─────────────────────────────────────────────────
          Positioned(
            top: 220,
            left: 90,
            child: _buildMapPin('Masa', colorScheme, textTheme),
          ),
          Positioned(
            top: 360,
            right: 70,
            child: _buildMapPin('Suya', colorScheme, textTheme, isSelected: true),
          ),
          Positioned(
            top: 160,
            right: 130,
            child: _buildMapPin('Jollof', colorScheme, textTheme),
          ),
          Positioned(
            top: 300,
            left: 160,
            child: _buildMapPin('Tuwo', colorScheme, textTheme),
          ),

          // ── 3. Top Bar ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Menu button
                      _floatingCircle(
                        child: IconButton(
                          icon: Icon(Icons.menu, color: colorScheme.primary),
                          onPressed: () {},
                        ),
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 12),
                      // Search bar
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search Tuwo, Masa, Suya…',
                              hintStyle: textTheme.bodyMedium
                                  ?.copyWith(color: colorScheme.outline),
                              prefixIcon:
                                  Icon(Icons.search, color: colorScheme.primary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Cart button
                      _floatingCircle(
                        colorScheme: colorScheme,
                        child: Stack(
                          children: [
                            IconButton(
                              icon: Icon(Icons.shopping_cart,
                                  color: colorScheme.primary),
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/cart'),
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
                                  border: Border.all(
                                      color: colorScheme.surface, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Location Banner ──────────────────────────────────────
                  GestureDetector(
                    onTap: _refreshLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on,
                              color: colorScheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _locationLabel,
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.refresh,
                              size: 14, color: colorScheme.outline),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. FABs ────────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.45,
            child: Column(
              children: [
                _buildFloatingIcon(Icons.layers, colorScheme),
                const SizedBox(height: 12),
                _buildFloatingIcon(Icons.my_location, colorScheme,
                    onTap: _fetchLocation),
              ],
            ),
          ),

          // ── 5. Draggable Bottom Sheet ───────────────────────────────────
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (n) {
              setState(() => _isSheetExpanded = n.extent > 0.45);
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
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nearby Kitchens',
                            style: textTheme.headlineMedium
                                ?.copyWith(color: colorScheme.primary),
                          ),
                          // Notifications shortcut
                          IconButton(
                            icon: Icon(Icons.notifications_none,
                                color: colorScheme.onSurfaceVariant),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/notifications'),
                            tooltip: 'Notifications',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildBentoGrid(colorScheme, textTheme, context),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: PlokitchBottomNav(
        role: 'foodie',
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/market');
          if (index == 2) Navigator.pushReplacementNamed(context, '/order-history');
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _floatingCircle({
    required Widget child,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMapPin(
    String label,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool isSelected = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                isSelected ? colorScheme.primaryContainer : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                    : Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.star,
                    size: 12, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 4),
              ],
              Text(
                isSelected ? '< $label >' : label,
                style: textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
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

  Widget _buildFloatingIcon(IconData icon, ColorScheme colorScheme,
      {VoidCallback? onTap}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: colorScheme.onSurfaceVariant),
        onPressed: onTap ?? () {},
      ),
    );
  }

  Widget _buildBentoGrid(
      ColorScheme colorScheme, TextTheme textTheme, BuildContext context) {
    return Column(
      children: [
        // Hero card
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/cart'),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF642714),
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1'
                    '?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'),
                fit: BoxFit.cover,
                colorFilter:
                    ColorFilter.mode(Colors.black45, BlendMode.darken),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('TOP RATED',
                        style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer)),
                  ),
                  const SizedBox(height: 8),
                  Text('Hajiya\'s Suya Spot',
                      style: textTheme.headlineSmall
                          ?.copyWith(color: Colors.white)),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('4.9 (120 reviews) · 1.2km',
                          style: textTheme.bodySmall
                              ?.copyWith(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Two cards row
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/cart'),
                child: _buildKitchenCard(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  imageUrl:
                      'https://images.unsplash.com/photo-1604328698692-f76ea9498e76'
                      '?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
                  name: 'Binta\'s Masa',
                  eta: '15 mins',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/cart'),
                child: _buildKitchenCard(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  imageUrl:
                      'https://images.unsplash.com/photo-1574484284002-952d92456975'
                      '?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
                  name: 'Mama Jollof',
                  eta: '25 mins',
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Promo banner (only when expanded)
        if (_isSheetExpanded)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: colorScheme.primaryContainer, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Free Delivery Today!',
                          style: textTheme.titleMedium
                              ?.copyWith(color: Colors.white)),
                      Text('On all orders above ₦5,000',
                          style: textTheme.bodySmall
                              ?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildKitchenCard({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String imageUrl,
    required String name,
    required String eta,
  }) {
    return Container(
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
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(eta,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
