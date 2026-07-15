import 'package:flutter/material.dart';

class PlokitchBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const PlokitchBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          color: colorScheme.primary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onPressed ?? () => Navigator.maybePop(context),
        ),
      ),
    );
  }
}
