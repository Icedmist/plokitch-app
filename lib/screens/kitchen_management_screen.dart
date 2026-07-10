import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_bottom_nav.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';

class KitchenManagementScreen extends StatefulWidget {
  const KitchenManagementScreen({super.key});

  @override
  State<KitchenManagementScreen> createState() => _KitchenManagementScreenState();
}

class _KitchenManagementScreenState extends State<KitchenManagementScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pingController;
  List<MenuItemModel> _menuItems = [];
  bool _loading = true;
  String? _error;
  String? _vendorId;
  Map<String, dynamic>? _vendorData;
  List<OrderModel> _activeOrders = [];

  final _dishNameController = TextEditingController();
  final _dishPriceController = TextEditingController();
  final _dishDescController = TextEditingController();
  final _dishCategoryController = TextEditingController();
  List<String> _selectedImageUrls = [];
  bool _isDishAddOn = false;
  bool _isDishAvailable = true;
  bool _isSavingDish = false;

  @override
  void initState() {
    super.initState();
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
        final fetchedVendor = await ApiService.fetchVendor(_vendorId!, forceRefresh: true);
        final menu = await ApiService.fetchVendorMenu(_vendorId!, forceRefresh: true);
        final orders = await ApiService.fetchOrders(vendorId: _vendorId!);
        if (mounted) {
          setState(() {
            _vendorData = fetchedVendor;
            _menuItems = menu.cast<MenuItemModel>();
            _activeOrders = orders.where((o) => !['delivered', 'cancelled', 'completed'].contains(o.status.toLowerCase())).toList();
          });
        }
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Failed to fetch vendor') || errStr.contains('not found') || errStr.contains('404')) {
        if (mounted) {
          setState(() {
            _vendorData = null;
            _error = null;
          });
        }
      } else {
        if (mounted) {
          setState(() => _error = errStr);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final images = await ImageService.pickImages(maxImages: 4 - _selectedImageUrls.length);
      if (images.isEmpty) return;

      setState(() => _isSavingDish = true);

      for (final image in images) {
        final compressed = await ImageService.compressImage(image);
        final url = await ImageService.uploadImage(compressed, 'dishes', _vendorId ?? 'unknown');
        _selectedImageUrls.add(url);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isSavingDish = false);
    }
  }

  void _showAddDishModal({MenuItemModel? existingItem}) {
    if (existingItem != null) {
      _dishNameController.text = existingItem.name;
      _dishPriceController.text = existingItem.price.toString();
      _dishDescController.text = existingItem.description ?? '';
      _dishCategoryController.text = existingItem.category ?? '';
      _selectedImageUrls = List.from(existingItem.images);
      if (_selectedImageUrls.isEmpty && existingItem.imageUrl != null) {
        _selectedImageUrls.add(existingItem.imageUrl!);
      }
      _isDishAddOn = existingItem.isAddOn;
      _isDishAvailable = existingItem.isAvailable;
    } else {
      _dishNameController.clear();
      _dishPriceController.clear();
      _dishDescController.clear();
      _dishCategoryController.clear();
      _selectedImageUrls = [];
      _isDishAddOn = false;
      _isDishAvailable = true;
    }

    final mainContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (_, setModalState) => Container(
          height: MediaQuery.of(modalContext).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(modalContext).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(existingItem == null ? 'Add New Dish' : 'Edit Dish', 
                       style: Theme.of(modalContext).textTheme.headlineMedium),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalContext)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: _dishNameController,
                      decoration: const InputDecoration(labelText: 'Dish Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dishPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (₦)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dishDescController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dishCategoryController,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('Mark as Add-on', style: Theme.of(modalContext).textTheme.bodyLarge)),
                        Switch(
                          value: _isDishAddOn,
                          onChanged: (v) => setModalState(() => _isDishAddOn = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('Available for order', style: Theme.of(modalContext).textTheme.bodyLarge)),
                        Switch(
                          value: _isDishAvailable,
                          onChanged: (v) => setModalState(() => _isDishAvailable = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Images (Max 4)', style: Theme.of(modalContext).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._selectedImageUrls.map((url) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setModalState(() => _selectedImageUrls.remove(url)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        )),
                        if (_selectedImageUrls.length < 4)
                          GestureDetector(
                            onTap: () async {
                              await _pickAndUploadImages();
                              setModalState(() {});
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_a_photo, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSavingDish ? null : () async {
                    if (_vendorId == null) return;

                    final name = _dishNameController.text.trim();
                    final price = double.tryParse(_dishPriceController.text) ?? 0.0;
                    final desc = _dishDescController.text.trim();
                    final rawCategory = _dishCategoryController.text.trim().toLowerCase();
                    const validCategories = {'mains', 'sides', 'desserts', 'drinks', 'starters', 'specials'};
                    final category = validCategories.contains(rawCategory) ? rawCategory : 'mains';

                    if (name.isEmpty || price <= 0) {
                      ScaffoldMessenger.of(modalContext).showSnackBar(SnackBar(
                        content: const Text('Please enter valid name and price.'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                      return;
                    }

                    setModalState(() => _isSavingDish = true);
                    try {
                      final payload = <String, dynamic>{
                        'name': name,
                        'price': price.toString(),
                        'description': desc,
                        'category': category,
                        'isAddOn': _isDishAddOn,
                        'isAvailable': _isDishAvailable,
                        'imageUrl': _selectedImageUrls.isNotEmpty ? _selectedImageUrls.first : null,
                      };

                      if (existingItem == null) {
                        await ApiService.addMenuItem(_vendorId!, payload);
                      } else {
                        await ApiService.updateMenuItem(_vendorId!, existingItem.id, payload);
                      }

                      if (mounted) {
                        Navigator.pop(modalContext);
                        _loadKitchenData();
                        _showSuccessDialog(mainContext, existingItem == null ? 'Dish added to your menu.' : 'Dish updated successfully.');
                      }
                    } catch (e) {
                      if (mounted) {
                        setModalState(() => _isSavingDish = false);
                        ScaffoldMessenger.of(modalContext).showSnackBar(SnackBar(
                          content: Text('Failed to save: $e'),
                          backgroundColor: Colors.red.shade800,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Theme.of(modalContext).colorScheme.primary,
                    foregroundColor: Theme.of(modalContext).colorScheme.onPrimary,
                    disabledBackgroundColor: Theme.of(modalContext).colorScheme.onSurface.withValues(alpha: 0.12),
                    elevation: 0,
                  ),
                  child: _isSavingDish
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Dish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    onPressed: () => Navigator.pop(context),
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
    _pingController.dispose();
    _dishNameController.dispose();
    _dishPriceController.dispose();
    _dishDescController.dispose();
    _dishCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading && _vendorData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: const PlokitchAppBar(
        title: 'Manage Kitchen',
        showMenu: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (_loading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SizedBox(
              height: 200,
              child: Center(child: Text('Error: $_error')),
            )
          else if (_vendorData == null)
            _buildNoKitchenState(colorScheme, textTheme)
          else ...[
            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildSimpleStat('Posted Dishes', '${_menuItems.length}', Icons.restaurant_menu, colorScheme, textTheme),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSimpleStat('Active Orders', '${_activeOrders.length}', Icons.shopping_bag, colorScheme, textTheme),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Menu', style: textTheme.headlineMedium?.copyWith(color: colorScheme.secondary)),
                ElevatedButton.icon(
                  onPressed: () => _showAddDishModal(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Dish'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_menuItems.isEmpty)
              const Center(child: Text('No menu items found'))
            else
              ..._menuItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildMenuItem(index, item, colorScheme, textTheme);
              }),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNoKitchenState(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront, 
              color: colorScheme.primary, 
              size: 48
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Kitchen Setup Yet', 
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You need to create your kitchen profile before you can add dishes and start receiving orders.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.pushNamed(context, '/kitchen-settings');
              _loadKitchenData();
            },
            icon: const Icon(Icons.add),
            label: const Text('Set Up Kitchen'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, IconData icon, ColorScheme colorScheme, TextTheme textTheme) {
    final isPrimary = label.contains('Dishes');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPrimary 
              ? [colorScheme.primaryContainer.withValues(alpha: 0.15), colorScheme.primary.withValues(alpha: 0.08)]
              : [colorScheme.tertiaryContainer.withValues(alpha: 0.15), colorScheme.tertiary.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isPrimary ? colorScheme.primary : colorScheme.tertiary).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPrimary ? colorScheme.primary : colorScheme.tertiary).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  color: isPrimary ? colorScheme.primary : colorScheme.tertiary, 
                  size: 20
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isPrimary ? colorScheme.primary : colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value, 
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              )
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, MenuItemModel item, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl != null 
              ? Image.network(item.imageUrl!, width: 64, height: 64, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: Colors.grey.shade300, child: const Icon(Icons.fastfood, color: Colors.white)))
              : Container(width: 64, height: 64, color: Colors.grey.shade300, child: const Icon(Icons.fastfood, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (item.category != null && item.category!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(item.category!, style: textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('₦${item.price.toStringAsFixed(0)}', style: textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
                if (!item.isAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Unavailable', style: textTheme.bodySmall?.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                if (item.isAddOn)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
                    child: Text('ADD-ON', style: textTheme.labelSmall?.copyWith(color: Colors.orange.shade900, fontSize: 8)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showAddDishModal(existingItem: item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: () async {
              if (_vendorId == null) return;
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Dish'),
                  content: Text('Are you sure you want to delete "${item.name}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              
              if (confirmed == true) {
                try {
                  await ApiService.deleteMenuItem(_vendorId!, item.id);
                  _loadKitchenData();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
