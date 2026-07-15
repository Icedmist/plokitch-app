import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'plokitch_back_button.dart';


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
      final res = await ApiService.fetchNotifications(limit: 1);
      final count = res['unreadCount'] as int? ?? 0;
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
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
              ? const PlokitchBackButton()
              : null,
      centerTitle: true,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          widget.title ?? 'Plokitch',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
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
