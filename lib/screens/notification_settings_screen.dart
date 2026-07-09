import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/plokitch_app_bar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _pushNotifications = true;
  bool _marketingEmails = false;
  bool _loginNotifications = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final profile = await AuthService.getProfile();
      final prefs = await SharedPreferences.getInstance();

      // Read values from API profile or fall back to local preferences
      final bool profilePushVal = profile?['pushNotificationsEnabled'] as bool? ??
          profile?['push_notifications_enabled'] as bool? ??
          true;
      final bool profileEmailVal = profile?['marketingEmailsEnabled'] as bool? ??
          profile?['marketing_emails_enabled'] as bool? ??
          false;
      final bool profileLoginVal = profile?['loginNotificationsEnabled'] as bool? ??
          profile?['login_notifications_enabled'] as bool? ??
          true;

      setState(() {
        _pushNotifications = prefs.getBool('pref_push_notifications') ?? profilePushVal;
        _marketingEmails = prefs.getBool('pref_marketing_emails') ?? profileEmailVal;
        _loginNotifications = prefs.getBool('pref_login_notifications') ?? profileLoginVal;
      });
    } catch (e) {
      _errorMessage = 'Failed to load preferences.';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveSettings(bool pushVal, bool emailVal, bool loginVal) async {
    setState(() {
      _saving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_push_notifications', pushVal);
      await prefs.setBool('pref_marketing_emails', emailVal);
      await prefs.setBool('pref_login_notifications', loginVal);

      // Send both camelCase and snake_case to the backend for maximum compatibility
      final payload = {
        'pushNotificationsEnabled': pushVal,
        'push_notifications_enabled': pushVal,
        'marketingEmailsEnabled': emailVal,
        'marketing_emails_enabled': emailVal,
        'loginNotificationsEnabled': loginVal,
        'login_notifications_enabled': loginVal,
      };

      await ApiService.updateUserProfile(payload);
      await AuthService.getProfile(forceRefresh: true);
    } catch (_) {
      // Silently fall back to local preferences if the API update fails
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Notification Settings',
        showMenu: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Alert Choices',
                  style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: colorScheme.surfaceContainerHigh,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Get alerts for order status, chats, and kitchen updates.'),
                          value: _pushNotifications,
                          activeThumbColor: colorScheme.primary,
                          onChanged: _saving
                              ? null
                              : (bool value) {
                                  setState(() {
                                    _pushNotifications = value;
                                  });
                                  _saveSettings(value, _marketingEmails, _loginNotifications);
                                },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Marketing Emails', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Receive special deals, newsletters, and promo codes.'),
                          value: _marketingEmails,
                          activeThumbColor: colorScheme.primary,
                          onChanged: _saving
                              ? null
                              : (bool value) {
                                  setState(() {
                                    _marketingEmails = value;
                                  });
                                  _saveSettings(_pushNotifications, value, _loginNotifications);
                                },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Login Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Receive alerts and top-sliding notifications whenever you sign in.'),
                          value: _loginNotifications,
                          activeThumbColor: colorScheme.primary,
                          onChanged: _saving
                              ? null
                              : (bool value) {
                                  setState(() {
                                    _loginNotifications = value;
                                  });
                                  _saveSettings(_pushNotifications, _marketingEmails, value);
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Preferences are automatically saved to your profile.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}
