import 'package:flutter/material.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Amina Yusuf');
  final _emailController = TextEditingController(text: 'amina@example.com');
  final _phoneController = TextEditingController(text: '+234 703 123 4567');
  final _addressController = TextEditingController(text: '15 Aminu Kano Way, Wuse 2, Gombe');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveDetails() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account details saved successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Account Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Personal information', style: textTheme.headlineSmall),
              const SizedBox(height: 20),
              _buildTextField('Full Name', _nameController, TextInputType.name),
              const SizedBox(height: 16),
              _buildTextField('Email Address', _emailController, TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', _phoneController, TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('Delivery Address', _addressController, TextInputType.streetAddress, maxLines: 3),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveDetails,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Save Details'),
              ),
              const SizedBox(height: 16),
              Text('Manage your account and delivery preferences here.', style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType keyboardType, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label'.toLowerCase();
        }
        return null;
      },
    );
  }
}
