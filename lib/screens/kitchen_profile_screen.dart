import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/vendor_model.dart';
import '../models/menu_item_model.dart';

class KitchenProfileScreen extends StatefulWidget {
  final String? id;

  const KitchenProfileScreen({super.key, this.id});

  @override
  State<KitchenProfileScreen> createState() => _KitchenProfileScreenState();
}

class _KitchenProfileScreenState extends State<KitchenProfileScreen> {
  bool _loading = true;
  String? _error;
  VendorModel? _vendor;
  List<MenuItemModel> _menu = [];
  int _retryCount = 0;
  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final vendorId = widget.id ?? args?['id'] as String? ?? args?['vendorId'] as String?;

    if (vendorId == null || vendorId.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Kitchen ID is missing. Please go back and try again.';
          _loading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _loading = true);
    try {
      final vendorData = await ApiService.fetchVendor(vendorId);
      if (vendorData == null || (vendorData is Map && vendorData.isEmpty)) {
        throw Exception('Invalid vendor data received');
      }
      final menuData = await ApiService.fetchVendorMenu(vendorId);
      
      if (mounted) {
        setState(() {
          _vendor = VendorModel.fromJson(vendorData);
          _menu = menuData.cast<MenuItemModel>();
          _loading = false;
          _error = null;
          _retryCount = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        if (_retryCount < _maxRetries) {
          _retryCount++;
          await Future.delayed(const Duration(milliseconds: 800));
          await _loadData();
        } else {
          setState(() {
            _error = 'Unable to load kitchen details. Please try again later.';
            _loading = false;
          });
        }
      }
    }
  }

  void _retryLoad() {
    _retryCount = 0;
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _vendor == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error)  ,
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Kitchen not found',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _retryLoad,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _vendor!.imageUrl != null
                  ? Image.network(_vendor!.imageUrl!, fit: BoxFit.cover)
                  : Container(color: colorScheme.surfaceContainerHigh, child: const Icon(Icons.storefront, size: 64)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_vendor!.businessName, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 18, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text('4.8 · 1.2km away · ', style: textTheme.bodyMedium),
                      Text('Open Now', style: textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_vendor!.description ?? 'Local Kitchen specialized in authentic flavors.', style: textTheme.bodyLarge),
                  const Divider(height: 40),
                  Text('Menu', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _menu[index];
                return _buildMenuItemCard(item, colorScheme, textTheme);
              },
              childCount: _menu.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item, ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/food-detail', arguments: {
          'foodItem': item.toJson(),
          'kitchen': _vendor?.businessName ?? 'Unknown Kitchen',
          'vendorId': _vendor?.id,
        }),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(item.description ?? '', style: textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text('₦${item.price.toStringAsFixed(2)}', style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(item.imageUrl!, width: 80, height: 80, fit: BoxFit.cover),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
