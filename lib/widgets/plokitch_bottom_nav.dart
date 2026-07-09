import 'package:flutter/material.dart';

class PlokitchBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// 'foodie' | 'chef' | 'rider'
  final String role;

  const PlokitchBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = 'foodie',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Tabs differ per role
    final List<_NavItem> items = _itemsForRole(role);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              return _buildNavItem(
                context: context,
                index: e.key,
                item: e.value,
                colorScheme: colorScheme,
                textTheme: textTheme,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<_NavItem> _itemsForRole(String role) {
    switch (role) {
      case 'chef':
        return const [
          _NavItem(Icons.home, 'Home'),
          _NavItem(Icons.restaurant, 'Kitchen'),
          _NavItem(Icons.receipt_long, 'Orders'),
          _NavItem(Icons.person, 'Profile'),
        ];
      case 'rider':
        return const [
          _NavItem(Icons.home, 'Home'),
          _NavItem(Icons.storefront, 'Market'),
          _NavItem(Icons.receipt_long, 'Orders'),
          _NavItem(Icons.person, 'Profile'),
        ];
      default: // foodie
        return const [
          _NavItem(Icons.home, 'Home'),
          _NavItem(Icons.storefront, 'Market'),
          _NavItem(Icons.receipt_long, 'Orders'),
          _NavItem(Icons.person, 'Profile'),
        ];
    }
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required _NavItem item,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
