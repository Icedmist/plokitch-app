import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccountDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountDetails() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final profile = await AuthService.getProfile();
      if (profile != null) {
        _nameController.text = profile['name'] as String? ?? '';
        _emailController.text = profile['email'] as String? ?? '';
        _phoneController.text = profile['phone'] as String? ?? '';
        final address = profile['address'];
        if (address is String) {
          _addressController.text = address;
        } else if (address is Map) {
          final street = address['street'] ?? '';
          final city = address['city'] ?? '';
          final state = address['state'] ?? '';
          _addressController.text = [street, city, state].where((part) => part != null && part.toString().isNotEmpty).join(', ');
        }
      }
    } catch (error) {
      _errorMessage = 'Unable to load account details. Please try again.';
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveDetails() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final profilePayload = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': {
          'street': _addressController.text.trim(),
        },
      };
      await ApiService.updateUserProfile(profilePayload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account details saved successfully.')),
        );
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Unable to save account details. Please try again.';
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Account Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text('Personal information', style: textTheme.headlineSmall),
                    const SizedBox(height: 20),
                    if (_errorMessage != null) ...[
                      Text(_errorMessage!, style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField('Full Name', _nameController, TextInputType.name),
                    const SizedBox(height: 16),
                    _buildTextField('Email Address', _emailController, TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildTextField('Phone Number', _phoneController, TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField('Delivery Address', _addressController, TextInputType.streetAddress, maxLines: 3),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : _saveDetails,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Details'),
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
