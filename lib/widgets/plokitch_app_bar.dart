import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PlokitchAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  final bool automaticallyImplyLeading;

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
    this.automaticallyImplyLeading = true,
  });

  @override
  State<PlokitchAppBar> createState() => _PlokitchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _PlokitchAppBarState extends State<PlokitchAppBar> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.showNotificationIcon) {
      _loadUnreadCount();
    }
  }

  @override
  void didUpdateWidget(covariant PlokitchAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showNotificationIcon) {
      _loadUnreadCount();
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final profile = await AuthService.getProfile();
      if (profile != null) {
        final data = profile['notifications'] as List<dynamic>? ?? 
            profile['notifications_list'] as List<dynamic>?;
        if (data != null) {
          int count = 0;
          for (final entry in data) {
            final map = Map<String, dynamic>.from(entry as Map);
            final isRead = map['isRead'] as bool? ?? map['read'] as bool? ?? false;
            if (!isRead) {
              count++;
            }
          }
          if (mounted) {
            setState(() {
              _unreadCount = count;
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      leading: widget.showMenu
          ? IconButton(
              icon: Icon(Icons.menu, color: colorScheme.primary),
              onPressed: widget.onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
            )
          : (Navigator.of(context).canPop() && widget.automaticallyImplyLeading)
              ? Padding(
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
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                )
              : null,
      centerTitle: true,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '<',
              style: textTheme.headlineLarge?.copyWith(
                color: const Color(0xFFFF9B04), // Branded Orange
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.title ?? 'Plokitch',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '>',
              style: textTheme.headlineLarge?.copyWith(
                color: const Color(0xFFFF9B04), // Branded Orange
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.showNotificationIcon)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Badge(
                label: Text('$_unreadCount'),
                isLabelVisible: _unreadCount > 0,
                backgroundColor: colorScheme.primaryContainer,
                textColor: colorScheme.onPrimaryContainer,
                child: IconButton(
                  icon: Icon(Icons.notifications_none, color: colorScheme.primary),
                  onPressed: () async {
                    if (widget.onNotificationPressed != null) {
                      widget.onNotificationPressed!();
                    } else {
                      await Navigator.pushNamed(context, '/notifications');
                    }
                    _loadUnreadCount();
                  },
                ),
              ),
            ),
          ),
        if (widget.showCart)
          IconButton(
            icon: Icon(Icons.shopping_cart, color: colorScheme.primary),
            onPressed: widget.onCartPressed,
          ),
        if (widget.showAvatar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: widget.onAvatarPressed,
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
                  image: widget.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(widget.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.avatarUrl == null
                    ? Icon(Icons.person, size: 20, color: colorScheme.onSecondaryContainer)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
