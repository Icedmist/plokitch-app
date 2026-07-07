import 'package:flutter/material.dart';

class PlokitchButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isFullWidth;
  final IconData? icon;

  const PlokitchButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  State<PlokitchButton> createState() => _PlokitchButtonState();
}

class _PlokitchButtonState extends State<PlokitchButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
        onTapDown: (_) {
          if (widget.onPressed != null) _controller.forward();
        },
        onTapUp: (_) {
          if (widget.onPressed != null) {
            _controller.reverse();
            widget.onPressed!();
          }
        },
        onTapCancel: () {
          if (widget.onPressed != null) _controller.reverse();
        },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          height: 48, // Reduced from 56
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? colorScheme.onSurface.withOpacity(0.12)
                : (widget.isOutlined ? Colors.transparent : colorScheme.primaryContainer),
            border: widget.isOutlined ? Border.all(color: colorScheme.primary, width: 2) : null,
            borderRadius: BorderRadius.circular(12), // Reduced from 16
            boxShadow: widget.isOutlined
                ? []
                : [
                    BoxShadow(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: widget.isOutlined ? colorScheme.primary : colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text.toUpperCase(),
                style: textTheme.labelLarge?.copyWith(
                  color: widget.onPressed == null
                      ? colorScheme.onSurface
                      : (widget.isOutlined ? colorScheme.primary : colorScheme.onPrimaryContainer),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
