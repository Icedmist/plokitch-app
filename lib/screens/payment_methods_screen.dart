import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
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
              'type': map['type']?.toString() ?? 'Card',
              'last4': map['last4']?.toString() ?? map['last_4']?.toString() ?? '????',
              'expires': map['expires']?.toString() ?? map['expiry']?.toString() ?? 'Unknown',
            };
          }).toList();
        } else {
          _methods = [];
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

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.upcoming_outlined,
                    color: colorScheme.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Coming Soon!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Saving payment methods directly from your profile is coming in the next update. For now, you can add and manage payment methods during checkout.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Got It',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  Text('Your saved payment methods', style: textTheme.headlineSmall),
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
                                  'Add a payment method to make your checkout, payouts, and refunds faster and easier.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: 240,
                                child: PlokitchButton(
                                  text: 'Add Payment Method',
                                  icon: Icons.add,
                                  onPressed: _showAddPaymentDialog,
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
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final method = _methods[index];
                          final isVisa = method['type']?.toLowerCase() == 'visa';
                          final isMaster = method['type']?.toLowerCase() == 'mastercard';
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isVisa || isMaster ? Icons.credit_card : Icons.account_balance_wallet,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                '${method['type']} •••• ${method['last4']}',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
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
                      text: 'Add Payment Method',
                      icon: Icons.add,
                      onPressed: _showAddPaymentDialog,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Saved methods are used for checkout, payouts, and refunds.',
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
