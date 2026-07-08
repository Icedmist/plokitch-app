import 'package:flutter/material.dart';
import '../../widgets/plokitch_button.dart';

class FirstActionPage extends StatelessWidget {
  final String role;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const FirstActionPage({
    super.key,
    required this.role,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isChef = role == 'chef';

    return Stack(
      children: [
        // Fun Background Gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerHigh,
                  colorScheme.secondaryContainer.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: onBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Text(
                  'You\'re all set!',
                  style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  isChef 
                      ? 'Let\'s set up your kitchen and start selling.'
                      : 'Time to discover the best local flavors.',
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 48),
                
                // Hero Image (Role Dependent)
                Center(
                  child: Container(
                    height: 240,
                    width: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 8,
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(
                          isChef
                              ? 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80' // Chef
                              : 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', // Food
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                PlokitchButton(
                  text: isChef ? 'Create Your First Product' : 'Make Your First Order',
                  icon: isChef ? Icons.add_circle_outline : Icons.shopping_bag_outlined,
                  onPressed: onNext,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
