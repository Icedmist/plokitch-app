import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/plokitch_toast.dart';

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
      PlokitchToast.show(context, 'Email and password are required', isError: true);
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
      PlokitchToast.show(context, message, isError: true);
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
      body: Stack(
        children: [
          // ── Background Image ───────────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/signin_background.png',
              fit: BoxFit.cover,
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

          // ── Main Content & Scrollable Card ───────────────────────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // ── Top Navigation Bar ─────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Back Button
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
                                    onPressed: () => Navigator.maybePop(context),
                                  ),
                                ),
                                // Register/Log in top action pill
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(context, '/onboarding');
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    shadowColor: Colors.black.withValues(alpha: 0.1),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'Register',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const Spacer(),

                          // ── Floating Sign In Card ──────────────────────────────
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
                                    // Title
                                    Text(
                                      'Welcome Back',
                                      style: textTheme.headlineMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Google Sign In Button
                                    _buildSocialButton(
                                      text: 'Sign in with Google',
                                      iconWidget: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                                          width: 20,
                                          height: 20,
                                          errorBuilder: (context, error, stackTrace) => Text(
                                            'G',
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        // Placeholder for Google Auth flow
                                      },
                                      backgroundColor: colorScheme.surface,
                                      foregroundColor: colorScheme.onSurface,
                                      side: BorderSide(color: colorScheme.outlineVariant),
                                    ),
                                    const SizedBox(height: 12),

                                    // Apple Sign In Button
                                    _buildSocialButton(
                                      text: 'Sign in with Apple',
                                      iconWidget: Icon(Icons.apple, color: colorScheme.surface, size: 22),
                                      onPressed: () {
                                        // Placeholder for Apple Auth flow
                                      },
                                      backgroundColor: const Color(0xFF131314),
                                      foregroundColor: Colors.white,
                                    ),
                                    const SizedBox(height: 20),

                                    // Or Divider
                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: colorScheme.outlineVariant, height: 1)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                          child: Text(
                                            'or sign in with email',
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.outline,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: colorScheme.outlineVariant, height: 1)),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Email Address Text Field
                                    _buildModernTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      hint: 'amina@example.com',
                                      keyboardType: TextInputType.emailAddress,
                                      colorScheme: colorScheme,
                                    ),
                                    const SizedBox(height: 16),

                                    // Password Text Field
                                    _buildModernTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: '••••••••',
                                      obscureText: !_isPasswordVisible,
                                      colorScheme: colorScheme,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                          color: colorScheme.outline,
                                        ),
                                        onPressed: () {
                                          setState(() => _isPasswordVisible = !_isPasswordVisible);
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Email Sign In Action Button
                                    OutlinedButton(
                                      onPressed: _loading ? null : _handleSignIn,
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
                                        _loading ? 'SIGNING IN...' : 'SIGN IN WITH EMAIL',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Forgot Password Link
                                    Center(
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
                                          'I forgot my password',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            decoration: TextDecoration.underline,
                                            fontWeight: FontWeight.bold,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required Widget iconWidget,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    BorderSide? side,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: side,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    required ColorScheme colorScheme,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      cursorColor: colorScheme.primary,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 15,
        ),
        labelStyle: TextStyle(
          color: colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        suffixIcon: suffixIcon,
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
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
      ),
    );
  }
}
