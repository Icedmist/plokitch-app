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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kitchen details saved successfully.')));
      Navigator.pop(context, true); // Return true to trigger reload in parent
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
