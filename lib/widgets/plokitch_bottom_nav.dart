import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      ),
    );
  }

  List<_NavItem> _itemsForRole(String role) {
    switch (role) {
      case 'chef':
        return const [
          _NavItem(Icons.home_outlined, Icons.home, 'Home'),
          _NavItem(Icons.restaurant_outlined, Icons.restaurant, 'Kitchen'),
          _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
          _NavItem(Icons.person_outline, Icons.person, 'Profile'),
        ];
      case 'rider':
        return const [
          _NavItem(Icons.home_outlined, Icons.home, 'Home'),
          _NavItem(Icons.storefront_outlined, Icons.storefront, 'Market'),
          _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
          _NavItem(Icons.person_outline, Icons.person, 'Profile'),
        ];
      default: // foodie
        return const [
          _NavItem(Icons.home_outlined, Icons.home, 'Home'),
          _NavItem(Icons.storefront_outlined, Icons.storefront, 'Market'),
          _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
          _NavItem(Icons.person_outline, Icons.person, 'Profile'),
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
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 20,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
