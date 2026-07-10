import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../widgets/plokitch_toast.dart';
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

// Global notifier for the active role used by administrators to preview screens.
final ValueNotifier<String> activeAdminRoleNotifier = ValueNotifier<String>('customer');

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
    activeAdminRoleNotifier.addListener(_onAdminRoleChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['showLoginToast'] == true) {
        args['showLoginToast'] = false;
        PlokitchToast.show(
          context,
          'You successfully logged into your account.',
          icon: Icons.vpn_key_outlined,
        );
      }
    });
  }

  @override
  void dispose() {
    activeAdminRoleNotifier.removeListener(_onAdminRoleChanged);
    super.dispose();
  }

  void _onAdminRoleChanged() async {
    if (mounted && _role == 'admin') {
      setState(() {
        _currentIndex = 0; // Reset index when switching UI modes
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_active_role', activeAdminRoleNotifier.value);
    }
  }

  Future<void> _loadRole() async {
    try {
      final stored = await AuthService.storedRole();
      if (stored != null && stored.isNotEmpty) {
        if (stored == 'admin') {
          final prefs = await SharedPreferences.getInstance();
          final override = prefs.getString('admin_active_role');
          if (override != null && (override == 'customer' || override == 'chef' || override == 'rider')) {
            activeAdminRoleNotifier.value = override;
          }
        }
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

    final activeRole = _role == 'admin' ? activeAdminRoleNotifier.value : _role;
    final screens = _getScreensForRole(activeRole);
    final index = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      extendBody: false,
      body: FadeIndexedStack(
        index: index,
        children: screens,
      ),
      bottomNavigationBar: PlokitchBottomNav(
        role: activeRole,
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

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 180), // Fast and snappy transitions
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        vsync: this,
        duration: widget.duration,
        value: index == widget.index ? 1.0 : 0.0,
      ),
    );
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controllers[oldWidget.index].reverse();
      _controllers[widget.index].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.children.length, (index) {
        final isCurrent = index == widget.index;
        return IgnorePointer(
          ignoring: !isCurrent,
          child: AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              final opacity = _controllers[index].value;
              if (opacity == 0.0) {
                return const SizedBox.shrink();
              }
              return Opacity(
                opacity: opacity,
                child: child,
              );
            },
            child: widget.children[index],
          ),
        );
      }),
    );
  }
}
