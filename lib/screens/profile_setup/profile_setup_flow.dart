import 'package:flutter/material.dart';
import 'referral_page.dart';
import 'location_page.dart';
import 'first_action_page.dart';
import '../../widgets/plokitch_app_bar.dart';

class ProfileSetupFlow extends StatefulWidget {
  const ProfileSetupFlow({super.key});

  @override
  State<ProfileSetupFlow> createState() => _ProfileSetupFlowState();
}

class _ProfileSetupFlowState extends State<ProfileSetupFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _userRole = 'foodie'; // Default role, in a real app this comes from auth state

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (_userRole == 'chef') {
        Navigator.pushReplacementNamed(context, '/chef-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const PlokitchAppBar(title: 'Setup Profile', showMenu: false),
      body: Column(
        children: [
          // Custom Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 8,
                    margin: EdgeInsets.only(right: index < 2 ? 8.0 : 0),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? colorScheme.primaryContainer
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                ReferralPage(onNext: _nextPage),
                LocationPage(onNext: _nextPage, onBack: _previousPage),
                FirstActionPage(role: _userRole, onNext: _nextPage, onBack: _previousPage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
