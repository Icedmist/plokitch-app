import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPlokitchScreen extends StatefulWidget {
  const AboutPlokitchScreen({super.key});

  @override
  State<AboutPlokitchScreen> createState() => _AboutPlokitchScreenState();
}

class _AboutPlokitchScreenState extends State<AboutPlokitchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Track which card is tapped for ring effect
  int? _tappedCardIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onCardTap(int index) {
    setState(() => _tappedCardIndex = index);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _tappedCardIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // ── Top AppBar ──
              SliverAppBar(
                pinned: true,
                backgroundColor: cs.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: 48,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(Icons.menu, color: cs.primary, size: 28),
                ),
                leadingWidth: 52,
                title: Text(
                  '< Plokitch >',
                  style: GoogleFonts.lilitaOne(
                    fontSize: 28,
                    color: cs.primary,
                    letterSpacing: 0.02 * 28,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.shopping_cart, color: cs.primary, size: 28),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // ── Hero Section ──
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Hero Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 192,
                              width: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Background color
                                  Container(color: cs.secondary),
                                  // Background image
                                  Opacity(
                                    opacity: 0.6,
                                    child: Image.network(
                                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAQXNQAqJlSd_VBiszafmxieCwnGmSR109S71lF8pVAqUez4Vg4aFWNYfuu42A6NHwxolB841RtVWnauKHxpu-XIgYCvbVQjlT3GPbahUbxgkCT6hm9WImyd6MOzq9OthFsRSvlUWAjrHlsobz5_K4IJpFagHY7_731d8MzsQBWznz3WnVxFeD1WZiGi3nAaw2c_nRtqHE9bc3TDqkbvrMHs4GADZycKFITTyWnVBs7AheBF5vpXVMi2AwLkrEfrLn-r-BO393OT9MJ',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(color: cs.secondary),
                                    ),
                                  ),
                                  // Gradient overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          cs.secondary,
                                          cs.secondary.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Title
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    child: Text(
                                      'About Plokitch',
                                      style: GoogleFonts.lilitaOne(
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Description
                          Text(
                            'A community-driven kitchen network bringing authentic Northern flavors to your doorstep.',
                            style: GoogleFonts.lilitaOne(
                              fontSize: 16,
                              height: 1.5,
                              color: const Color(0xFF544434),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bento Grid ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Local Chefs Card (full width)
                      _BentoCard(
                        index: 0,
                        isTapped: _tappedCardIndex == 0,
                        onTap: () => _onCardTap(0),
                        primaryColor: cs.primaryContainer,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.secondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.restaurant,
                                  color: cs.onPrimaryContainer,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Local Chefs',
                                      style: GoogleFonts.lilitaOne(
                                        fontSize: 20,
                                        color: const Color(0xFFFFDCBD),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Empowering community talent to share traditional recipes.',
                                      style: GoogleFonts.lilitaOne(
                                        fontSize: 12,
                                        color: const Color(0xFFFFB59F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Fresh & Fast cards (side by side)
                      Row(
                        children: [
                          // Fresh Card
                          Expanded(
                            child: _BentoCard(
                              index: 1,
                              isTapped: _tappedCardIndex == 1,
                              onTap: () => _onCardTap(1),
                              primaryColor: cs.primaryContainer,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF74331F),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.outline.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.eco,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fresh',
                                      style: GoogleFonts.lilitaOne(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sourced daily from the Gombe central market.',
                                      style: GoogleFonts.lilitaOne(
                                        fontSize: 12,
                                        color: const Color(0xFFFFDBD1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Fast Card
                          Expanded(
                            child: _BentoCard(
                              index: 2,
                              isTapped: _tappedCardIndex == 2,
                              onTap: () => _onCardTap(2),
                              primaryColor: cs.primaryContainer,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.outline.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: cs.secondary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.moped,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fast',
                                      style: GoogleFonts.lilitaOne(
                                        fontSize: 20,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hyper-local riders who know every shortcut.',
                                      style: GoogleFonts.lilitaOne(
                                        fontSize: 12,
                                        color: cs.onPrimaryContainer
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Our Network Card (full width with bg image)
                      _BentoCard(
                        index: 3,
                        isTapped: _tappedCardIndex == 3,
                        onTap: () => _onCardTap(3),
                        primaryColor: cs.primaryContainer,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 128,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(color: cs.tertiary),
                                Opacity(
                                  opacity: 0.4,
                                  child: Image.network(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuB53jhv-PFSxYBGAsStKjwslb9w8ZzEhsMuV2N7F9Ba9ylfkLjWsRK4mB_f88Xg-icrT3anNT8IdL8sBhUijDeHKWEaHeVys9l4V7pNwKjh-tRwCJAe92jCECEhQGNRIcmQw4IjJ_EiHjRwGRhJxCBLgoDUvJ_e98uBH37Kmrj-_YXbwAj_ATX0T0O5gsvsnQMB5t19Pq-5BLxigD7YunfUUxinkngiJjePmm1JgtsVZiM6zFzDLxSk9vNwTdV0jHoHu462CEfIuCyi',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(color: cs.tertiary),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Our Network',
                                        style: GoogleFonts.lilitaOne(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Connecting 50+ local kitchens to your table.',
                                        style: GoogleFonts.lilitaOne(
                                          fontSize: 12,
                                          color: const Color(0xFFFDDCCC),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Bottom padding to avoid overlap with bottom bar
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom Navigation (Skip / Next) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: cs.surface,
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Skip button
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 44,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/onboarding');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF544434),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.lilitaOne(
                              fontSize: 14,
                              letterSpacing: 0.05 * 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Next button
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/onboarding');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primaryContainer,
                            foregroundColor: cs.onPrimaryContainer,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Next',
                                style: GoogleFonts.lilitaOne(
                                  fontSize: 14,
                                  letterSpacing: 0.05 * 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bento card with tap-to-ring micro-interaction
class _BentoCard extends StatelessWidget {
  final int index;
  final bool isTapped;
  final VoidCallback onTap;
  final Color primaryColor;
  final Widget child;

  const _BentoCard({
    required this.index,
    required this.isTapped,
    required this.onTap,
    required this.primaryColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.elasticOut,
        transform: Matrix4.diagonal3Values(
          isTapped ? 0.96 : 1.0,
          isTapped ? 0.96 : 1.0,
          1.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: isTapped
              ? Border.all(color: primaryColor, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: child,
      ),
    );
  }
}
