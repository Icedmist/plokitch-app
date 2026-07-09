import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // ─── Bracket animations ────────────────────────────────────────────────────
  late AnimationController _bracketController;
  late Animation<double> _leftBracketSlide;
  late Animation<double> _rightBracketSlide;
  late Animation<double> _bracketFade;

  // ─── Typewriter ────────────────────────────────────────────────────────────
  late AnimationController _wordController;
  late Animation<double> _wordFade;
  String _displayed = '';
  final String _full = 'Plokitch';
  Timer? _typeTimer;
  int _typeIndex = 0;

  // ─── Subtitle + nav ────────────────────────────────────────────────────────
  late AnimationController _subController;
  late Animation<double> _subFade;

  @override
  void initState() {
    super.initState();

    // 1. Brackets slide in from sides and fade in
    _bracketController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _leftBracketSlide = Tween<double>(begin: -80, end: 0).animate(
      CurvedAnimation(parent: _bracketController, curve: Curves.easeOutCubic),
    );
    _rightBracketSlide = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(parent: _bracketController, curve: Curves.easeOutCubic),
    );
    _bracketFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bracketController, curve: Curves.easeIn),
    );

    // 2. Word fade-in controller (just for the word container opacity)
    _wordController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _wordFade = Tween<double>(begin: 0, end: 1).animate(_wordController);

    // 3. Subtitle
    _subController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _subFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  void _startSequence() async {
    // Check if user is already signed in
    try {
      final storedRole = await AuthService.storedRole();
      if (storedRole != null && storedRole.isNotEmpty) {
        // User is already logged in, skip welcome animation
        if (mounted) {
          _navigateToRoleHome(storedRole);
        }
        return;
      }
    } catch (_) {}

    // User is not signed in, show welcome animation
    // Step 1: animate brackets in
    await _bracketController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Step 2: start typewriter for "Plokitch"
    _wordController.forward();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 110), (t) {
      if (_typeIndex < _full.length) {
        setState(() {
          _displayed = _full.substring(0, _typeIndex + 1);
          _typeIndex++;
        });
      } else {
        t.cancel();
        _onTypewriterDone();
      }
    });
  }

  void _navigateToRoleHome(String role) {
    if (!mounted) return;
    final route = role.toLowerCase() == 'chef'
        ? '/chef-dashboard'
        : role.toLowerCase() == 'rider'
            ? '/rider-dashboard'
            : '/home';
    Navigator.pushReplacementNamed(context, route);
  }

  void _onTypewriterDone() async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _subController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/sign-in');
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _bracketController.dispose();
    _wordController.dispose();
    _subController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const bracketStyle = TextStyle(
      fontSize: 128,
      fontWeight: FontWeight.w900,
      height: 1.0,
      letterSpacing: -6,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo row ──────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _bracketController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _bracketFade.value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left bracket (slides from left)
                        Transform.translate(
                          offset: Offset(_leftBracketSlide.value, 0),
                          child: Text(
                            '<',
                            style: bracketStyle.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),

                        // Typewriter word in the middle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: FadeTransition(
                            opacity: _wordFade,
                            child: Text(
                              _displayed,
                              style: textTheme.displayMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.5,
                              ),
                            ),
                          ),
                        ),

                        // Right bracket (slides from right)
                        Transform.translate(
                          offset: Offset(_rightBracketSlide.value, 0),
                          child: Text(
                            '>',
                            style: bracketStyle.copyWith(
                              color: colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── Subtitle ──────────────────────────────────────────────────
              FadeTransition(
                opacity: _subFade,
                child: Text(
                  'Your culinary ecosystem',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ── Pulsing dot loader while waiting ─────────────────────────
              FadeTransition(
                opacity: _subFade,
                child: _PulsingDots(color: colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three bouncing dots shown while the app transitions
class _PulsingDots extends StatefulWidget {
  final Color color;
  const _PulsingDots({required this.color});

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final delay = i * 0.3;
            final t = ((_c.value - delay).clamp(0.0, 1.0));
            final opacity = Curves.easeInOut.transform(t);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: 0.3 + opacity * 0.7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
