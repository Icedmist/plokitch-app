import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/vendor_model.dart';
import '../models/menu_item_model.dart';
import '../widgets/plokitch_app_bar.dart';
import '../widgets/plokitch_back_button.dart';

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
  Map<String, dynamic>? _profile;
  String? _userRole;
  int _retryCount = 0;
  bool _hasLoadedData = false;
  static const int _maxRetries = 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic>? argMap;
    if (args is Map<String, dynamic>) {
      argMap = args;
    } else if (args is Map) {
      argMap = Map<String, dynamic>.from(args);
    }

    final profile = await AuthService.getProfile();
    _profile = profile;
    _userRole = profile?['role'] as String? ?? await AuthService.storedRole();

    String? vendorId = widget.id?.trim();
    if (vendorId == null || vendorId.isEmpty) {
      vendorId = argMap?['id']?.toString().trim();
      if (vendorId == null || vendorId.isEmpty) {
        vendorId = argMap?['vendorId']?.toString().trim();
      }
    }
    if (vendorId == null || vendorId.isEmpty) {
      vendorId = profile?['vendorId']?.toString().trim() ?? profile?['vendor_id']?.toString().trim();
      if (vendorId == null || vendorId.isEmpty) {
        final vendorMap = profile?['vendor'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(profile!['vendor'] as Map)
            : null;
        vendorId = vendorMap?['id']?.toString().trim();
      }
    }

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
      final vendorData = await ApiService.fetchVendor(vendorId, forceRefresh: true);
      if (vendorData.isEmpty) {
        throw Exception('Invalid vendor data received');
      }
      final menuData = await ApiService.fetchVendorMenu(vendorId, forceRefresh: true);

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
      return const Scaffold(
        appBar: PlokitchAppBar(title: '', showMenu: false),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _vendor == null) {
      return Scaffold(
        appBar: const PlokitchAppBar(title: '', showMenu: false),
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
            leading: const PlokitchBackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: _vendor!.imageUrl != null
                  ? Image.network(_vendor!.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: colorScheme.surfaceContainerHigh, child: const Icon(Icons.storefront, size: 64)))
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
                      Text('4.8 · 1.2km away', style: textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (_vendor!.openTime != null && _vendor!.closeTime != null) ...[
                        Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${_vendor!.openTime} - ${_vendor!.closeTime}', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _vendor!.isOpenNow ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _vendor!.isOpenNow ? 'Open Now' : 'Closed',
                          style: textTheme.bodySmall?.copyWith(
                            color: _vendor!.isOpenNow ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if ((_userRole ?? '').toLowerCase() == 'chef' &&
                      (_profile?['vendorId']?.toString() == _vendor?.id ||
                       _profile?['vendor_id']?.toString() == _vendor?.id ||
                       (_profile?['vendor'] is Map<String, dynamic> && (_profile?['vendor']['id'] as String?) == _vendor?.id)))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/kitchen-settings'),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Kitchen'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/food-detail', arguments: {
            'foodItem': item.toJson(),
            'kitchen': _vendor?.businessName ?? 'Unknown Kitchen',
            'vendorId': _vendor?.id,
          }),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (item.description != null && item.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.description!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        '₦${item.price.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    (item.images.isNotEmpty ? item.images.first : item.imageUrl) ?? '',
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 84,
                      height: 84,
                      color: colorScheme.surfaceContainerHigh,
                      child: Icon(Icons.fastfood_rounded, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
