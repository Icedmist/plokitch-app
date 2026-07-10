import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/plokitch_error_banner.dart';
import '../widgets/plokitch_button.dart';

class KitchenSettingsScreen extends StatefulWidget {
  const KitchenSettingsScreen({super.key});

  @override
  State<KitchenSettingsScreen> createState() => _KitchenSettingsScreenState();
}

class _KitchenSettingsScreenState extends State<KitchenSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _vendorId;

  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _openTimeController = TextEditingController(text: '08:00');
  final _closeTimeController = TextEditingController(text: '22:00');

  @override
  void initState() {
    super.initState();
    _loadKitchenData();
  }

  Future<void> _loadKitchenData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await AuthService.getProfile();
      String? vId = profile?['vendorId'] ?? profile?['vendor_id'];
      
      Map<String, dynamic>? vendorData;
      if (vId != null) {
        try {
          vendorData = await ApiService.fetchVendor(vId, forceRefresh: true);
          _vendorId = vId;
        } catch (_) {}
      }
      
      if (vendorData == null) {
        try {
          vendorData = await ApiService.fetchMyVendor();
          _vendorId = vendorData['id'] as String?;
        } catch (e) {
          // If fetchMyVendor fails (e.g. 404), it means they don't have a kitchen yet, which is fine
        }
      }

      if (vendorData != null && mounted) {
        setState(() {
          _businessNameController.text = vendorData!['businessName'] as String? ?? vendorData!['business_name'] as String? ?? '';
          _descriptionController.text = vendorData!['description'] as String? ?? '';
          _imageUrlController.text = vendorData!['imageUrl'] as String? ?? vendorData!['image_url'] as String? ?? '';
          final location = vendorData!['location'] as Map<String, dynamic>?;
          _streetController.text = location?['street'] as String? ?? '';
          _cityController.text = location?['city'] as String? ?? '';
          _stateController.text = location?['state'] as String? ?? '';
          _openTimeController.text = location?['openTime'] as String? ?? '08:00';
          _closeTimeController.text = location?['closeTime'] as String? ?? '22:00';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveVendorDetails() async {
    if (_businessNameController.text.trim().isEmpty) {
      setState(() => _error = 'Business Name is required');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final payload = {
        'businessName': _businessNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'isActive': true,
        'location': {
          'address': _streetController.text.trim(),
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'openTime': _openTimeController.text.trim(),
          'closeTime': _closeTimeController.text.trim(),
        },
      };

      if (_vendorId != null && _vendorId!.isNotEmpty) {
        await ApiService.updateVendor(_vendorId!, payload);
      } else {
        final newVendor = await ApiService.createVendor(payload);
        _vendorId = newVendor['id'] as String?;
      }
      
      AuthService.invalidateProfile();

      if (!mounted) return;
      _showSuccessDialog(context, 'Kitchen details saved successfully.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$hour:$minute';
      });
    }
  }

  void _showSuccessDialog(BuildContext dialogContext, String message) {
    showDialog(
      context: dialogContext,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        final theme = Theme.of(context);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Success!', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 12),
                Text(message, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Okay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  PlokitchErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
                  const SizedBox(height: 16),
                ],
                _buildTextField('Business Name', _businessNameController),
                const SizedBox(height: 12),
                _buildTextField('Description', _descriptionController, maxLines: 4),
                const SizedBox(height: 12),
                _buildTextField('Image URL', _imageUrlController),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Street', _streetController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('City', _cityController)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField('State', _stateController),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    _buildTimeField('Open Time', _openTimeController),
                    const SizedBox(width: 12),
                    _buildTimeField('Close Time', _closeTimeController),
                  ],
                ),
                const SizedBox(height: 28),
                
                PlokitchButton(
                  text: _saving ? 'Saving...' : 'Save Kitchen Details',
                  onPressed: _saving ? null : _saveVendorDetails,
                ),
              ],
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildTimeField(String label, TextEditingController controller) {
    return Expanded(
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectTime(context, controller),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
