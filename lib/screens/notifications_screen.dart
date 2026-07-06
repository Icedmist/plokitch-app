import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';

class _Notification {
  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final bool isRead;
  final String type; // 'order', 'promo', 'system'

  _Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    this.isRead = false,
    required this.type,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<_Notification> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      _Notification(
        id: '1',
        title: 'Order Confirmed! 🎉',
        body: 'Your order #PK-8249 has been placed. Chef is cooking your Jollof Rice Feast.',
        time: '2 mins ago',
        icon: Icons.check_circle,
        type: 'order',
      ),
      _Notification(
        id: '2',
        title: 'Rider En Route',
        body: 'Musa Ibrahim is on his way. ETA: 12 minutes. Track your order live.',
        time: '18 mins ago',
        icon: Icons.two_wheeler,
        type: 'order',
      ),
      _Notification(
        id: '3',
        title: '🔥 Weekend Special',
        body: 'Get 20% off all Masa orders this weekend. Use code MASA20 at checkout.',
        time: '2 hrs ago',
        icon: Icons.local_offer,
        isRead: true,
        type: 'promo',
      ),
      _Notification(
        id: '4',
        title: 'Order Delivered ✅',
        body: 'Your order #PK-8201 was delivered. Enjoy your meal! Rate your experience.',
        time: 'Yesterday',
        icon: Icons.home,
        isRead: true,
        type: 'order',
      ),
      _Notification(
        id: '5',
        title: 'New Chef in Your Area',
        body: "Mama Ngozi's Kitchen just joined Plokitch. Try her Pounded Yam & Egusi!",
        time: 'Yesterday',
        icon: Icons.restaurant,
        isRead: true,
        type: 'system',
      ),
      _Notification(
        id: '6',
        title: '💸 Wallet Topped Up',
        body: 'Your Plokitch Wallet has been credited with ₦5,000. Balance: ₦25,000.',
        time: '3 days ago',
        icon: Icons.account_balance_wallet,
        isRead: true,
        type: 'system',
      ),
    ];
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications.map((n) => _Notification(
        id: n.id,
        title: n.title,
        body: n.body,
        time: n.time,
        icon: n.icon,
        isRead: true,
        type: n.type,
      )).toList();
    });
  }

  void _markRead(String id) {
    setState(() {
      _notifications = _notifications.map((n) {
        if (n.id == id) {
          return _Notification(
            id: n.id, title: n.title, body: n.body, time: n.time,
            icon: n.icon, isRead: true, type: n.type,
          );
        }
        return n;
      }).toList();
    });
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: PlokitchAppBar(
        title: 'Notifications',
        showMenu: false,
        showAvatar: false,
      ),
      body: Column(
        children: [
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primaryContainer.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active, color: colorScheme.primaryContainer, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _markAllRead,
                    child: Text(
                      'Mark all read',
                      style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return _buildNotificationCard(n, colorScheme, textTheme);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: PlokitchBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/home');
          if (index == 2) Navigator.pushReplacementNamed(context, '/tracking');
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildNotificationCard(_Notification n, ColorScheme colorScheme, TextTheme textTheme) {
    Color iconBg;
    Color iconColor;
    switch (n.type) {
      case 'order':
        iconBg = colorScheme.primaryContainer.withValues(alpha: 0.2);
        iconColor = colorScheme.primaryContainer;
        break;
      case 'promo':
        iconBg = colorScheme.tertiaryContainer.withValues(alpha: 0.2);
        iconColor = colorScheme.tertiary;
        break;
      default:
        iconBg = colorScheme.secondaryContainer.withValues(alpha: 0.2);
        iconColor = colorScheme.secondary;
    }

    return GestureDetector(
      onTap: () => _markRead(n.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead ? colorScheme.outlineVariant : colorScheme.primaryContainer.withValues(alpha: 0.5),
            width: n.isRead ? 1 : 1.5,
          ),
          boxShadow: n.isRead ? [] : [
            BoxShadow(
              color: colorScheme.primaryContainer.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(n.icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n.time,
                    style: textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
