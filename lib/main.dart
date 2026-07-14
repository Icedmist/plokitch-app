import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/plokitch_theme.dart';
import 'services/auth_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/profile_setup/profile_setup_flow.dart';
import 'screens/map_explorer_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chef_dashboard_screen.dart';
import 'screens/chef_orders_screen.dart';
import 'screens/kitchen_management_screen.dart';
import 'screens/kitchen_profile_screen.dart';
import 'screens/market_screen.dart';
import 'screens/rider_dashboard_screen.dart';
import 'screens/food_detail_screen.dart';
import 'screens/account_details_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/kitchen_settings_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/notification_settings_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
String mockUserRole = 'customer'; // updated at startup from stored profile when available

/// Returns the correct home screen widget based on the current user role.
Widget _roleHome() {
  switch (mockUserRole) {
    case 'chef':
      return const ChefDashboardScreen();
    case 'rider':
      return const RiderDashboardScreen();
    default:
      return const MapExplorerScreen();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env may be absent in some environments (web/dev); continue with defaults
    // Avoid crashing the app when assets/.env is not present
    // ignore: avoid_print
    print('dotenv.load failed: $e');
  }
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  // Try to restore session from stored token and determine initial route
  try {
    final role = await AuthService.storedRole();
    if (role != null && role.isNotEmpty) {
      mockUserRole = role;
      // Validate that the stored token is still valid by attempting refresh
      final isValid = await AuthService.tryRefreshSession();
      if (!isValid) {
        // Token expired, clear it for login
        await AuthService.signOut();
      }
    }
  } catch (_) {}
  runApp(const PlokitchApp());
}

class PlokitchApp extends StatelessWidget {
  const PlokitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        final isDark = currentMode == ThemeMode.dark ||
            (currentMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            systemNavigationBarColor: isDark ? const Color(0xFF14120E) : const Color(0xFFFFF9EC),
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp(
          title: 'Plokitch',
          debugShowCheckedModeBanner: false,
          theme: PlokitchTheme.lightTheme,
          darkTheme: PlokitchTheme.darkTheme,
          themeMode: currentMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const WelcomeScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/sign-in': (context) => const SignInScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/profile-setup': (context) => const ProfileSetupFlow(),
            // Role-based home: always resolves to the correct dashboard via the shell wrapper
            '/home': (context) => const MainNavigationShell(initialIndex: 0),
            '/cart': (context) => const CartScreen(),
            '/payment': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              return PaymentScreen(orderPayload: args is Map<String, dynamic> ? args : null);
            },
            '/tracking': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              return OrderTrackingScreen(orderId: args is String ? args : null);
            },
            '/order-history': (context) => const MainNavigationShell(initialIndex: 2),
            '/notifications': (context) => const NotificationsScreen(),
            '/settings': (context) => const MainNavigationShell(initialIndex: 3),
            '/chef-dashboard': (context) => const MainNavigationShell(initialIndex: 0),
            '/chef-orders': (context) => const MainNavigationShell(initialIndex: 2),
            '/kitchen': (context) => const MainNavigationShell(initialIndex: 1),
            '/market': (context) => const MainNavigationShell(initialIndex: 1),
            '/food-detail': (context) => const FoodDetailScreen(),
            '/kitchen-profile': (context) => const KitchenProfileScreen(),
            '/account-details': (context) => const AccountDetailsScreen(),
            '/payment-methods': (context) => const PaymentMethodsScreen(),
            '/rider-dashboard': (context) => const MainNavigationShell(initialIndex: 0),
            '/kitchen-settings': (context) => const KitchenSettingsScreen(),
            '/notification-settings': (context) => const NotificationSettingsScreen(),
          },
        );
      },
    );
  }
}
