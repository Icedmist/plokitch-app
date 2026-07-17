import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            expandedHeight: 220,
            pinned: true,
            leading: const PlokitchBackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _vendor!.imageUrl != null
                      ? Image.network(
                          _vendor!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHigh,
                            child: const Icon(Icons.storefront, size: 64),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHigh,
                          child: const Icon(Icons.storefront, size: 64),
                        ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kitchen Name
                  Text(
                    _vendor!.businessName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info chips row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.star_rounded,
                          iconColor: Colors.amber.shade700,
                          label: '4.8 Rating',
                          bgColor: Colors.amber.shade50,
                          labelColor: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.directions_bike_rounded,
                          iconColor: colorScheme.primary,
                          label: '1.2 km',
                          bgColor: colorScheme.primaryContainer.withValues(alpha: 0.15),
                          labelColor: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: _vendor!.isOpenNow ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                          iconColor: _vendor!.isOpenNow ? Colors.green : Colors.red,
                          label: _vendor!.isOpenNow ? 'Open Now' : 'Closed',
                          bgColor: _vendor!.isOpenNow ? Colors.green.shade50 : Colors.red.shade50,
                          labelColor: _vendor!.isOpenNow ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                        if (_vendor!.openTime != null && _vendor!.closeTime != null) ...[
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            icon: Icons.schedule_rounded,
                            iconColor: colorScheme.onSurfaceVariant,
                            label: '${_vendor!.openTime} - ${_vendor!.closeTime}',
                            bgColor: colorScheme.surfaceContainerHigh,
                            labelColor: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    _vendor!.description ?? 'Local Kitchen specialized in authentic flavors.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Owner controls (if logged in as chef and viewing their own kitchen)
                  if ((_userRole ?? '').toLowerCase() == 'chef' &&
                      (_profile?['vendorId']?.toString() == _vendor?.id ||
                       _profile?['vendor_id']?.toString() == _vendor?.id ||
                       (_profile?['vendor'] is Map<String, dynamic> && (_profile?['vendor']['id'] as String?) == _vendor?.id))) ...[
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/kitchen-settings'),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Kitchen Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Contact Card (Email & Phone)
                  if ((_vendor!.email != null && _vendor!.email!.isNotEmpty) ||
                      (_vendor!.phone != null && _vendor!.phone!.isNotEmpty)) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KITCHEN CONTACT DETAILS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_vendor!.phone != null && _vendor!.phone!.isNotEmpty) ...[
                            _buildContactRow(
                              icon: Icons.phone_android_rounded,
                              value: _vendor!.phone!,
                              colorScheme: colorScheme,
                              context: context,
                            ),
                          ],
                          if (_vendor!.phone != null && _vendor!.phone!.isNotEmpty &&
                              _vendor!.email != null && _vendor!.email!.isNotEmpty)
                            Divider(height: 20, thickness: 0.5, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          if (_vendor!.email != null && _vendor!.email!.isNotEmpty) ...[
                            _buildContactRow(
                              icon: Icons.alternate_email_rounded,
                              value: _vendor!.email!,
                              colorScheme: colorScheme,
                              context: context,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  Text(
                    'Menu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
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

  Widget _buildInfoChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color bgColor,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String value,
    required ColorScheme colorScheme,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied "$value" to clipboard'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.copy_rounded, size: 14, color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/food-detail', arguments: {
            'foodItem': item.toJson(),
            'kitchen': _vendor?.businessName ?? 'Unknown Kitchen',
            'vendorId': _vendor?.id,
          }),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        (item.images.isNotEmpty ? item.images.first : item.imageUrl) ?? '',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 96,
                          height: 96,
                          color: colorScheme.surfaceContainerHigh,
                          child: Icon(
                            Icons.fastfood_rounded,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    if (item.isFeatured)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C00),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SPECIAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.description != null && item.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.description!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₦${item.price.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
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
