import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/plokitch_error_banner.dart';

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
      _vendorId = profile?['vendorId'] ?? profile?['vendor_id'] ?? profile?['id'];
      
      if (_vendorId != null) {
        final vendorData = await ApiService.fetchVendor(_vendorId!);
        if (mounted) {
          setState(() {
            _businessNameController.text = vendorData['businessName'] as String? ?? vendorData['business_name'] as String? ?? '';
            _descriptionController.text = vendorData['description'] as String? ?? '';
            _imageUrlController.text = vendorData['imageUrl'] as String? ?? vendorData['image_url'] as String? ?? '';
            final location = vendorData['location'] as Map<String, dynamic>?;
            _streetController.text = location?['street'] as String? ?? '';
            _cityController.text = location?['city'] as String? ?? '';
            _stateController.text = location?['state'] as String? ?? '';
          });
        }
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
    if (_vendorId == null || _vendorId!.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final payload = {
        'businessName': _businessNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'location': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
        },
      };

      await ApiService.updateVendor(_vendorId!, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kitchen details updated successfully.')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen Profile')),
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _saveVendorDetails,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Save Kitchen Details', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
