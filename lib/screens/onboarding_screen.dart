import 'package:flutter/material.dart';
import '../widgets/plokitch_button.dart';
import '../main.dart';
import '../services/auth_service.dart';

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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final role = _selectedRole ?? 'customer';

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.signUp(name: name, email: email, password: password, role: role);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/profile-setup');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe
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
          
          // Progress Bar (only show on step 2 and 3)
          if (_currentPage > 0)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_currentPage + 1) / 3,
                          backgroundColor: colorScheme.outlineVariant,
                          color: colorScheme.primaryContainer,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_currentPage + 1}/3',
                      style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep1Welcome(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.network(
            'https://images.unsplash.com/photo-1604328698692-f76ea9498e76?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
            fit: BoxFit.cover,
          ),
        ),
        // Dark Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '< Plokitch >',
                  style: textTheme.headlineLarge?.copyWith(
                    color: colorScheme.primaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Authentic Flavors of Gombe, Delivered Hot.',
                  style: textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Join the fastest growing community of food lovers and local chefs.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                PlokitchButton(
                  text: 'Get Started',
                  onPressed: _nextPage,
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
                        color: colorScheme.primaryContainer,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2ChooseVibe(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your vibe.',
              style: textTheme.headlineLarge?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'How will you use Plokitch?',
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            
            _buildRoleCard(
              id: 'foodie',
              icon: Icons.restaurant,
              title: 'Hungry Foodie',
              description: 'I want to order delicious local food.',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              id: 'chef',
              icon: Icons.storefront,
              title: 'Local Chef',
              description: 'I want to sell my culinary creations.',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              id: 'rider',
              icon: Icons.two_wheeler,
              title: 'Delivery Rider',
              description: 'I want to deliver and earn money.',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            
            const Spacer(),
            PlokitchButton(
              text: 'Continue',
              onPressed: _selectedRole != null ? _nextPage : () {},
              // Disable if no role selected (using alpha to simulate)
              // We'll wrap button to handle disable state natively next iteration if needed
            ),
          ],
        ),
      ),
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
            color: isSelected ? colorScheme.primaryContainer : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primaryContainer.withOpacity(0.2),
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
                color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.primary,
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
                  Text(description, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primaryContainer),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3SignUp(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Account',
              style: textTheme.headlineLarge?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Join Plokitch today.',
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            
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
            Text('Phone Number', style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
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
                        Text('+234', style: textTheme.bodyLarge),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '801 234 5678',
                        hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
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
            Text('Password', style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: colorScheme.onSurfaceVariant,
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
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            PlokitchButton(
              text: _loading ? 'Creating Account...' : 'Create Account',
              onPressed: _loading ? null : _nextPage,
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        Text(label, style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
            prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
