import 'package:flutter/material.dart';

class PlokitchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showMenu;
  final bool showCart;
  final bool showAvatar;
  final bool showNotificationIcon;
  final String? avatarUrl;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onCartPressed;
  final VoidCallback? onAvatarPressed;
  final VoidCallback? onNotificationPressed;

  const PlokitchAppBar({
    super.key,
    this.title = 'Plokitch',
    this.showMenu = true,
    this.showCart = false,
    this.showAvatar = false,
    this.showNotificationIcon = false,
    this.avatarUrl,
    this.onMenuPressed,
    this.onCartPressed,
    this.onAvatarPressed,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      leading: showMenu
          ? IconButton(
              icon: Icon(Icons.menu, color: colorScheme.primary),
              onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
            )
          : null,
      title: Text(
        '< ${title ?? 'Plokitch'} >',
        style: textTheme.headlineLarge?.copyWith(
          color: colorScheme.primary,
        ),
      ),
      actions: [
        if (showNotificationIcon)
          IconButton(
            icon: Icon(Icons.notifications_none, color: colorScheme.primary),
            onPressed: onNotificationPressed,
          ),
        if (showCart)
          IconButton(
            icon: Icon(Icons.shopping_cart, color: colorScheme.primary),
            onPressed: onCartPressed,
          ),
        if (showAvatar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: onAvatarPressed,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.secondaryContainer,
                  border: Border.all(
                    color: colorScheme.primaryContainer,
                    width: 2,
                  ),
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 20, color: colorScheme.onSecondaryContainer)
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
