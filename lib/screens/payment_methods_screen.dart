import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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

  void _removeMethod(int index) {
    setState(() {
      _methods.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment method removed.')),
    );
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Payment method addition feature will be available in the next update.'),
            SizedBox(height: 16),
            Text('For now, you can add payment methods during checkout.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your saved payment methods', style: textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_errorMessage!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
                    ),
                  if (_methods.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No saved payment methods found. Add one from checkout or update your account settings.',
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: _methods.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final method = _methods[index];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: CircleAvatar(child: Text(method['type']!.substring(0, 1))),
                              title: Text('${method['type']} •••• ${method['last4']}'),
                              subtitle: Text('Expires ${method['expires']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeMethod(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPaymentDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment Method'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Saved methods are used for checkout, payouts, and refunds.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
    );
  }
}
