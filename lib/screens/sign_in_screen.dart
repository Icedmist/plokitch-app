import 'package:flutter/material.dart';
import '../widgets/plokitch_button.dart';
import '../widgets/plokitch_app_bar.dart';
import '../main.dart';
import '../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isPasswordVisible = false;
  bool _loading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email and password are required')));
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.signIn(email, password);
      if (!mounted) return;
      final profile = await AuthService.getProfile();
      if (!mounted) return;
      final role = profile?['role'] as String? ?? 'customer';
      if (role == 'chef') {
        Navigator.pushReplacementNamed(context, '/chef-dashboard');
      } else if (role == 'rider') {
        Navigator.pushReplacementNamed(context, '/rider-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const PlokitchAppBar(showMenu: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome Back',
                style: textTheme.headlineLarge?.copyWith(color: colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to order or manage your kitchen.',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 48),
              
              _buildTextField(
                controller: _emailController,
                label: 'Email / Phone Number',
                hint: 'amina@example.com',
                icon: Icons.person_outline,
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
              const SizedBox(height: 16),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Handle forgot password
                  },
                  child: Text(
                    'Forgot Password?',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              const SizedBox.shrink(),
              
              const SizedBox(height: 32),
              PlokitchButton(
                text: _loading ? 'Signing in...' : 'Sign In',
                onPressed: () {
                  if (!_loading) _handleSignIn();
                },
              ),
              
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/onboarding');
                      },
                      child: Text(
                        'Sign Up',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
