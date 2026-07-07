import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/plokitch_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/about_plokitch_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/sign_in_screen.dart';
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

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
String mockUserRole = 'customer'; // placeholder until auth is wired

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
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['VITE_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['VITE_SUPABASE_ANON_KEY'] ?? '',
  );
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
            '/': (context) => const WelcomeScreen(),
            '/about': (context) => const AboutPlokitchScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/sign-in': (context) => const SignInScreen(),
            '/profile-setup': (context) => const ProfileSetupFlow(),
            // Role-based home: always resolves to the correct dashboard
            '/home': (context) => _roleHome(),
            '/cart': (context) => const CartScreen(),
            '/payment': (context) => const PaymentScreen(),
            '/tracking': (context) => const OrderTrackingScreen(),
            '/order-history': (context) => const OrderHistoryScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/chef-dashboard': (context) => const ChefDashboardScreen(),
            '/chef-orders': (context) => const ChefOrdersScreen(),
            '/kitchen': (context) => const KitchenManagementScreen(),
            '/market': (context) => const MarketScreen(),
            '/food-detail': (context) => const FoodDetailScreen(),
            '/kitchen-profile': (context) => const KitchenProfileScreen(),
            '/account-details': (context) => const AccountDetailsScreen(),
            '/payment-methods': (context) => const PaymentMethodsScreen(),
            '/rider-dashboard': (context) => const RiderDashboardScreen(),
          },
        );
      },
    );
  }
}
