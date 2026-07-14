import 'package:flutter/material.dart';
import '../widgets/plokitch_button.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

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
      
      final profile = await AuthService.getProfile(forceRefresh: true);
      if (!mounted) return;
      
      if (profile == null || profile.isEmpty) {
        throw Exception('Failed to load profile. Please try signing in again.');
      }
      
      final bool loginNotifEnabled = profile['loginNotificationsEnabled'] as bool? ??
          profile['login_notifications_enabled'] as bool? ??
          true;

      final profileRole = (profile['role'] as String?)?.toLowerCase();
      final fallbackRole = await AuthService.storedRole();
      final role = (profileRole != null && profileRole.isNotEmpty)
          ? profileRole
          : (fallbackRole?.toLowerCase() ?? 'customer');
      mockUserRole = role;
      
      // Navigate to appropriate role-based dashboard
      final route = role == 'chef'
          ? '/chef-dashboard'
          : role == 'rider'
              ? '/rider-dashboard'
              : '/home';
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context, 
        route, 
        arguments: {'showLoginToast': loginNotifEnabled},
      );
    } catch (e) {
      if (!mounted) return;
      final message = _friendlyAuthError(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(Object error) {
    final message = error.toString().toLowerCase();
    print('Auth error: $error'); // Log the actual error for debugging
    
    if (message.contains('invalid')) {
      return 'Email or password is incorrect. Please try again.';
    }
    if (message.contains('not found')) {
      return 'This account doesn\'t exist. Please check your email or sign up.';
    }
    if (message.contains('network') || message.contains('socket') || message.contains('connection') || message.contains('errno 111')) {
      return 'Unable to connect to server. Ensure your backend is running at ${ApiService.baseUrl} and your internet is stable.';
    }
    if (message.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }
    if (message.contains('server') || message.contains('500')) {
      return 'Server is experiencing issues. Please try again in a moment.';
    }
    if (message.contains('profile')) {
      return 'Unable to load your profile. Please try signing in again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.of(context).canPop()
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    color: colorScheme.primary,
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Logo Header ──────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/Plokitch_Bracket_Left.png',
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Plokitch',
                              style: textTheme.headlineLarge?.copyWith(
                                color: colorScheme.primary,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/images/Plokitch_Bracket_Right.png',
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ── Authentication Card ──────────────────────────────
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Welcome Back',
                                    textAlign: TextAlign.center,
                                    style: textTheme.headlineMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Sign in to order or manage your kitchen.',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

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
                              Text(
                                'Password',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.outline.withValues(alpha: 0.6),
                                  ),
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
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/forgot-password');
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              PlokitchButton(
                                text: _loading ? 'Signing in...' : 'Sign In',
                                onPressed: _loading
                                    ? null
                                    : () {
                                        _handleSignIn();
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),

                        const SizedBox(height: 32),
                        Row(
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
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colorScheme.outline.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
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
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
