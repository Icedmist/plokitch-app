import 'package:flutter/material.dart';
import '../widgets/plokitch_button.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Email is required.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.forgotPassword(email);
      if (mounted) {
        setState(() {
          _submitted = true;
          _loading = false;
        });
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
                              mainAxisAlignment: MainAxisAlignment.start,
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
                              ],
                            ),
                          ),
                          
                          const Spacer(),

                          // ── Floating Reset Card ─────────────────────────────────
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
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _submitted
                                      ? _buildSuccessState(colorScheme, textTheme)
                                      : _buildFormState(colorScheme, textTheme),
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

  Widget _buildFormState(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      key: const ValueKey('form_state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Reset Password',
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email address below and we\'ll send you a link to reset your password.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.errorContainer),
            ),
            child: Text(
              _error!,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildModernTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'amina@example.com',
          keyboardType: TextInputType.emailAddress,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _loading ? null : _handleSubmit,
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
            _loading ? 'SENDING LINK...' : 'SEND RESET LINK',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      key: const ValueKey('success_state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF34A853).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: Color(0xFF34A853),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to ${_emailController.text.trim()}. Please check your email inbox to complete the password reset process.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: colorScheme.surface,
            elevation: 0,
          ),
          child: const Text(
            'BACK TO LOGIN',
            style: TextStyle(
              color: Color(0xFF3E1F1A),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    required ColorScheme colorScheme,
  }) {
    return TextField(
      controller: controller,
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
