import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/plokitch_error_banner.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedRole;
  bool _isPasswordVisible = false;
  bool _loading = false;
  String? _error;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSignUp();
    }
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final role = _selectedRole ?? 'foodie';

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.signUp(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: '+234$phone',
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/profile-setup');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  String _getBackgroundImage() {
    if (_currentPage == 0) {
      return 'assets/images/onboarding_general.png';
    }
    switch (_selectedRole) {
      case 'foodie':
        return 'assets/images/onboarding_foodie.png';
      case 'chef':
        return 'assets/images/onboarding_chef.png';
      case 'rider':
        return 'assets/images/onboarding_rider.png';
      default:
        return 'assets/images/onboarding_general.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background Image with animated transition ──────────────────────
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Image.asset(
                _getBackgroundImage(),
                key: ValueKey(_getBackgroundImage()),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // Gradient Overlay at the top to keep status bar / icons visible
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Navigation / Progress bar
                _buildTopNavigation(colorScheme, textTheme),
                
                // Page Content
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
                      _buildStep1Welcome(context, colorScheme, textTheme),
                      _buildStep2ChooseVibe(context, colorScheme, textTheme),
                      _buildStep3SignUp(context, colorScheme, textTheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigation(ColorScheme colorScheme, TextTheme textTheme) {
    if (_currentPage == 0) {
      return const SizedBox(height: 56);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.primary, size: 20),
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 3,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.3),
                color: colorScheme.primary,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_currentPage + 1}/3',
            style: textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Welcome(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Plokitch',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Authentic Flavors of Gombe, Delivered Hot.',
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Join the fastest growing community of food lovers and local chefs.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 32),
                            OutlinedButton(
                              onPressed: _nextPage,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: colorScheme.surface,
                                elevation: 0,
                              ),
                              child: Text(
                                'GET STARTED',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/sign-in');
                                },
                                child: Text(
                                  'Already have an account? Sign In',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep2ChooseVibe(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Choose your vibe',
                              style: textTheme.headlineMedium?.copyWith(
                                color: colorScheme.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'How will you use Plokitch?',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildRoleCard(
                              id: 'foodie',
                              icon: Icons.restaurant,
                              title: 'Hungry Foodie',
                              description: 'I want to order delicious local food.',
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 12),
                            _buildRoleCard(
                              id: 'chef',
                              icon: Icons.storefront,
                              title: 'Local Chef',
                              description: 'I want to sell my culinary creations.',
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 12),
                            _buildRoleCard(
                              id: 'rider',
                              icon: Icons.two_wheeler,
                              title: 'Delivery Rider',
                              description: 'I want to deliver and earn money.',
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            
                            const SizedBox(height: 24),
                            OutlinedButton(
                              onPressed: _selectedRole != null ? _nextPage : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _selectedRole != null 
                                      ? colorScheme.primary 
                                      : colorScheme.outlineVariant, 
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: _selectedRole != null 
                                    ? colorScheme.surface 
                                    : colorScheme.surface.withValues(alpha: 0.5),
                                elevation: 0,
                              ),
                              child: Text(
                                'CONTINUE',
                                style: TextStyle(
                                  color: _selectedRole != null 
                                      ? colorScheme.primary 
                                      : colorScheme.outline,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleCard({
    required String id,
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isSelected = _selectedRole == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surfaceContainerHigh : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(description, style: textTheme.bodySmall?.copyWith(color: colorScheme.outline)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3SignUp(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Create Account',
                              style: textTheme.headlineMedium?.copyWith(
                                color: colorScheme.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join Plokitch today.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_error != null) ...[
                              PlokitchErrorBanner(
                                message: _error!,
                                onDismiss: () => setState(() => _error = null),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'Amina Yusuf',
                              icon: Icons.person_outline,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 16),
                            
                            // Phone Field with +234
                            Text(
                              'Phone Number',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: colorScheme.outlineVariant),
                                borderRadius: BorderRadius.circular(16),
                                color: colorScheme.surfaceContainerHigh,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('🇳🇬'),
                                        const SizedBox(width: 8),
                                        Text(
                                          '+234', 
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      cursorColor: colorScheme.primary,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 15,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '801 234 5678',
                                        hintStyle: TextStyle(
                                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                                          fontSize: 15,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'amina@example.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field
                            Text(
                              'Password',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              cursorColor: colorScheme.primary,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(Icons.lock_outline, color: colorScheme.outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: colorScheme.outline,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHigh,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            OutlinedButton(
                              onPressed: _loading ? null : _handleSignUp,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: colorScheme.surface,
                                elevation: 0,
                              ),
                              child: Text(
                                _loading ? 'CREATING ACCOUNT...' : 'CREATE ACCOUNT',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/sign-in');
                                },
                                child: Text(
                                  'Already have an account? Sign In',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          cursorColor: colorScheme.primary,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 15,
            ),
            prefixIcon: Icon(icon, color: colorScheme.outline),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
