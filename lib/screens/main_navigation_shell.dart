import 'package:flutter/material.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../services/auth_service.dart';
import '../main.dart';

// Import all screens
import 'chef_dashboard_screen.dart';
import 'kitchen_management_screen.dart';
import 'chef_orders_screen.dart';
import 'settings_screen.dart';
import 'rider_dashboard_screen.dart';
import 'market_screen.dart';
import 'order_history_screen.dart';
import 'map_explorer_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  String _role = mockUserRole;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadRole();
  }

  @override
  void didUpdateWidget(MainNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
    }
  }

  Future<void> _loadRole() async {
    try {
      final stored = await AuthService.storedRole();
      if (stored != null && stored.isNotEmpty) {
        if (mounted) {
          setState(() {
            _role = stored;
            _loadingRole = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loadingRole = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingRole = false;
        });
      }
    }
  }

  List<Widget> _getScreensForRole(String role) {
    switch (role) {
      case 'chef':
        return const [
          ChefDashboardScreen(),
          KitchenManagementScreen(),
          ChefOrdersScreen(),
          SettingsScreen(),
        ];
      case 'rider':
        return const [
          RiderDashboardScreen(),
          MarketScreen(role: 'rider'),
          OrderHistoryScreen(),
          SettingsScreen(),
        ];
      default: // customer/foodie
        return const [
          MapExplorerScreen(),
          MarketScreen(role: 'customer'),
          OrderHistoryScreen(),
          SettingsScreen(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screens = _getScreensForRole(_role);
    final index = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      extendBody: false,
      body: IndexedStack(
        index: index,
        children: screens,
      ),
      bottomNavigationBar: PlokitchBottomNav(
        role: _role,
        currentIndex: index,
        onTap: (newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        },
      ),
    );
  }
}
