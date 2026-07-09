import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/menu_item_model.dart';

class KitchenManagementScreen extends StatefulWidget {
  const KitchenManagementScreen({super.key});

  @override
  State<KitchenManagementScreen> createState() => _KitchenManagementScreenState();
}

class _KitchenManagementScreenState extends State<KitchenManagementScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pingController;
  List<MenuItemModel> _menuItems = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _vendorId;
  Map<String, dynamic>? _vendorData;

  late TextEditingController _businessNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _imageUrlController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
        final fetchedVendor = await ApiService.fetchVendor(_vendorId!);
        final menu = await ApiService.fetchVendorMenu(_vendorId!);
        if (mounted) {
          setState(() {
            _vendorData = fetchedVendor;
            _menuItems = menu.cast<MenuItemModel>();
            _businessNameController.text = _vendorData?['businessName'] as String? ?? _vendorData?['business_name'] as String? ?? '';
            _descriptionController.text = _vendorData?['description'] as String? ?? '';
            _imageUrlController.text = _vendorData?['imageUrl'] as String? ?? _vendorData?['image_url'] as String? ?? '';
            final location = _vendorData?['location'] as Map<String, dynamic>?;
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

  @override
  void dispose() {
    _pingController.dispose();
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
      appBar: PlokitchAppBar(
        title: 'Kitchen Mgmt',
        showMenu: true,
        showAvatar: true,
        avatarUrl: _vendorData?['imageUrl'] as String? ?? _vendorData?['image_url'] as String?,
      ),
      body: ListView(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.black,
            child: Row(
              children: [
                Icon(Icons.campaign, color: colorScheme.primaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'RAMADAN SPECIAL: UPDATE YOUR EVENING MENU BY 4PM DAILY!',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.close, color: Colors.white, size: 16),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kitchen Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kitchen Status', style: textTheme.headlineMedium?.copyWith(color: Colors.white)),
                          Text('Visible to customers', style: textTheme.bodySmall?.copyWith(color: const Color(0xFFFFB59F))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF74331F), // on-secondary-fixed-variant approx
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                FadeTransition(
                                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_pingController),
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 1.0, end: 2.5).animate(_pingController),
                                    child: Container(
                                      width: 12, height: 12,
                                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 12, height: 12,
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text('ONLINE', style: textTheme.labelLarge?.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Analytics Bento Summary
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 140,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF642714), // warmBrown
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.trending_up, color: colorScheme.primaryContainer, size: 32),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('42', style: textTheme.headlineLarge?.copyWith(color: colorScheme.primaryContainer)),
                                Text('ORDERS TODAY', style: textTheme.labelLarge?.copyWith(color: const Color(0xFFFDDCCC), fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 140,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF642714),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('RATING', style: textTheme.labelLarge?.copyWith(color: const Color(0xFFFDDCCC), fontSize: 10)),
                                        Text('4.9', style: textTheme.headlineMedium?.copyWith(color: colorScheme.primaryContainer)),
                                      ],
                                    ),
                                    Icon(Icons.star, color: colorScheme.primaryContainer),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('EARNED', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer, fontSize: 10)),
                                        Text('₦12.5k', style: textTheme.headlineMedium?.copyWith(color: colorScheme.onPrimaryContainer)),
                                      ],
                                    ),
                                    Icon(Icons.payments, color: colorScheme.onPrimaryContainer),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Kitchen Details Section
                Text('Kitchen Details', style: textTheme.headlineMedium?.copyWith(color: colorScheme.secondary)),
                const SizedBox(height: 12),
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _saveVendorDetails,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(_saving ? 'Saving...' : 'Save Kitchen Details'),
                ),
                const SizedBox(height: 24),
                // Current Menu Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Menu', style: textTheme.headlineMedium?.copyWith(color: colorScheme.secondary)),
                    Text('Manage All', style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary, 
                      decoration: TextDecoration.underline,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Menu List
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(child: Text('Error: $_error'))
                else if (_menuItems.isEmpty)
                  const Center(child: Text('No menu items found'))
                else
                  ..._menuItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildMenuItem(index, item, colorScheme, textTheme);
                  }),
                
                const SizedBox(height: 24),
                // Kitchen Tasks Prompt
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/chef-dashboard');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.restaurant_menu, color: colorScheme.onPrimaryContainer),
                            const SizedBox(width: 12),
                            Text('New Orders (3)', style: textTheme.headlineMedium?.copyWith(color: colorScheme.onPrimaryContainer)),
                          ],
                        ),
                        Icon(Icons.chevron_right, color: colorScheme.onPrimaryContainer),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: PlokitchBottomNav(
        currentIndex: 1, // Menu active
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/chef-dashboard'); // Map/Home equivalent
          if (index == 3) Navigator.pushReplacementNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildMenuItem(int index, MenuItemModel item, ColorScheme colorScheme, TextTheme textTheme) {
    // Backend doesn't have 'available' field in model yet, assuming true for now
    const isAvailable = true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF642714),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: item.imageUrl != null ? DecorationImage(
                image: NetworkImage(item.imageUrl!),
                fit: BoxFit.cover,
              ) : null,
              color: Colors.grey,
            ),
            child: item.imageUrl == null ? const Icon(Icons.fastfood, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: textTheme.bodyLarge?.copyWith(color: Colors.white)),
                Text('₦${item.price.toStringAsFixed(2)}', style: textTheme.bodySmall?.copyWith(color: const Color(0xFFFDDCCC))),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (value) {
              // Status update not implemented yet
            },
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

  Future<void> _saveVendorDetails() async {
    if (_vendorId == null || _vendorId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kitchen identifier is missing.')));
      return;
    }

    setState(() => _saving = true);
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

      final updatedVendor = await ApiService.updateVendor(_vendorId!, payload);
      if (!mounted) return;
      setState(() {
        _vendorData = updatedVendor;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kitchen details updated successfully.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }
}
