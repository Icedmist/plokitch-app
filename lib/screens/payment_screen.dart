import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/paystack_service.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_button.dart';

enum PaymentPhase { select, processing, success }

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? orderPayload;

  const PaymentScreen({super.key, this.orderPayload});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  PaymentPhase _phase = PaymentPhase.select;
  String _selectedMethod = 'paystack';
  String? _selectedSavedCard;
  String? _errorMessage;
  String? _confirmedOrderId;
  String? _paystackReference;
  double _amountPaid = 0.0;
  List<Map<String, String>> _savedMethods = [];

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

    if (widget.orderPayload != null) {
      _amountPaid = (widget.orderPayload!['totalAmount'] is num)
          ? (widget.orderPayload!['totalAmount'] as num).toDouble()
          : double.tryParse(widget.orderPayload!['totalAmount']?.toString() ?? '0') ?? 0.0;
    }

    _loadSavedPaymentMethods();
  }

  String _formatCardLabel(Map<String, String> m) {
    final type = m['type'] ?? 'Card';
    final last4 = m['last4'] ?? '????';
    final expires = m['expires'] ?? '';
    return '$type •••• $last4${expires.isNotEmpty ? ' ($expires)' : ''}';
  }

  Future<void> _loadSavedPaymentMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? methodsJson = prefs.getString('PLOKITCH_SAVED_PAYMENT_METHODS');
      if (methodsJson != null) {
        final List<dynamic> decoded = json.decode(methodsJson);
        final list = decoded.map((item) => Map<String, String>.from(item as Map)).toList();
        if (mounted) {
          setState(() {
            _savedMethods = list;
            if (_savedMethods.isNotEmpty) {
              _selectedSavedCard = _formatCardLabel(_savedMethods[0]);
            }
          });
        }
      }
    } catch (_) {}
  }

  String get _deliveryAddress {
    final addr = widget.orderPayload?['deliveryAddress'];
    if (addr is Map) {
      final parts = [addr['street'], addr['city'], addr['state']]
          .where((p) => p != null && p.toString().isNotEmpty)
          .toList();
      return parts.isNotEmpty ? parts.join(', ') : 'No address provided';
    }
    if (addr is String && addr.isNotEmpty) return addr;
    return 'No address provided';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (widget.orderPayload == null) {
      setState(() {
        _errorMessage = 'Unable to complete payment. Your order details are missing.';
      });
      return;
    }

    if (_selectedMethod == 'paystack') {
      _showPaystackCheckoutModal();
    } else {
      _executeOrderPlacement(paymentMethod: _selectedMethod);
    }
  }

  void _showPaystackCheckoutModal() {
    final emailController = TextEditingController(text: 'customer@plokitch.app');
    AuthService.getProfile().then((p) {
      if (p?['email'] != null && p!['email'].toString().isNotEmpty) {
        emailController.text = p['email'].toString();
      }
    });

    final formKey = GlobalKey<FormState>();
    final cardController = TextEditingController(text: '4081 0000 0000 4081');
    final expiryController = TextEditingController(text: '12/28');
    final cvvController = TextEditingController(text: '123');
    bool isProcessingApi = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF09A5DB).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    color: Color(0xFF09A5DB),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Paystack Checkout',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Pay ₦${_amountPaid.toStringAsFixed(0)} securely',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF09A5DB),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (_savedMethods.isNotEmpty) ...[
                          Builder(
                            builder: (context) {
                              final dropdownOptions = _savedMethods.map((m) => _formatCardLabel(m)).toSet().toList();
                              final currentSelection = (dropdownOptions.contains(_selectedSavedCard))
                                  ? _selectedSavedCard
                                  : (dropdownOptions.isNotEmpty ? dropdownOptions.first : null);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Select Saved Paystack Card:', style: theme.textTheme.labelMedium),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: currentSelection,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF09A5DB)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    items: dropdownOptions.map((label) {
                                      return DropdownMenuItem<String>(
                                        value: label,
                                        child: Text(label, style: theme.textTheme.bodyMedium),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setModalState(() {
                                        _selectedSavedCard = val;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                        ],

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Payment Receipt Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: cardController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Card Number',
                            hintText: '4081 0000 0000 4081',
                            prefixIcon: const Icon(Icons.credit_card_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          validator: (val) => val == null || val.length < 13 ? 'Enter card number' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: expiryController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Expiry (MM/YY)',
                                  hintText: '12/28',
                                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: cvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'CVV',
                                  hintText: '123',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF09A5DB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isProcessingApi
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setModalState(() {
                                      isProcessingApi = true;
                                    });

                                    final email = emailController.text.trim();
                                    final ref = PaystackService.generateReference();

                                    // Initialize Paystack API call
                                    final initResult = await PaystackService.initializeTransaction(
                                      email: email,
                                      amountInNaira: _amountPaid,
                                      reference: ref,
                                      metadata: {
                                        'custom_fields': [
                                          {'display_name': 'App', 'variable_name': 'app', 'value': 'Plokitch'},
                                          {'display_name': 'Delivery Address', 'variable_name': 'address', 'value': _deliveryAddress},
                                        ]
                                      },
                                    );

                                    if (mounted) {
                                      Navigator.pop(context);
                                      _executeOrderPlacement(
                                        paymentMethod: 'paystack',
                                        reference: initResult['reference']?.toString() ?? ref,
                                      );
                                    }
                                  },
                            child: isProcessingApi
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Pay ₦${_amountPaid.toStringAsFixed(0)} via Paystack',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _executeOrderPlacement({required String paymentMethod, String? reference}) {
    setState(() {
      _phase = PaymentPhase.processing;
      _errorMessage = null;
      _paystackReference = reference;
    });

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      try {
        final payload = Map<String, dynamic>.from(widget.orderPayload!);
        payload['paymentMethod'] = paymentMethod;
        if (reference != null) {
          payload['paystackReference'] = reference;
        }

        final order = await ApiService.placeOrder(payload);
        _confirmedOrderId = order['id']?.toString() ?? 'Unknown';
        _amountPaid = (order['totalAmount'] is num)
            ? (order['totalAmount'] as num).toDouble()
            : double.tryParse(order['totalAmount']?.toString() ?? _amountPaid.toString()) ?? _amountPaid;

        await CartService.clearCart();

        await ApiService.addNotification(
          title: 'Order Placed Successfully!',
          body: 'Your payment via ${paymentMethod == 'paystack' ? 'Paystack' : paymentMethod} was confirmed. Order #$_confirmedOrderId.',
          type: 'order',
        );

        if (!mounted) return;
        setState(() {
          _phase = PaymentPhase.success;
        });
        _pulseController.repeat(reverse: true);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _phase = PaymentPhase.select;
          _errorMessage = 'Payment succeeded, but the order could not be completed. Please try again or contact support.';
        });
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
                    Text('₦${_amountPaid.toStringAsFixed(0)}', style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _deliveryAddress,
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
            id: 'paystack',
            title: 'Paystack Payment',
            subtitle: _selectedSavedCard != null ? 'Saved: $_selectedSavedCard' : 'Cards, Bank Transfer, USSD, QR',
            icon: Icons.shield_outlined,
            isRecommended: true,
            badgeText: 'FAST & SECURE',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethod(
            id: 'wallet',
            title: 'Plokitch Wallet',
            subtitle: 'Balance: ₦25,000',
            icon: Icons.account_balance_wallet,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethod(
            id: 'transfer',
            title: 'Direct Bank Transfer',
            subtitle: 'Pay via USSD or Bank App',
            icon: Icons.account_balance,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          ],

          const Spacer(),
          PlokitchButton(
            text: widget.orderPayload != null
                ? 'Confirm & Pay ₦${_amountPaid.toStringAsFixed(0)}'
                : 'Unable to pay',
            onPressed: widget.orderPayload != null ? _processPayment : null,
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
    String? badgeText,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isSelected = _selectedMethod == id;
    final isPaystack = id == 'paystack';
    final activeColor = isPaystack ? const Color(0xFF09A5DB) : colorScheme.primary;

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
          color: isSelected
              ? (isPaystack ? const Color(0xFF09A5DB).withValues(alpha: 0.08) : colorScheme.surfaceContainerHigh)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.12) : colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? activeColor : colorScheme.onSurfaceVariant, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                      if (isRecommended || badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText ?? 'RECOMMENDED',
                            style: textTheme.labelSmall?.copyWith(color: activeColor, fontSize: 8, fontWeight: FontWeight.bold),
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
                  color: isSelected ? activeColor : colorScheme.outlineVariant,
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
                          color: activeColor,
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
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * 3.14159,
                child: const Icon(Icons.restaurant, size: 80, color: Color(0xFF09A5DB)),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Processing Paystack Payment...',
            style: textTheme.headlineMedium?.copyWith(color: const Color(0xFF09A5DB)),
          ),
          const SizedBox(height: 16),
          Text(
            'Confirming order and verifying transaction',
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            child: LinearProgressIndicator(
              color: const Color(0xFF09A5DB),
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
                color: const Color(0xFF09A5DB),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF09A5DB).withValues(alpha: 0.4),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.check, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Order Confirmed!',
            style: textTheme.headlineLarge?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Your food is being prepared.',
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 28),
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
                    Text(_confirmedOrderId ?? 'Pending', style: textTheme.titleMedium),
                  ],
                ),
                if (_paystackReference != null) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paystack Ref', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      Text(
                        _paystackReference!.length > 18
                            ? '${_paystackReference!.substring(0, 15)}...'
                            : _paystackReference!,
                        style: textTheme.titleSmall?.copyWith(color: const Color(0xFF09A5DB), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Amount Paid', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Text('₦${_amountPaid.toStringAsFixed(0)}', style: textTheme.titleMedium),
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
              Navigator.pushReplacementNamed(context, '/tracking', arguments: _confirmedOrderId);
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
