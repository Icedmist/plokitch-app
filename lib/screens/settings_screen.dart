import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../main.dart';

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
        _avatarUrl = profile?['avatarUrl'] as String? ?? profile?['avatar_url'] as String?;
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Settings',
        showMenu: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Profile Anchor Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF642714), // warmBrown
              borderRadius: BorderRadius.circular(16),
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
                  child: _avatarUrl == null ? const Icon(Icons.person, color: Colors.white, size: 32) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profileName, style: textTheme.titleLarge?.copyWith(color: Colors.white)),
                      Text(_profileEmail, style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(_profileRole.toUpperCase(), style: textTheme.bodySmall?.copyWith(color: Colors.white54)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, '/account-details'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
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
              onTap: () => Navigator.pushNamed(context, '/account-details')),
          _buildSettingsItem(Icons.notifications_none, 'Notifications', colorScheme, textTheme,
              onTap: () => Navigator.pushNamed(context, '/notifications')),
          _buildSettingsItem(Icons.payment, 'Payment Methods', colorScheme, textTheme,
              onTap: () => Navigator.pushNamed(context, '/payment-methods')),
          _buildSettingsItem(Icons.history, 'Order History', colorScheme, textTheme,
              onTap: () => Navigator.pushNamed(context, '/order-history')),
          
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
              onPressed: _handleLogout,
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
}
