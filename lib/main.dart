import 'package:flutter/material.dart';

import 'theme/plokitch_theme.dart';
import 'screens/about_plokitch_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/profile_setup/profile_setup_flow.dart';
import 'screens/map_explorer_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chef_dashboard_screen.dart';
import 'screens/kitchen_management_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const PlokitchApp());
}

class PlokitchApp extends StatelessWidget {
  const PlokitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Plokitch',
          debugShowCheckedModeBanner: false,
          theme: PlokitchTheme.lightTheme,
          darkTheme: PlokitchTheme.darkTheme,
          themeMode: currentMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const AboutPlokitchScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/sign-in': (context) => const SignInScreen(),
            '/profile-setup': (context) => const ProfileSetupFlow(),
            '/home': (context) => const MapExplorerScreen(),
            '/cart': (context) => const CartScreen(),
            '/payment': (context) => const PaymentScreen(),
            '/tracking': (context) => const OrderTrackingScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/chef-dashboard': (context) => const ChefDashboardScreen(),
            '/kitchen': (context) => const KitchenManagementScreen(),
          },
        );
      }
    );
  }
}
