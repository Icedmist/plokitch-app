import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/plokitch_error_banner.dart';
import '../widgets/plokitch_app_bar.dart';

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
  final _avatarUrlController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;
  String? _errorMessage;
  String? _currentAvatarUrl;

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
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountDetails() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final profile = await AuthService.getProfile();
      if (mounted) {
        if (profile == null) {
          setState(() => _errorMessage = 'Failed to load account details. Please try again.');
        } else {
          setState(() {
            _nameController.text = profile['name'] as String? ?? '';
            _emailController.text = profile['email'] as String? ?? '';
            _phoneController.text = profile['phone'] as String? ?? '';
            _currentAvatarUrl = profile['image'] as String? ?? profile['avatarUrl'] as String? ?? profile['avatar_url'] as String?;
            _avatarUrlController.text = _currentAvatarUrl ?? '';
            final address = profile['address'];
            if (address is String) {
              _addressController.text = address;
            } else if (address is Map) {
              final street = address['street'] ?? '';
              final city = address['city'] ?? '';
              final state = address['state'] ?? '';
              final parts = [street, city, state].where((p) => p != null && p.toString().isNotEmpty).toList();
              _addressController.text = parts.join(', ');
            }
            _errorMessage = null;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Error loading account details: ${error.toString()}'  );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
        'image': _avatarUrlController.text.trim(),
        'address': _addressController.text.trim(),
      };
      await ApiService.updateUserProfile(profilePayload);
      
      await AuthService.getProfile();
      
      if (mounted) {
        setState(() {
           _currentAvatarUrl = _avatarUrlController.text.trim();
        });
        _showSuccessDialog('Account details saved successfully.');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _deleteProfilePicture() {
    setState(() {
      _avatarUrlController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const PlokitchAppBar(title: 'Account Details', showMenu: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_errorMessage != null) ...[
                      PlokitchErrorBanner(
                        message: _errorMessage!,
                        onDismiss: () => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.surfaceContainerHigh,
                              border: Border.all(color: colorScheme.primary, width: 2),
                              image: _avatarUrlController.text.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(_avatarUrlController.text),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _uploadingImage
                                ? const Center(child: CircularProgressIndicator())
                                : (_avatarUrlController.text.isEmpty
                                    ? Icon(Icons.person, size: 50, color: colorScheme.outline)
                                    : null),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Row(
                              children: [
                                _buildCircleButton(
                                  icon: Icons.edit,
                                  color: colorScheme.primary,
                                  onTap: () => _showAvatarOptions(),
                                ),
                                if (_avatarUrlController.text.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  _buildCircleButton(
                                    icon: Icons.delete,
                                    color: colorScheme.error,
                                    onTap: _deleteProfilePicture,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('Personal information', style: textTheme.headlineSmall),
                    const SizedBox(height: 20),
                    _buildTextField('Full Name', _nameController, TextInputType.name),
                    const SizedBox(height: 16),
                    _buildTextField('Email Address', _emailController, TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildTextField('Phone Number', _phoneController, TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField('Delivery Address', _addressController, TextInputType.streetAddress, maxLines: 3),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saving ? null : _saveDetails,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: _saving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                          : const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Text('Manage your account and delivery preferences here.', style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload from Device'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _uploadingImage = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _uploadingImage = false);
        return;
      }

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('Failed to read file data.');
      }

      // Check size limit: 2MB
      if (file.size > 2 * 1024 * 1024) {
        throw Exception('Image size must be less than 2MB. Selected image is ${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB.');
      }

      final extension = file.extension ?? 'jpg';
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final supabase = Supabase.instance.client;
      await supabase.storage.from('avatars').uploadBinary(
        fileName,
        file.bytes!,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      if (mounted) {
        setState(() {
          _avatarUrlController.text = publicUrl;
        });
        _showSuccessDialog('Image uploaded successfully.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingImage = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        final theme = Theme.of(context);
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
                Text(
                  'Success!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Okay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
