import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/plokitch_app_bar.dart';
import '../main.dart';
import 'main_navigation_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _profileName = 'Plokitch User';
  String _profileEmail = 'No email provided';
  String _profileRole = 'customer';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.getProfile();
      final storedRole = await AuthService.storedRole();
      if (!mounted) return;
      setState(() {
        _profileName = profile?['name'] as String? ?? _profileName;
        _profileEmail = profile?['email'] as String? ?? _profileEmail;
        _profileRole = profile?['role'] as String? ?? storedRole ?? _profileRole;
        _avatarUrl = profile?['image'] as String? ?? profile?['avatarUrl'] as String? ?? profile?['avatar_url'] as String?;
      });
    } catch (_) {
      final storedRole = await AuthService.storedRole();
      if (!mounted) return;
      setState(() {
        _profileRole = storedRole ?? _profileRole;
      });
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Log Out?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to log out of your account?',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _handleLogout();
                        },
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Settings',
        showMenu: false,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Profile Anchor Card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.primaryContainer, width: 2),
                        image: _avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                      ),
                      child: _avatarUrl == null ? Icon(Icons.person, color: colorScheme.primary, size: 32) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_profileName, style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
                          Text(_profileEmail, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(_profileRole.toUpperCase(), style: textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: colorScheme.primary),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/account-details');
                        _loadProfile();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_profileRole == 'admin') ...[
            ValueListenableBuilder<String>(
              valueListenable: activeAdminRoleNotifier,
              builder: (context, activeMode, child) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
                  ),
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'ADMIN VIEW CONTROL',
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildAdminModeOption(
                              label: 'Customer',
                              icon: Icons.shopping_bag_outlined,
                              isActive: activeMode == 'customer',
                              onTap: () => activeAdminRoleNotifier.value = 'customer',
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            const SizedBox(width: 8),
                            _buildAdminModeOption(
                              label: 'Vendor',
                              icon: Icons.restaurant_outlined,
                              isActive: activeMode == 'chef',
                              onTap: () => activeAdminRoleNotifier.value = 'chef',
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            const SizedBox(width: 8),
                            _buildAdminModeOption(
                              label: 'Rider',
                              icon: Icons.pedal_bike_outlined,
                              isActive: activeMode == 'rider',
                              onTap: () => activeAdminRoleNotifier.value = 'rider',
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          
          if (_profileRole == 'chef') ...[
            Text('Kitchen Management', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
            const SizedBox(height: 16),
            _buildSettingsItem(Icons.storefront, 'Kitchen Profile', colorScheme, textTheme,
                onTap: () => Navigator.pushNamed(context, '/kitchen-settings')),
            const SizedBox(height: 32),
          ],

          Text('Preferences', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 16),
          
          _buildSettingsItem(Icons.person_outline, 'Account Details', colorScheme, textTheme,
              onTap: () async {
                await Navigator.pushNamed(context, '/account-details');
                _loadProfile();
              }),
          _buildSettingsItem(Icons.notifications_none, 'Notifications', colorScheme, textTheme,
              onTap: () => Navigator.pushNamed(context, '/notifications')),
          _buildSettingsItem(Icons.settings_outlined, 'Notification Settings', colorScheme, textTheme,
              onTap: () => Navigator.pushNamed(context, '/notification-settings')),
          _buildSettingsItem(Icons.payment, 'Payment Methods', colorScheme, textTheme,
              onTap: () => Navigator.pushNamed(context, '/payment-methods')),
          
          const SizedBox(height: 32),
          Text('Appearance', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 16),
          
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentTheme, child) {
              return Material(
                color: colorScheme.surfaceContainerHigh,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    _buildThemeOption(ThemeMode.system, currentTheme, 'System Default', Icons.brightness_auto, colorScheme, textTheme),
                    const Divider(height: 1),
                    _buildThemeOption(ThemeMode.light, currentTheme, 'Light Mode', Icons.light_mode, colorScheme, textTheme),
                    const Divider(height: 1),
                    _buildThemeOption(ThemeMode.dark, currentTheme, 'Dark Mode', Icons.dark_mode, colorScheme, textTheme),
                  ],
                ),
              );
            }
          ),
          
          const SizedBox(height: 32),
          Text('Support', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 16),
          _buildSettingsItem(Icons.help_outline, 'Help & Support', colorScheme, textTheme, onTap: () {}),
          
          const SizedBox(height: 48),
          
          // Log Out Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _showLogoutConfirmationDialog,
              icon: Icon(Icons.logout, color: colorScheme.error),
              label: Text(
                'LOG OUT',
                style: textTheme.labelLarge?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.errorContainer, width: 2),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Version 2.4.0 (Gombe-Build)',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, ColorScheme colorScheme, TextTheme textTheme, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
      ),
      title: Text(title, style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
      trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
      onTap: onTap,
    );
  }

  Widget _buildThemeOption(ThemeMode mode, ThemeMode currentTheme, String title, IconData icon, ColorScheme colorScheme, TextTheme textTheme) {
    final isSelected = currentTheme == mode;
    
    return ListTile(
      leading: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
      title: Text(title, style: textTheme.bodyLarge?.copyWith(color: isSelected ? colorScheme.primary : colorScheme.onSurface)),
      trailing: isSelected ? Icon(Icons.check, color: colorScheme.primaryContainer) : null,
      onTap: () {
        themeNotifier.value = mode;
      },
    );
  }

  Widget _buildAdminModeOption({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
