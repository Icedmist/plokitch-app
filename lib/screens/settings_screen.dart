import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1531123897727-8f129e1688ce?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amina Yusuf', style: textTheme.titleLarge?.copyWith(color: Colors.white)),
                      Text('amina@example.com', style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text('Preferences', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 16),
          
          _buildSettingsItem(Icons.person_outline, 'Account Details', colorScheme, textTheme, onTap: () {}),
          _buildSettingsItem(Icons.notifications_none, 'Notifications', colorScheme, textTheme,
              onTap: () => Navigator.pushNamed(context, '/notifications')),
          _buildSettingsItem(Icons.payment, 'Payment Methods', colorScheme, textTheme, onTap: () {}),
          _buildSettingsItem(Icons.history, 'Order History', colorScheme, textTheme,
              onTap: () => Navigator.pushNamed(context, '/order-history')),
          
          const SizedBox(height: 32),
          Text('Appearance', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 16),
          
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentTheme, child) {
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
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
          _buildSettingsItem(Icons.info_outline, 'About Plokitch', colorScheme, textTheme,
              onTap: () => Navigator.pushNamed(context, '/about')),
          
          const SizedBox(height: 48),
          
          // Log Out Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
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
      bottomNavigationBar: PlokitchBottomNav(
        currentIndex: 3, // Profile
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/home');
          if (index == 1) Navigator.pushReplacementNamed(context, '/kitchen'); // or market depending on role
          if (index == 2) Navigator.pushReplacementNamed(context, '/tracking');
        },
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
