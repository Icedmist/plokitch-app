import 'dart:math' as math;
import 'package:flutter/material.dart';

class PlokitchCookingLoader extends StatefulWidget {
  final double scale;
  final String? loadingText;

  const PlokitchCookingLoader({
    super.key,
    this.scale = 1.0,
    this.loadingText,
  });

  @override
  State<PlokitchCookingLoader> createState() => _PlokitchCookingLoaderState();
}

class _PlokitchCookingLoaderState extends State<PlokitchCookingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = _controller.value; // 0.0 to 1.0

            // 1. Pan rotation (cooking animation)
            double panRotation = 0.0;
            if (value <= 0.1) {
              panRotation = math.pi / 180 * (-4.0 * (value / 0.1));
            } else if (value <= 0.5) {
              final t = (value - 0.1) / 0.4;
              panRotation = math.pi / 180 * (-4.0 + 24.0 * t);
            } else {
              final t = (value - 0.5) / 0.5;
              panRotation = math.pi / 180 * (20.0 * (1.0 - t));
            }

            // 2. Food flip (translation & rotation)
            double foodTranslateY = 0.0;
            double foodRotation = 0.0;
            if (value <= 0.5) {
              final t = value / 0.5;
              foodTranslateY = -85.0 * math.sin(t * math.pi / 2);
              foodRotation = math.pi * t;
            } else {
              final t = (value - 0.5) / 0.5;
              foodTranslateY = -85.0 * math.cos(t * math.pi / 2);
              foodRotation = math.pi + (math.pi * t);
            }

            // 3. Shadow scale
            double shadowScale = 0.7 + 0.3 * math.sin(value * math.pi);

            return Transform.scale(
              scale: widget.scale,
              child: SizedBox(
                width: 170,
                height: 130,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // ── Pan Shadow ──
                    Positioned(
                      bottom: 6,
                      left: 30,
                      child: Transform.scale(
                        scaleX: shadowScale,
                        child: Container(
                          width: 70,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Pan & Food Group ──
                    Positioned(
                      bottom: 18,
                      left: 10,
                      right: 10,
                      child: Transform(
                        alignment: Alignment.topRight,
                        transform: Matrix4.identity()..rotateZ(panRotation),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            // ── Flying Food ──
                            Positioned(
                              left: 10,
                              top: -4,
                              child: Transform(
                                transform: Matrix4.translationValues(0.0, foodTranslateY, 0.0)
                                  ..rotateZ(foodRotation),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 56,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF642714),
                                        Color(0xFFFDA186),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // ── Pan Base & Handle ──
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Pan Base (Cookware bowl)
                                Container(
                                  width: 75,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(40),
                                      bottomRight: Radius.circular(40),
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primaryContainer,
                                        colorScheme.primary,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                // Pan Handle
                                Container(
                                  width: 60,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1E1E1E),
                                        Color(0xFF4A4A4A),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.loadingText != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.loadingText!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
