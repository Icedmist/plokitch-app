import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_button.dart';

enum PaymentPhase { select, processing, success }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  PaymentPhase _phase = PaymentPhase.select;
  String _selectedMethod = 'wallet';
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _processPayment() {
    setState(() {
      _phase = PaymentPhase.processing;
    });
    
    // Simulate network request
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _phase = PaymentPhase.success;
        });
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: PlokitchAppBar(
        title: _phase == PaymentPhase.select ? 'Checkout' : '',
        showMenu: false,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildCurrentPhase(context, colorScheme, textTheme),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    switch (_phase) {
      case PaymentPhase.select:
        return _buildSelectPhase(context, colorScheme, textTheme);
      case PaymentPhase.processing:
        return _buildProcessingPhase(context, colorScheme, textTheme);
      case PaymentPhase.success:
        return _buildSuccessPhase(context, colorScheme, textTheme);
    }
  }

  Widget _buildSelectPhase(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total to Pay', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Text('₦14,500', style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '15 Aminu Kano Way, Wuse 2',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text('Payment Method', style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: 16),
          
          _buildPaymentMethod(
            id: 'wallet',
            title: 'Plokitch Wallet',
            subtitle: 'Balance: ₦25,000',
            icon: Icons.account_balance_wallet,
            isRecommended: true,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethod(
            id: 'card',
            title: 'Credit / Debit Card',
            subtitle: '**** **** **** 4242',
            icon: Icons.credit_card,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethod(
            id: 'transfer',
            title: 'Bank Transfer',
            subtitle: 'Pay via USSD or App',
            icon: Icons.account_balance,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          
          const Spacer(),
          PlokitchButton(
            text: 'Confirm & Pay ₦14,500',
            onPressed: _processPayment,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isRecommended = false,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isSelected = _selectedMethod == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surfaceContainerHigh : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primaryContainer : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: textTheme.labelSmall?.copyWith(color: colorScheme.onPrimaryContainer, fontSize: 8),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primaryContainer : colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primaryContainer,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingPhase(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simulate the simmering pot animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * 3.14159,
                child: Icon(Icons.restaurant, size: 80, color: colorScheme.primaryContainer),
              );
            },
            onEnd: () {
              // We could repeat it if we wanted to manage the controller explicitly
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Simmering...',
            style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Confirming your payment',
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            child: LinearProgressIndicator(
              color: colorScheme.primaryContainer,
              backgroundColor: colorScheme.surfaceContainerHigh,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessPhase(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primaryContainer.withOpacity(0.4),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.check, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Order Confirmed!',
            style: textTheme.headlineLarge?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Your food is being prepared.',
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order ID', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Text('#PK-8249', style: textTheme.titleMedium),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Amount Paid', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Text('₦14,500', style: textTheme.titleMedium),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Est. Delivery', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Text('25-35 mins', style: textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
                  ],
                ),
              ],
            ),
          ),
          
          const Spacer(),
          PlokitchButton(
            text: 'Track My Order',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/tracking');
            },
          ),
          const SizedBox(height: 16),
          PlokitchButton(
            text: 'Back to Market',
            isOutlined: true,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
    );
  }
}
