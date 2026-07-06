import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, String>> _methods = [
    {
      'type': 'Visa',
      'last4': '4242',
      'expires': '12/27',
    },
    {
      'type': 'Mobile Pay',
      'last4': 'N/A',
      'expires': 'Active',
    },
  ];

  void _addMethod() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add payment method is not available in this mockup.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Your saved payment methods', style: textTheme.headlineSmall),
          const SizedBox(height: 16),
          ..._methods.map((method) {
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 14),
              child: ListTile(
                leading: CircleAvatar(child: Text(method['type']!.substring(0, 1))),
                title: Text('${method['type']} •••• ${method['last4']}'),
                subtitle: Text('Expires ${method['expires']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() => _methods.remove(method));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment method removed.')),
                    );
                  },
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addMethod,
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
          const SizedBox(height: 24),
          Text('Your saved methods are used for checkout, tip payouts, and refunds.', style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
