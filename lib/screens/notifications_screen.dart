import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/plokitch_app_bar.dart';

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
  bool _loading = true;
  String? _profileName;

  @override
  void initState() {
    super.initState();
    _notifications = [];
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
    });
    try {
      final profile = await AuthService.getProfile();
      _profileName = profile?['name'] as String? ?? profile?['email'] as String?;
      
      final res = await ApiService.fetchNotifications();
      final data = res['data'] as List<dynamic>?;
      if (data != null) {
        _notifications = data.map((entry) {
          final map = Map<String, dynamic>.from(entry as Map);
          final readAt = map['readAt'] ?? map['read_at'];
          return _Notification(
            id: map['id']?.toString() ?? UniqueKey().toString(),
            title: map['title']?.toString() ?? 'Notification',
            body: map['body']?.toString() ?? map['message']?.toString() ?? 'You have a new notification.',
            time: _formatTime(map['createdAt'] ?? map['created_at']),
            icon: _iconForType(map['type']?.toString() ?? 'system'),
            isRead: readAt != null || map['isRead'] == true || map['read'] == true,
            type: map['type']?.toString() ?? 'system',
          );
        }).toList();
      }
    } catch (_) {
      _notifications = [];
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return 'Just now';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return value.toString();
    }
  }

  void _markAllRead() async {
    try {
      await ApiService.markAllNotificationsAsRead();
      await AuthService.getProfile(forceRefresh: true);
    } catch (_) {}
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

  IconData _iconForType(String type) {
    switch (type) {
      case 'order':
        return Icons.check_circle;
      case 'promo':
        return Icons.local_offer;
      case 'system':
      default:
        return Icons.info;
    }
  }

  void _markRead(String id) async {
    try {
      await ApiService.markNotificationAsRead(id);
      await AuthService.getProfile(forceRefresh: true);
    } catch (_) {}
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
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_notifications.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 72, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _profileName != null
                            ? 'Hello $_profileName, you will see alerts here when new updates are available.'
                            : 'Updates and alerts will appear here when they are available.',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
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
