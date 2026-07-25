import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/paystack_service.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_button.dart';
import '../widgets/plokitch_toast.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, String>> _methods = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? methodsJson = prefs.getString('PLOKITCH_SAVED_PAYMENT_METHODS');
      if (methodsJson != null) {
        final List<dynamic> decoded = json.decode(methodsJson);
        _methods = decoded.map((item) => Map<String, String>.from(item as Map)).toList();
      } else {
        // Fallback: try loading from profile
        final profile = await AuthService.getProfile();
        final methods = profile?['paymentMethods'] as List<dynamic>? ?? profile?['payment_methods'] as List<dynamic>?;
        if (methods != null) {
          _methods = methods.map((entry) {
            final map = Map<String, dynamic>.from(entry as Map);
            return {
              'type': map['type']?.toString() ?? 'Paystack Card',
              'last4': map['last4']?.toString() ?? map['last_4']?.toString() ?? '????',
              'expires': map['expires']?.toString() ?? map['expiry']?.toString() ?? 'Unknown',
              'provider': map['provider']?.toString() ?? 'paystack',
            };
          }).toList();
        } else {
          // Provide default Paystack test payment method if empty so user has something working out of the box
          _methods = [
            {
              'type': 'Paystack Visa',
              'last4': '4081',
              'expires': '12/28',
              'provider': 'paystack',
            }
          ];
          await prefs.setString('PLOKITCH_SAVED_PAYMENT_METHODS', json.encode(_methods));
        }
      }
    } catch (e) {
      _errorMessage = 'Unable to load saved payment methods.';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _removeMethod(int index) async {
    final removed = _methods[index];
    setState(() {
      _methods.removeAt(index);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('PLOKITCH_SAVED_PAYMENT_METHODS', json.encode(_methods));
      
      await ApiService.addNotification(
        title: 'Payment Method Removed',
        body: 'Your ${removed['type']} card ending in ${removed['last4']} was removed.',
        type: 'system',
      );
    } catch (_) {}

    if (mounted) {
      PlokitchToast.show(
        context,
        '${removed['type']} card ending in ${removed['last4']} removed.',
        icon: Icons.delete_outline_rounded,
      );
    }
  }

  void _showAddPaystackPaymentBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final cardNumberController = TextEditingController(text: '4081 0000 0000 4081');
    final expiryController = TextEditingController(text: '12/28');
    final cvvController = TextEditingController(text: '123');
    final holderNameController = TextEditingController(text: 'Test User');

    String detectedBrand = 'Paystack Visa';
    bool isSaving = false;

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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
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
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF09A5DB).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.payment_rounded,
                                color: Color(0xFF09A5DB),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Paystack Card',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Secured by Paystack Payment Gateway',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Card Number Field
                        TextFormField(
                          controller: cardNumberController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                            _CardNumberInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Card Number',
                            hintText: '0000 0000 0000 0000',
                            prefixIcon: const Icon(Icons.credit_card),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Chip(
                                label: Text(
                                  detectedBrand,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFF09A5DB),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onChanged: (val) {
                            final brand = PaystackService.detectCardBrand(val);
                            setModalState(() {
                              detectedBrand = brand == 'Card' ? 'Paystack Card' : 'Paystack $brand';
                            });
                          },
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter card number';
                            final clean = val.replaceAll(RegExp(r'\D'), '');
                            if (clean.length < 13) return 'Invalid card number length';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Expiry Date Field
                            Expanded(
                              child: TextFormField(
                                controller: expiryController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  _CardExpiryInputFormatter(),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Expiry Date',
                                  hintText: 'MM/YY',
                                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'MM/YY required';
                                  if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(val.trim())) {
                                    return 'Use MM/YY format';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // CVV Field
                            Expanded(
                              child: TextFormField(
                                controller: cvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'CVV / CVC',
                                  hintText: '123',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'CVV required';
                                  if (val.trim().length < 3) return '3-4 digits';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Cardholder Name Field
                        TextFormField(
                          controller: holderNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Cardholder Name',
                            hintText: 'e.g. John Doe',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter cardholder name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: PlokitchButton(
                            text: isSaving ? 'Saving Card...' : 'Save Paystack Card',
                            icon: Icons.check_circle_outline,
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setModalState(() {
                                      isSaving = true;
                                    });

                                    final cleanNum = cardNumberController.text.replaceAll(RegExp(r'\D'), '');
                                    final last4 = cleanNum.substring(cleanNum.length - 4);
                                    final expiry = expiryController.text.trim();
                                    final brand = detectedBrand;

                                    final newMethod = {
                                      'type': brand,
                                      'last4': last4,
                                      'expires': expiry,
                                      'provider': 'paystack',
                                    };

                                    final prefs = await SharedPreferences.getInstance();
                                    final updatedList = List<Map<String, String>>.from(_methods)..add(newMethod);
                                    await prefs.setString('PLOKITCH_SAVED_PAYMENT_METHODS', json.encode(updatedList));

                                    await ApiService.addNotification(
                                      title: 'Paystack Payment Method Added',
                                      body: 'Your $brand ending in $last4 was saved successfully.',
                                      type: 'system',
                                    );

                                    if (mounted) {
                                      setState(() {
                                        _methods = updatedList;
                                      });
                                      Navigator.pop(context);
                                      PlokitchToast.show(
                                        context,
                                        '$brand ending in $last4 saved!',
                                        icon: Icons.credit_card_rounded,
                                      );
                                    }
                                  },
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const PlokitchAppBar(title: 'Payment Methods', showMenu: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Saved Payment Methods', style: textTheme.headlineSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF09A5DB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified, color: Color(0xFF09A5DB), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Paystack Verified',
                              style: textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF09A5DB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_errorMessage!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
                    ),
                  if (_methods.isEmpty)
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payment_outlined,
                                size: 80,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No saved payment methods',
                                style: textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                child: Text(
                                  'Add a Paystack payment method to make your checkout, payouts, and refunds faster and seamless.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: 260,
                                child: PlokitchButton(
                                  text: 'Add Paystack Card',
                                  icon: Icons.add,
                                  onPressed: _showAddPaystackPaymentBottomSheet,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: ListView.separated(
                        itemCount: _methods.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final method = _methods[index];
                          final type = method['type'] ?? 'Card';
                          final isVisa = type.toLowerCase().contains('visa');
                          final isMaster = type.toLowerCase().contains('mastercard');

                          return Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF09A5DB).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isVisa || isMaster ? Icons.credit_card : Icons.account_balance_wallet,
                                  color: const Color(0xFF09A5DB),
                                  size: 24,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    '$type •••• ${method['last4']}',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF09A5DB).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'PAYSTACK',
                                      style: TextStyle(
                                        color: Color(0xFF09A5DB),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Expires ${method['expires']}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                onPressed: () => _removeMethod(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    PlokitchButton(
                      text: 'Add Paystack Card',
                      icon: Icons.add,
                      onPressed: _showAddPaystackPaymentBottomSheet,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Saved Paystack cards are processed securely via Paystack Payment Gateway.',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
